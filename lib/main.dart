import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // كودك
import 'package:geolocator/geolocator.dart'; // كودك
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
      home: const LoginPage(), // يبدأ بشغل صديقتك
    );
  }
}

// --- شغل صديقتك (بدون حذف) ---
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
                  // هنا ربطنا شغل صديقتك بشغلك:
                  // عند الضغط على الزر يفتح صفحة الحضور التي صممتيها
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

// --- شغلك أنتِ (إضافة بالأسفل) ---
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkAttendance() async {
    // يطلب الإذن بناءً على الصلاحيات التي أضفتيها في AndroidManifest
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // جلب الإحداثيات من Firestore
        QuerySnapshot locations =
            await _firestore.collection('locations').get();
        bool inside = false;

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
      _showMsg("يجب السماح بالموقع");
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل الحضور")),
      body: Center(
        child: ElevatedButton(
          onPressed: checkAttendance,
          child: const Text("اضغط لتسجيل الحضور"),
        ),
      ),
    );
  }
}
