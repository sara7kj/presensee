import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

      setState(() => status = "Running face model...");
      final emb = await _service.extractEmbeddingFromFile(pic.path);

      if (widget.enrollMode) {
  setState(() => status = "Saving face...");
  await _saveEmbeddingToFirestore(emb);

  setState(() {
    isFaceOk = true;
    status = "Face registered ✅";
  });

  // ننتقل مباشرة لصفحة الحضور
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const AttendanceScreen(),
    ),
  );
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

      final dist = _l2Distance(emb, stored);
      // Threshold مبدئي. نعدله حسب التجربة
      final ok = dist < 1.10;

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
