import 'package:flutter/material.dart';
import 'services/facenet_service.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';

class FaceVerifyPage extends StatefulWidget {
  const FaceVerifyPage({super.key});

  @override
  State<FaceVerifyPage> createState() => _FaceVerifyPageState();
}

class _FaceVerifyPageState extends State<FaceVerifyPage> {
  final FaceNetService _service = FaceNetService();
  CameraController? _cameraController;

  String status = 'Loading...';

  bool isLocationValid = false;
  bool isFaceOk = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    setState(() => status = "Loading model + camera + location...");

    // شغّليهم مع بعض (أسرع)
    await Future.wait([
      _loadFaceAndCamera(),
      _checkLocation(),
    ]);

    setState(() {
      status = _buildStatusText();
    });
  }

  Future<void> _loadFaceAndCamera() async {
    try {
      await _service.loadModel();

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();
    } catch (e) {
      setState(() => status = "Camera/Model Error: $e");
    }
  }

  Future<void> _checkLocation() async {
    try {
      // 1) تأكد الخدمات شغّالة
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLocationValid = false;
          status = "Location services are OFF";
        });
        return;
      }

      // 2) Permissions
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

      // 3) Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4) تحقق هل داخل نطاق موقع التدريب؟
      // TODO: هنا تحطين كودك القديم:
      // - جيبي lat/lng حق موقع التدريب assigned للطالب (من Firestore أو اللي عندك)
      // - احسبي المسافة
      //
      // مثال (بدّلي القيم بقيم موقعكم الحقيقي):
      const double trainingLat = 24.7136; // TODO
      const double trainingLng = 46.6753; // TODO
      const double radiusMeters = 100;    // TODO

      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        trainingLat,
        trainingLng,
      );

      final inside = distance <= radiusMeters;

      setState(() {
        isLocationValid = inside;
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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camReady = _cameraController != null && _cameraController!.value.isInitialized;

    if (!camReady) {
      return Scaffold(
        body: Center(child: Text(status)),
      );
    }

    final canCapture = isLocationValid; 

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
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: canCapture
                    ? () async {
                        try {
                          setState(() => status = "Capturing...");
                          final pic = await _cameraController!.takePicture();

                          final emb = await _service.extractEmbeddingFromFile(pic.path);

                          setState(() {
                            isFaceOk = emb.isNotEmpty;
                            status = _buildStatusText();
                          });


                        } catch (e) {
                          setState(() => status = "Face Error: $e");
                        }
                      }
                    : null,
                child: Text(canCapture ? "Capture & Run" : "Move to training location"),
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
                  fontSize: 18,
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
