import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  Future<void> checkAttendance() async {
    setState(() => isLoading = true);

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        bool inside = false;

        // Manual training locations
        List<Map<String, double>> manualLocations = [
          {'lat': 24.1608566, 'lng': 47.2731534},
          {'lat': 23.991732, 'lng': 47.119911},
          {'lat': 23.9964898, 'lng': 47.1129058},
          {'lat': 23.9886747, 'lng': 47.1267959},
          {'lat': 24.1636391, 'lng': 47.3122536},
          {'lat': 24.1471470, 'lng': 47.2709184},
          {'lat': 24.1470161, 'lng': 47.2711555},
        ];

        // Check manual coordinates
        for (var loc in manualLocations) {
          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            loc['lat']!,
            loc['lng']!,
          );

          if (distance <= 100) {
            inside = true;
            break;
          }
        }

        // Check Firestore locations if not found manually
        if (!inside) {
          QuerySnapshot locations =
              await _firestore.collection('locations').get();

          for (var doc in locations.docs) {
            double lat = doc['lat'];
            double lng = doc['lng'];

            double distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lng,
            );

            if (distance <= 100) {
              inside = true;
              break;
            }
          }
        }

        // Final result
        if (inside) {
          await _firestore.collection('attendance').add({
            'studentId': '123',
            'time': Timestamp.now(),
            'status': 'present',
          });

          _showMsg("Attendance recorded successfully ✅");
        } else {
          _showMsg("You are outside the training location ❌");
        }
      } catch (e) {
        _showMsg("Error: $e");
      }
    } else {
      _showMsg("Location permission is required");
    }

    setState(() => isLoading = false);
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
                onPressed: checkAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
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
