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

        await _firestore
            .collection('attendance')
            .doc(widget.checkInDocId)
            .update({
          'checkOut': Timestamp.now(),
          'status': 'completed',
        });


        _showMsg("Check-out recorded successfully ✅");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMsg("Error: $e");
      setState(() => _currentStep = '');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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

    const radiusMeters = 100.0;

    for (final loc in manualLocations) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        loc['lat']!,
        loc['lng']!,
      );
      if (d <= radiusMeters) return true;
    }

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