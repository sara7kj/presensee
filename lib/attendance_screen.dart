import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'face_verify_page.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // لو تبين تخلينها إحداثيات بيتك للاختبار:
  // عدلي هنا فقط، ولا تلمسين face_verify_page
  final List<Map<String, double>> manualLocations = const [
    {'lat': 24.1608566, 'lng': 47.2731534},
    {'lat': 23.991732, 'lng': 47.119911},
    {'lat': 23.9964898, 'lng': 47.1129058},
    {'lat': 23.9886747, 'lng': 47.1267959},
    {'lat': 24.1636391, 'lng': 47.3122536},
    {'lat': 24.1471470, 'lng': 47.2709184},
    {'lat': 24.1470161, 'lng': 47.2711555},
    {'lat': 23.9906, 'lng': 47.2107},
  ];

  Future<void> checkIn() async {
    setState(() => isLoading = true);

    try {
      final inside = await _isInsideTrainingLocation();
      if (!inside) {
        _showMsg("You are outside the training location ❌");
        return;
      }

      // Face verify (must be registered already)
      final faceOk = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const FaceVerifyPage(enrollMode: false),
        ),
      );

      if (faceOk != true) {
        _showMsg("Face verification failed ❌");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? "unknown";
      final email = user?.email ?? "";

      await _firestore.collection('attendance').add({
        'uid': uid,
        'email': email,
        'time': Timestamp.now(),
        'status': 'present',
      });

      _showMsg("Attendance recorded successfully ✅");
    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> _isInsideTrainingLocation() async {
    // permission
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are OFF");

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    // current position
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // radius
    const radiusMeters = 100.0;

    // 1) manual list
    for (final loc in manualLocations) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        loc['lat']!,
        loc['lng']!,
      );
      if (d <= radiusMeters) return true;
    }

    // 2) Firestore locations (اختياري)
    final locations = await _firestore.collection('locations').get();
    for (final doc in locations.docs) {
      final lat = (doc['lat'] as num).toDouble();
      final lng = (doc['lng'] as num).toDouble();

      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        lat,
        lng,
      );
      if (d <= radiusMeters) return true;
    }

    return false;
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        centerTitle: true,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: checkIn,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Check In",
                  style: TextStyle(fontSize: 18),
                ),
              ),
      ),
    );
  }
}
