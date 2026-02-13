import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PresenSee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// --- صفحة تسجيل الدخول (شغل صديقتك) ---
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PresenSee')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AttendanceScreen()),
                  );
                },
                child: const Text('Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- صفحة الحضور (شغلك مع الإحداثيات الـ 7 الجديدة) ---
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkAttendance() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        bool inside = false;

        // قائمة الإحداثيات اليدوية التي أرسلتيها
        List<Map<String, double>> manualLocations = [
          {'lat': 24.1608566, 'lng': 47.2731534},
          {'lat': 23.991732, 'lng': 47.119911},
          {'lat': 23.9964898, 'lng': 47.1129058},
          {'lat': 23.9886747, 'lng': 47.1267959},
          {'lat': 24.1636391, 'lng': 47.3122536},
          {'lat': 24.1471470, 'lng': 47.2709184},
          {'lat': 24.1470161, 'lng': 47.2711555},
        ];

        // 1. فحص الإحداثيات اليدوية
        for (var loc in manualLocations) {
          double distance = Geolocator.distanceBetween(
              position.latitude, position.longitude, loc['lat']!, loc['lng']!);

          if (distance <= 100) {
            inside = true;
            break;
          }
        }

        // 2. فحص الإحداثيات في Firestore إذا لم ينجح الفحص اليدوي
        if (!inside) {
          QuerySnapshot locations =
              await _firestore.collection('locations').get();
          for (var doc in locations.docs) {
            double lat = doc['lat'];
            double lng = doc['lng'];
            double distance = Geolocator.distanceBetween(
                position.latitude, position.longitude, lat, lng);

            if (distance <= 100) {
              inside = true;
              break;
            }
          }
        }

        // 3. معالجة النتيجة
        if (inside) {
          await _firestore.collection('attendance').add({
            'studentId': '123',
            'time': Timestamp.now(),
            'status': 'present'
          });
          _showMsg("تم تسجيل حضورك بنجاح ✅");
        } else {
          _showMsg("أنت خارج النطاق ❌");
        }
      } catch (e) {
        _showMsg("خطأ: $e");
      }
    } else {
      _showMsg("يجب السماح بالوصول للموقع");
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الحضور")),
      body: Center(
        child: ElevatedButton(
          onPressed: checkAttendance,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text("اضغط لتسجيل الحضور"),
        ),
      ),
    );
  }
}
