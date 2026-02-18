import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'services/facenet_service.dart';

class FaceVerifyPage extends StatefulWidget {
  final bool enrollMode; // true = تسجيل وجه, false = تحقق وجه

  const FaceVerifyPage({super.key, this.enrollMode = false});

  @override
  State<FaceVerifyPage> createState() => _FaceVerifyPageState();
}

class _FaceVerifyPageState extends State<FaceVerifyPage> {
  final FaceNetService _service = FaceNetService();
  CameraController? _cameraController;

  String status = 'Loading...';
  bool isLocationValid = false;
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
      // 1) Load model
      await _service.loadModel();

      // 2) Init camera (front)
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();

      // 3) Location check only in verification mode
      if (widget.enrollMode) {
        setState(() {
          isLocationValid = true; // ما نحتاج موقع وقت التسجيل
          status = "Enroll mode | Face register";
        });
      } else {
        setState(() => status = "Checking location...");
        await _checkLocation();
        setState(() => status = _buildStatusText());
      }
    } catch (e) {
      setState(() => status = "Init error: $e");
    }
  }

  Future<void> _checkLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLocationValid = false;
          status = "Location services are OFF";
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          isLocationValid = false;
          status = "Location permission denied";
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // TODO: بدّلي تدريبكم الحقيقي هنا
      const double trainingLat = 24.7136;
      const double trainingLng = 46.6753;
      const double radiusMeters = 100;

      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        trainingLat,
        trainingLng,
      );

      setState(() {
        isLocationValid = distance <= radiusMeters;
      });
    } catch (e) {
      setState(() {
        isLocationValid = false;
        status = "Location Error: $e";
      });
    }
  }

  String _buildStatusText() {
    final loc = isLocationValid ? "Location ✅" : "Location ❌";
    final face = isFaceOk ? "Face ✅" : "Face ❌";
    return "$loc  |  $face";
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
      // 1) Capture
      final pic = await _cameraController!.takePicture();
      if (!await File(pic.path).exists()) {
        throw Exception("Captured file not found");
      }

      // 2) Extract embedding
      final emb = await _service.extractEmbeddingFromFile(pic.path);

      // 3) Enroll (save) OR Verify (compare)
      if (widget.enrollMode) {
        await _saveEmbeddingToFirestore(emb);
        setState(() {
          isFaceOk = true;
          status = "Face saved ✅";
        });

        // بعد الحفظ: ارجعي للصفحة اللي قبل (أو قدمي لصفحة الحضور عندك)
        Navigator.pop(context, true);
      } else {
        final stored = await _getStoredEmbedding();
        if (stored == null || stored.length != emb.length) {
          setState(() {
            isFaceOk = false;
            status = "No stored face for this user";
          });
          Navigator.pop(context, false);
          return;
        }

        final dist = _l2Distance(emb, stored);
        // Threshold مبدئي (نعدله بعد التجربة)
        final ok = dist < 1.10;

        setState(() {
          isFaceOk = ok;
          status = _buildStatusText();
        });

        Navigator.pop(context, ok);
      }
    } catch (e) {
      setState(() {
        isFaceOk = false;
        status = "Face Error: $e";
      });

      if (!widget.enrollMode) {
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveEmbeddingToFirestore(List<double> emb) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No logged-in user");

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'email': user.email ?? '',
        'faceEmbedding': emb,
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

    // في التسجيل: ما نشترط موقع
    // في التحقق: نشترط موقع
    final canCapture = widget.enrollMode ? true : isLocationValid;

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),

          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Text(
                _buildStatusText(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.enrollMode ? "Enroll mode | Face register" : "Verify mode",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: (_busy || !canCapture) ? null : _captureAndProcess,
                child: Text(
                  widget.enrollMode
                      ? "Capture & Save"
                      : (canCapture ? "Capture & Verify" : "Move to training location"),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
