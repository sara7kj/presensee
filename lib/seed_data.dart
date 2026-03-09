import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════════
///  seed_data.dart — يضيف بيانات تجريبية في Firestore
///
///  شغّله مرة واحدة بس عشان يسوي الـ Collections والبيانات.
///  اربطه بزر أو استدعيه من أي مكان:
///
///    await SeedData.run();
///
///  بعد ما يخلص امسح الاستدعاء عشان ما يتكرر.
/// ═══════════════════════════════════════════════════════════════

class SeedData {
  static final _fs = FirebaseFirestore.instance;

  static Future<void> run() async {
    print('🌱 Seeding Firestore data...');

    // ────── 1. Users ──────
    // ملاحظة: لازم تسوي هالحسابات في Firebase Auth أولاً
    // من Firebase Console > Authentication > Add user
    // أو استخدم الكود هذا (يحتاج صلاحيات):

    final users = {
      'ZEkNFNs3a0VMMzbBxUV4TMdjMU13': {
        'userId': 'ZEkNFNs3a0VMMzbBxUV4TMdjMU13',
        'username': 'Dr. Hessah',
        'email': 'hessa88@psau.edu.sa',
        'role': 'supervisor',
      },
      'supervisor_uid_2': {
        'userId': 'supervisor_uid_2',
        'username': 'Dr. Asma',
        'email': 'asmaa9@psau.edu.sa',
        'role': 'supervisor',
      },
      'student_uid_1': {
        'userId': 'student_uid_1',
        'username': 'Sara Khalid',
        'email': 'sara@psau.edu.sa',
        'role': 'student',
      },
      'student_uid_2': {
        'userId': 'student_uid_2',
        'username': 'Raghad Ja',
        'email': 'raghad@psau.edu.sa',
        'role': 'student',
      },
      'student_uid_3': {
        'userId': 'student_uid_3',
        'username': 'Noura Ali',
        'email': 'noura@psau.edu.sa',
        'role': 'student',
      },
      'student_uid_4': {
        'userId': 'student_uid_4',
        'username': 'Lama Hassan',
        'email': 'lama@psau.edu.sa',
        'role': 'student',
      },
      'admin_uid_1': {
        'userId': 'admin_uid_1',
        'username': 'Admin',
        'email': 'admin@psau.edu.sa',
        'role': 'admin',
      },
    };

    for (final entry in users.entries) {
      await _fs.collection('Users').doc(entry.key).set(entry.value);
    }
    print('  ✅ Users collection created');

    // ────── 2. Supervisors ──────
    await _fs.collection('Supervisors').doc('SUP001').set({
      'supervisorId': 'SUP001',
      'userId': 'ZEkNFNs3a0VMMzbBxUV4TMdjMU13',
      'name': 'Dr. Hessah',
      'email': 'hessa88@psau.edu.sa',
      'phone': '+966 55 8894 438',
      'department': 'Engineering',
      'locationId': 'LOC001',
    });

    await _fs.collection('Supervisors').doc('SUP002').set({
      'supervisorId': 'SUP002',
      'userId': 'supervisor_uid_2',
      'name': 'Dr. Asma',
      'email': 'asmaa9@psau.edu.sa',
      'phone': '+966 55 6533 239',
      'department': 'Computer Science',
      'locationId': 'LOC002',
    });
    print('  ✅ Supervisors collection created');

    // ────── 3. TrainingLocations ──────
    await _fs.collection('TrainingLocations').doc('LOC001').set({
      'locationId': 'LOC001',
      'name': 'Main Campus',
      'address': '123, Al-Kharj',
      'gpsCoordinates': '24.1500,47.3000',
      'capacity': 100,
    });

    await _fs.collection('TrainingLocations').doc('LOC002').set({
      'locationId': 'LOC002',
      'name': 'STC',
      'address': '456, Riyadh',
      'gpsCoordinates': '24.7136,46.6753',
      'capacity': 50,
    });
    print('  ✅ TrainingLocations collection created');

    // ────── 4. Trainees ──────
    final trainees = [
      {
        'studentId': 'STU001',
        'userId': 'student_uid_1',
        'name': 'Sara Khalid',
        'email': 'sara@psau.edu.sa',
        'phone': '+966 55 4674 890',
        'completedHours': 120.5,
        'remainingHours': 159.5,
        'supervisorId': 'SUP001',
        'locationId': 'LOC001',
        'enrollDate': '2025-01-15',
      },
      {
        'studentId': 'STU002',
        'userId': 'student_uid_2',
        'name': 'Raghad Ja',
        'email': 'raghad@psau.edu.sa',
        'phone': '+966 55 4674 666',
        'completedHours': 95.0,
        'remainingHours': 185.0,
        'supervisorId': 'SUP001',
        'locationId': 'LOC001',
        'enrollDate': '2025-02-01',
      },
      {
        'studentId': 'STU003',
        'userId': 'student_uid_3',
        'name': 'Noura Ali',
        'email': 'noura@psau.edu.sa',
        'phone': '+966 55 1234 567',
        'completedHours': 200.0,
        'remainingHours': 80.0,
        'supervisorId': 'SUP001',
        'locationId': 'LOC001',
        'enrollDate': '2025-01-20',
      },
      {
        'studentId': 'STU004',
        'userId': 'student_uid_4',
        'name': 'Lama Hassan',
        'email': 'lama@psau.edu.sa',
        'phone': '+966 55 9876 543',
        'completedHours': 60.0,
        'remainingHours': 220.0,
        'supervisorId': 'SUP001',
        'locationId': 'LOC001',
        'enrollDate': '2025-02-10',
      },
    ];

    for (final t in trainees) {
      await _fs.collection('Trainees').doc(t['studentId'] as String).set(t);
    }
    print('  ✅ Trainees collection created');

    // ────── 5. AttendanceRecords ──────
    final records = <Map<String, dynamic>>[];
    final statuses = ['present', 'present', 'present', 'present', 'absent', 'present', 'excused'];
    final studentIds = ['STU001', 'STU002', 'STU003', 'STU004'];

    for (final sid in studentIds) {
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final status = statuses[(i + studentIds.indexOf(sid)) % statuses.length];

        records.add({
          'recordId': '${sid}_$dateStr',
          'studentId': sid,
          'date': dateStr,
          'status': status,
          'checkInTime': status == 'present' ? '08:0${i % 3}' : '',
          'checkOutTime': status == 'present' ? '17:00' : '',
          'gpsLocation': '24.1500,47.3000',
        });
      }
    }

