import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'face_verify_page.dart';
import 'theme.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isCheckIn;
  final String? checkInDocId;

  const AttendanceScreen({
    super.key,
    required this.isCheckIn,
    this.checkInDocId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  // Verification step tracking
  String _currentStep = ''; // '', 'location', 'face', 'done'
  bool _locationOk = false;
  bool _faceOk = false;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleAttendance() async {
    setState(() {
      isLoading = true;
      _currentStep = 'location';
      _locationOk = false;
      _faceOk = false;
    });

    try {
      // 1) التحقق من الموقع
      final inside = await _isInsideTrainingLocation();
      if (!inside) {
        _showMsg("You are outside the training location ❌");
        setState(() {
          isLoading = false;
          _currentStep = '';
        });
        return;
      }

      setState(() {
        _locationOk = true;
        _currentStep = 'face';
      });

      // 2) التحقق من الوجه
      final faceOk = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const FaceVerifyPage(enrollMode: false),
        ),
      );

      if (faceOk != true) {
        _showMsg("Face verification failed ❌");
        setState(() {
          isLoading = false;
          _currentStep = '';
        });
        return;
      }

      setState(() {
        _faceOk = true;
        _currentStep = 'done';
      });

      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? "unknown";
      final email = user?.email ?? "";

      if (widget.isCheckIn) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        final existing = await _firestore
            .collection('attendance')
            .where('uid', isEqualTo: uid)
            .where('checkIn',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('checkOut', isNull: true)
            .get();

        if (existing.docs.isNotEmpty) {
          _showMsg("You already checked in today ❌");
          setState(() {
            isLoading = false;
            _currentStep = '';
          });
          return;
        }

        await _firestore.collection('attendance').add({
          'uid': uid,
          'email': email,
          'checkIn': Timestamp.now(),
          'checkOut': null,
          'status': 'present',
        });

        // ═══════════════════════════════════════════════════════
        // ✅ ربط مع AttendanceRecords عشان يظهر عند المشرف
        // ═══════════════════════════════════════════════════════
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        final traineeQ = await _firestore
            .collection('Trainees')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();

        if (traineeQ.docs.isNotEmpty) {
          final studentId = traineeQ.docs.first['studentId'];
          await _firestore
              .collection('AttendanceRecords')
              .doc('${studentId}_$dateStr')
              .set({
            'recordId': '${studentId}_$dateStr',
            'studentId': studentId,
            'date': dateStr,
            'status': 'present',
            'checkInTime': timeStr,
            'checkOutTime': '',
            'gpsLocation': '',
          });
        }
        // ═══════════════════════════════════════════════════════

        _showMsg("Check-in recorded successfully ✅");
      } else {
        if (widget.checkInDocId == null) {
          _showMsg("No active check-in found ❌");
          setState(() {
            isLoading = false;
            _currentStep = '';
          });
          return;
        }

        // ═══════════════════════════════════════════════════════
        // ✅ 1) جيب وثيقة الـ check-in عشان نعرف وقت الدخول
        // ═══════════════════════════════════════════════════════
        final checkInDocRef = _firestore
            .collection('attendance')
            .doc(widget.checkInDocId);
        final checkInSnap = await checkInDocRef.get();
        final checkInData = checkInSnap.data();

        if (checkInData == null || checkInData['checkIn'] == null) {
          _showMsg("Check-in record missing ❌");
          setState(() {
            isLoading = false;
            _currentStep = '';
          });
          return;
        }

        final checkInTime =
            (checkInData['checkIn'] as Timestamp).toDate();
        final checkOutTime = DateTime.now();

        // ═══════════════════════════════════════════════════════
        // ✅ 2) احسب الفرق بالساعات (مع الكسور)
        // ═══════════════════════════════════════════════════════
        final diff = checkOutTime.difference(checkInTime);
        final hoursWorked = diff.inSeconds / 3600.0; // مثلاً 2.5 ساعة

        // ═══════════════════════════════════════════════════════
        // ✅ 3) حدّث وثيقة الحضور (مع تخزين الساعات)
        // ═══════════════════════════════════════════════════════
        await checkInDocRef.update({
          'checkOut': Timestamp.fromDate(checkOutTime),
          'status': 'completed',
          'hoursWorked': hoursWorked,
        });

        // ═══════════════════════════════════════════════════════
        // ✅ 4) تحديث وقت الخروج في AttendanceRecords + ساعات Trainees
        // ═══════════════════════════════════════════════════════
        final dateStr =
            '${checkOutTime.year}-${checkOutTime.month.toString().padLeft(2, '0')}-${checkOutTime.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}';

        final traineeQ = await _firestore
            .collection('Trainees')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();

        if (traineeQ.docs.isNotEmpty) {
          final traineeDoc = traineeQ.docs.first;
          final studentId = traineeDoc['studentId'];
          final traineeData = traineeDoc.data();

          // ── أ) سجّل وقت الخروج + الساعات في AttendanceRecords ──
          final docRef = _firestore
              .collection('AttendanceRecords')
              .doc('${studentId}_$dateStr');
          final docSnap = await docRef.get();
          if (docSnap.exists) {
            await docRef.update({
              'checkOutTime': timeStr,
              'hoursWorked': hoursWorked,
            });
          }

          // ── ب) ✅ المهم: حدّث Trainees (الساعات المنجزة + المتبقية) ──
          final currentCompleted =
              (traineeData['completedHours'] ?? 0).toDouble();
          final currentRemaining =
              (traineeData['remainingHours'] ?? 280).toDouble();

          final newCompleted = currentCompleted + hoursWorked;
          final newRemaining =
              (currentRemaining - hoursWorked).clamp(0, double.infinity);

          await traineeDoc.reference.update({
            'completedHours': newCompleted,
            'remainingHours': newRemaining,
          });
        }
        // ═══════════════════════════════════════════════════════

        _showMsg(
            "Check-out recorded ✅ (${hoursWorked.toStringAsFixed(2)}h added)");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMsg("Error: $e");
      setState(() => _currentStep = '');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  ✅ التحقق من موقع الطالب المعيّن فقط (من Firestore)
  // ══════════════════════════════════════════════════════════════
  Future<bool> _isInsideTrainingLocation() async {
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

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 1) جيب UID الطالب الحالي
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not authenticated");
    }

    // 2) جيب وثيقة الطالب من Trainees عشان نعرف locationId
    final traineeQuery = await _firestore
        .collection('Trainees')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (traineeQuery.docs.isEmpty) {
      throw Exception("Trainee profile not found");
    }

    final locationId = traineeQuery.docs.first.data()['locationId'];
    if (locationId == null || locationId.toString().isEmpty) {
      throw Exception("No training location assigned to you");
    }

    // 3) جيب وثيقة الموقع (نجرّب الاسمين Locations و locations للأمان)
    DocumentSnapshot? locDoc;
    try {
      locDoc = await _firestore
          .collection('Locations')
          .doc(locationId.toString())
          .get();
      if (!locDoc.exists) {
        locDoc = await _firestore
            .collection('locations')
            .doc(locationId.toString())
            .get();
      }
    } catch (_) {
      locDoc = null;
    }

    if (locDoc == null || !locDoc.exists) {
      throw Exception("Training location not found");
    }

    final locData = locDoc.data() as Map<String, dynamic>;
    final lat = (locData['lat'] as num?)?.toDouble();
    final lng = (locData['lng'] as num?)?.toDouble();
    final radius = (locData['radius'] as num?)?.toDouble() ?? 100.0;

    if (lat == null || lng == null) {
      throw Exception("Invalid location coordinates");
    }

    // 4) احسب المسافة وقارنها بنصف القطر المخصص للموقع
    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      lat,
      lng,
    );

    return distance <= radius;
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: DS.primary900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusLG)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  UI
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = widget.isCheckIn ? DS.success : DS.error;
    final title = widget.isCheckIn ? "Check In" : "Check Out";

    return ThemedScaffold(
      appBar: CustomHeader(
        title: title,
        showBack: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DS.spaceLG),
          child: Column(
            children: [
              const SizedBox(height: DS.spaceLG),

              // ── Logo Icon ──
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
                    width: 1.5,
                  ),
                ),
                child: Image.asset(
                  'assets/logos/logo_icon.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: DS.spaceLG),

              // ── Title & Subtitle ──
              Text(
                widget.isCheckIn
                    ? "Ready to check in?"
                    : "Ready to check out?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : DS.neutral900,
                ),
              ),
              const SizedBox(height: DS.spaceSM),
              Text(
                widget.isCheckIn
                    ? "We'll verify your location and identity\nto mark your attendance."
                    : "We'll verify your identity to\nend your session.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: DS.neutral500,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: DS.spaceXL),

              // ── Verification Steps Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DS.spaceLG),
                decoration: BoxDecoration(
                  color: isDark ? DS.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(DS.radiusXL),
                  border: Border.all(
                    color: isDark ? DS.neutral700 : DS.neutral200,
                  ),
                  boxShadow: isDark ? null : DS.shadowSM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verification steps",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? DS.neutral300 : DS.neutral600,
                      ),
                    ),
                    const SizedBox(height: DS.spaceMD),

                    // Step 1: Location
                    _buildVerificationStep(
                      icon: Icons.location_on_outlined,
                      label: "Location verification",
                      subtitle: "Confirm you're at the training site",
                      status: _getStepStatus('location'),
                      isDark: isDark,
                    ),

                    // Connector line
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Container(
                        width: 2,
                        height: 20,
                        color: isDark ? DS.neutral700 : DS.neutral200,
                      ),
                    ),

                    // Step 2: Face
                    _buildVerificationStep(
                      icon: Icons.face_rounded,
                      label: "Face recognition",
                      subtitle: "Verify your identity",
                      status: _getStepStatus('face'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DS.spaceXL),

              // ── Main Action Button ──
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: actionColor.withOpacity(0.5),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(DS.radiusXL),
                    ),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: DS.spaceMD),
                            Text(
                              _getLoadingText(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isCheckIn
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: DS.spaceSM),
                            Text(
                              widget.isCheckIn
                                  ? "Start Check In"
                                  : "Start Check Out",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: DS.spaceMD),

              // ── Info note ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DS.spaceMD),
                decoration: BoxDecoration(
                  color: isDark
                      ? DS.info.withOpacity(0.1)
                      : DS.info.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(DS.radiusLG),
                  border: Border.all(
                    color: DS.info.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: DS.info,
                      size: 20,
                    ),
                    const SizedBox(width: DS.spaceSM),
                    Expanded(
                      child: Text(
                        widget.isCheckIn
                            ? "Make sure your face is clearly visible and you're at the training location."
                            : "Make sure your face is clearly visible for verification.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? DS.neutral300 : DS.neutral600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DS.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  // ── Verification step item ─────────────────────────────────
  // status: 'pending' | 'active' | 'done' | 'idle'
  String _getStepStatus(String step) {
    if (_currentStep == '') return 'idle';
    if (step == 'location') {
      if (_locationOk) return 'done';
      if (_currentStep == 'location') return 'active';
      return 'idle';
    }
    if (step == 'face') {
      if (_faceOk) return 'done';
      if (_currentStep == 'face') return 'active';
      return 'idle';
    }
    return 'idle';
  }

  String _getLoadingText() {
    switch (_currentStep) {
      case 'location':
        return 'Checking location...';
      case 'face':
        return 'Verifying face...';
      case 'done':
        return 'Recording...';
      default:
        return 'Processing...';
    }
  }

  Widget _buildVerificationStep({
    required IconData icon,
    required String label,
    required String subtitle,
    required String status,
    required bool isDark,
  }) {
    Color iconBgColor;
    Color iconColor;
    Widget? trailing;

    switch (status) {
      case 'done':
        iconBgColor = DS.success.withOpacity(0.12);
        iconColor = DS.success;
        trailing = const Icon(Icons.check_circle_rounded,
            color: DS.success, size: 22);
        break;
      case 'active':
        iconBgColor = DS.primary500.withOpacity(0.12);
        iconColor = DS.primary500;
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: DS.primary500,
          ),
        );
        break;
      default: // idle
        iconBgColor = isDark
            ? DS.neutral700.withOpacity(0.5)
            : DS.neutral100;
        iconColor = DS.neutral400;
        trailing = null;
    }

    return Row(
      children: [
        // Step icon
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(DS.radiusLG),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: DS.spaceMD),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: status == 'idle'
                      ? DS.neutral400
                      : (isDark ? Colors.white : DS.neutral800),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: DS.neutral500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}