import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'attendance_screen.dart';
import 'services/facenet_service.dart';

class FaceVerifyPage extends StatefulWidget {
  /// enrollMode = true  => Save faceEmbedding in users/{uid}
  /// enrollMode = false => Compare captured embedding with stored one, then return true/false
  final bool enrollMode;

  const FaceVerifyPage({super.key, this.enrollMode = false});

  @override
  State<FaceVerifyPage> createState() => _FaceVerifyPageState();
}

class _FaceVerifyPageState extends State<FaceVerifyPage> {
  final FaceNetService _service = FaceNetService();
  CameraController? _cameraController;

  String status = "Loading...";
  bool isFaceOk = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    setState(() => status = "Loading model + camera...");

    try {
      await _service.loadModel();

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        status = widget.enrollMode
            ? "Enroll mode | Register your face"
            : "Verify mode | Confirm your face";
      });
    } catch (e) {
      setState(() => status = "Init error: $e");
    }
  }

  // ✅ Enrollment quality checks (قبل حفظ الوجه)
  Future<String?> _validateEnrollmentPhoto(String imagePath) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );

    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await detector.processImage(inputImage);
    await detector.close();

    if (faces.isEmpty) return "No face detected. Center your face.";
    if (faces.length > 1) return "Multiple faces detected. Only one face allowed.";

    final f = faces.first;
    final box = f.boundingBox;

    // وجه صغير = بعيد أو جزء بسيط
    if (box.width < 140 || box.height < 140) {
      return "Face too small. Move closer.";
    }

    // ميلان كبير
    final yaw = (f.headEulerAngleY ?? 0).abs();
    final pitch = (f.headEulerAngleX ?? 0).abs();
    if (yaw > 18 || pitch > 18) {
      return "Keep your face straight (no heavy tilt).";
    }
    final leftEye = f.leftEyeOpenProbability ?? 1.0;
    final rightEye = f.rightEyeOpenProbability ?? 1.0;
    if (leftEye < 0.5 || rightEye < 0.5) {
      return "Keep your eyes open";
    }

    // فحص الإضاءة (Brightness) سريع
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return "Image unreadable. Try again.";

    double sum = 0;
    int count = 0;
    for (int y = 0; y < decoded.height; y += 8) {
      for (int x = 0; x < decoded.width; x += 8) {
        final pixel = decoded.getPixel(x, y);

        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        sum += lum;
        count++;
      }
    }
    final avgLum = sum / count;

    if (avgLum < 55) return "Too dark. Increase lighting.";
    if (avgLum > 220) return "Too bright. Avoid glare.";

    return null; // ✅ ممتازة
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => status = "Camera not ready");
      return;
    }

    setState(() {
      _busy = true;
      status = "Capturing...";
    });

    try {
      final pic = await _cameraController!.takePicture();
      if (!await File(pic.path).exists()) {
        throw Exception("Captured file not found");
      }

      // ✅ لو تسجيل وجه: لازم نتحقق من جودة الصورة قبل التخزين
      if (widget.enrollMode) {
        final err = await _validateEnrollmentPhoto(pic.path);
        if (err != null) {
          setState(() {
            isFaceOk = false;
            status = err;
          });
          return; // ❌ لا نكمل ولا نخزن
        }
      }

      setState(() => status = "Running face model...");
      final emb = await _service.extractEmbeddingFromFile(pic.path);

      if (widget.enrollMode) {
        setState(() => status = "Saving face...");
        await _saveEmbeddingToFirestore(emb);

        setState(() {
          isFaceOk = true;
          status = "Face registered ✅";
        });

        // ✅
Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      // verify mode: compare with stored embedding
      final stored = await _getStoredEmbedding();
      if (stored == null || stored.length != emb.length) {
        setState(() {
          isFaceOk = false;
          status = "No stored face found for this account";
        });
        Navigator.pop(context, false);
        return;
      }

      final liveN = _l2Normalize(emb);
      final storedN = _l2Normalize(stored);

      final dist = _l2Distance(liveN, storedN);

      print("LIVE len=${emb.length} first3=${emb.take(3).toList()}");
      print("STORED len=${stored.length} first3=${stored.take(3).toList()}");
      print("🧪 Face distance (normalized) = $dist");

      // 🔧 مبدئيًا (بنضبطه لاحقًا حسب اختباراتكم)
      final ok = dist < 0.95;

      setState(() {
        isFaceOk = ok;
        status = ok ? "Face verified ✅" : "Face verification failed ❌";
      });

      Navigator.pop(context, ok);
    } catch (e) {
      setState(() {
        isFaceOk = false;
        status = "Face error: $e";
      });

      if (!widget.enrollMode) {
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveEmbeddingToFirestore(List<double> emb) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No logged-in user");

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'email': user.email ?? '',
        'faceEmbedding': emb,
        'faceEnrolled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<double>?> _getStoredEmbedding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['faceEmbedding'] == null) return null;

    final list = List.from(data['faceEmbedding']);
    return list.map((e) => (e as num).toDouble()).toList();
  }

  double _l2Distance(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      s += d * d;
    }
    return math.sqrt(s);
  }

  List<double> _l2Normalize(List<double> v) {
    double s = 0;
    for (final x in v) {
      s += x * x;
    }
    final norm = math.sqrt(s);
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camReady =
        _cameraController != null && _cameraController!.value.isInitialized;

    if (!camReady) {
      return Scaffold(
        appBar: AppBar(title: const Text("PresenSee")),
        body: Center(child: Text(status)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enrollMode ? "Register Face" : "Verify Face"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),

          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _busy ? null : _captureAndProcess,
                child: Text(
                  widget.enrollMode ? "Capture & Save" : "Capture & Verify",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}