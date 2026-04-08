import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import 'services/facenet_service.dart';
import 'theme.dart';

class FaceVerifyPage extends StatefulWidget {
  final bool enrollMode;

  const FaceVerifyPage({super.key, this.enrollMode = false});

  @override
  State<FaceVerifyPage> createState() => _FaceVerifyPageState();
}

class _FaceVerifyPageState extends State<FaceVerifyPage>
    with SingleTickerProviderStateMixin {
  final FaceNetService _service = FaceNetService();
  CameraController? _cameraController;

  String status = "Loading...";
  bool isFaceOk = false;
  bool _busy = false;

  // Animation for the scanning ring
  late AnimationController _scanController;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
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
            ? "Position your face in the frame"
            : "Position your face in the frame";
      });
    } catch (e) {
      setState(() => status = "Init error: $e");
    }
  }

  // ── اللوجيك الأصلي بدون تغيير ──────────────────────────────

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
    if (faces.length > 1)
      return "Multiple faces detected. Only one face allowed.";

    final f = faces.first;
    final box = f.boundingBox;

    if (box.width < 140 || box.height < 140) {
      return "Face too small. Move closer.";
    }

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

    return null;
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

      if (widget.enrollMode) {
        final err = await _validateEnrollmentPhoto(pic.path);
        if (err != null) {
          setState(() {
            isFaceOk = false;
            status = err;
          });
          return;
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

        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

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

      final ok = dist < 0.95;

      setState(() {
        isFaceOk = ok;
        status = ok
            ? "Face verified ✅"
            : "Face verification failed ❌";
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

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
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
    _scanController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  UI — Redesigned with DS theme
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final camReady =
        _cameraController != null && _cameraController!.value.isInitialized;

    if (!camReady) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera Preview (full screen) ──
          CameraPreview(_cameraController!),

          // ── Dark overlay with face cutout ──
          _buildFaceOverlay(),

          // ── Top bar ──
          _buildTopBar(),

          // ── Bottom controls ──
          _buildBottomControls(),
        ],
      ),
    );
  }

  // ── Loading Screen (before camera is ready) ──
  Widget _buildLoadingScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DS.darkBg : DS.neutral50,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? DS.primary500.withOpacity(0.15)
                    : DS.primary50,
                borderRadius: BorderRadius.circular(DS.radiusXL),
                border: Border.all(
                  color: isDark
                      ? DS.primary500.withOpacity(0.3)
                      : DS.primary100,
                ),
              ),
              child: Image.asset(
                'assets/logos/logo_icon.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: DS.spaceLG),

            const CircularProgressIndicator(
              color: DS.primary500,
              strokeWidth: 3,
            ),

            const SizedBox(height: DS.spaceLG),

            Text(
              status,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? DS.neutral300 : DS.neutral600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar (overlaid on camera) ──
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + DS.spaceSM,
          left: DS.spaceMD,
          right: DS.spaceMD,
          bottom: DS.spaceMD,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DS.radiusLG),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: DS.spaceMD),

            // Title
            Expanded(
              child: Text(
                widget.enrollMode ? "Register Face" : "Verify Face",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Mode badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (widget.enrollMode
                        ? DS.accentAmber
                        : DS.primary500)
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(DS.radiusFull),
                border: Border.all(
                  color: (widget.enrollMode
                          ? DS.accentAmber
                          : DS.primary500)
                      .withOpacity(0.5),
                ),
              ),
              child: Text(
                widget.enrollMode ? "ENROLL" : "VERIFY",
                style: TextStyle(
                  color: widget.enrollMode
                      ? DS.accentAmber
                      : DS.primary300,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Face Overlay (dark edges + oval guide) ──
  Widget _buildFaceOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _FaceOverlayPainter(
          borderColor: _busy
              ? DS.accentAmber
              : (isFaceOk ? DS.success : DS.primary400),
        ),
      ),
    );
  }

  // ── Bottom Controls ──
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: DS.spaceLG,
          left: DS.spaceLG,
          right: DS.spaceLG,
          bottom: MediaQuery.of(context).padding.bottom + DS.spaceLG,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Status message ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DS.spaceMD, vertical: DS.spaceSM),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(DS.radiusFull),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _getStatusColor(),
                      ),
                    )
                  else
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: _getStatusColor(),
                    ),
                  const SizedBox(width: DS.spaceSM),
                  Flexible(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DS.spaceLG),

            // ── Capture Button ──
            GestureDetector(
              onTap: _busy ? null : _captureAndProcess,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _busy
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _busy ? 30 : 60,
                    height: _busy ? 30 : 60,
                    decoration: BoxDecoration(
                      color: _busy
                          ? DS.accentAmber
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                          _busy ? DS.radiusMD : DS.radiusFull),
                    ),
                    child: _busy
                        ? null
                        : Icon(
                            Icons.camera_alt_rounded,
                            color: DS.primary700,
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: DS.spaceMD),

            // ── Hint text ──
            Text(
              _busy
                  ? "Processing..."
                  : (widget.enrollMode
                      ? "Tap to capture & register"
                      : "Tap to capture & verify"),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_busy) return DS.accentAmber;
    if (isFaceOk) return DS.success;
    if (status.contains('❌') || status.contains('error') ||
        status.contains('failed') || status.contains('denied')) {
      return DS.error;
    }
    return DS.primary400;
  }

  IconData _getStatusIcon() {
    if (isFaceOk) return Icons.check_circle_rounded;
    if (status.contains('❌') || status.contains('error') ||
        status.contains('failed')) {
      return Icons.error_rounded;
    }
    return Icons.face_rounded;
  }
}

// ══════════════════════════════════════════════════════════════
//  Custom Painter — Face oval overlay with darkened edges
// ══════════════════════════════════════════════════════════════

class _FaceOverlayPainter extends CustomPainter {
  final Color borderColor;

  _FaceOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.35;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Dark overlay with oval cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Oval border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Corner accents (4 small arcs at corners of the oval)
    final accentPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final accentLength = 0.15; // radians

    // Top
    canvas.drawArc(ovalRect, -math.pi / 2 - accentLength / 2,
        accentLength, false, accentPaint);
    // Bottom
    canvas.drawArc(ovalRect, math.pi / 2 - accentLength / 2,
        accentLength, false, accentPaint);
    // Left
    canvas.drawArc(
        ovalRect, math.pi - accentLength / 2, accentLength, false, accentPaint);
    // Right
    canvas.drawArc(
        ovalRect, -accentLength / 2, accentLength, false, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}