    for (final r in records) {
      await _fs.collection('AttendanceRecords').doc(r['recordId'] as String).set(r);
    }
    print('  ✅ AttendanceRecords collection created (${records.length} records)');

    // ────── 6. Excuses ──────
    final excuses = [
      {
        'excuseId': 'EXC001',
        'studentId': 'STU003',
        'studentName': 'Noura Ali',
        'supervisorId': 'SUP001',
        'type': 'Sick Leave',
        'startDate': '2025-11-17',
        'endDate': '2025-11-17',
        'reason': 'Medical appointment',
        'status': 'pending',
        'fileUrl': '',
      },
      {
        'excuseId': 'EXC002',
        'studentId': 'STU004',
        'studentName': 'Lama Hassan',
        'supervisorId': 'SUP001',
        'type': 'Personal',
        'startDate': '2025-11-13',
        'endDate': '2025-11-13',
        'reason': 'Family emergency',
        'status': 'pending',
        'fileUrl': '',
      },
      {
        'excuseId': 'EXC003',
        'studentId': 'STU001',
        'studentName': 'Sara Khalid',
        'supervisorId': 'SUP001',
        'type': 'Sick Leave',
        'startDate': '2025-11-11',
        'endDate': '2025-11-11',
        'reason': 'Flu symptoms',
        'status': 'approved',
        'fileUrl': '',
      },
    ];

    for (final e in excuses) {
      await _fs.collection('Excuses').doc(e['excuseId'] as String).set(e);
    }
    print('  ✅ Excuses collection created');

    print('🎉 All data seeded successfully!');
    print('');
    print('⚠️  IMPORTANT: You also need to create these users in');
    print('    Firebase Auth (Console > Authentication > Add user):');
    print('');
    print('    Email: hessa88@psau.edu.sa  Password: test123456  (Supervisor)');
    print('    Email: admin@psau.edu.sa    Password: test123456  (Admin)');
    print('');
    print('    After creating them, update the userId fields in');
    print('    Users and Supervisors collections with the real UIDs.');
  }
}