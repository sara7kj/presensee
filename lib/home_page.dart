import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'attendance_screen.dart';
import 'login_page.dart';
import 'submit_excuse_page.dart';       // اسم ملف الـ Excuse عندك
import 'attendance_history_page.dart';      // اسم ملف الـ History عندك

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isCheckedIn = false;
  String? _checkInDocId;
  DateTime? _checkInTime;

  // Timer
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  const targetDuration = Duration(hours: 6); // الوقت المطلوب
  bool _notified = false; // عشان ما يتكرر الإشعار  

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Brand Colors
  static const Color kNavy      = Color(0xFF1B2B4B);
  static const Color kBlue      = Color(0xFF2D5BE3);
  static const Color kLightBlue = Color(0xFF5B8AF0);
  static const Color kBg        = Color(0xFFF5F7FF);
  static const Color kGrey      = Color(0xFF8A94A6);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkTodayStatus();
  }

  // ── اللوجيك الأصلي بدون تغيير ─────────────────────────────
  Future<void> _checkTodayStatus() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: uid)
          .where('checkIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('checkOut', isNull: true)
          .get();

      if (query.docs.isNotEmpty) {
        _isCheckedIn = true;
        _checkInDocId = query.docs.first.id;
        final data = query.docs.first.data();
        if (data['checkIn'] is Timestamp) {
          _checkInTime = (data['checkIn'] as Timestamp).toDate();
          _startTimer();
        }
      } else {
        _isCheckedIn = false;
        _checkInDocId = null;
        _checkInTime = null;
        _stopTimer();
      }
    } catch (e) {
      _showMsg("Error checking status: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _checkInTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_checkInTime!);
        });
        // اذا وصل 6 ساعات وما سوا checkout
        if (_elapsed >= targetDuration && !_notified && _isCheckedIn) {
         _notified = true ;
         _showMsg("انتهى وقت التدريب الرجاء تسجيل الخروج")
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _elapsed = Duration.zero;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? "Student";

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kBlue),
              )
            : Column(
                children: [
                  // ── Top Bar ──────────────────────────────
                  _buildTopBar(name),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // ── Timer Circle ─────────────────
                          _buildTimerCircle(),

                          const SizedBox(height: 40),

                          // ── Action Buttons ───────────────
                          _buildActionButtons(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────
  Widget _buildTopBar(String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: const BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Welcome
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                      children: [
                        TextSpan(
                            text: "Presen",
                            style: TextStyle(color: Colors.white)),
                        TextSpan(
                            text: "See",
                            style: TextStyle(color: kLightBlue)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Welcome, $name 👋",
                style: const TextStyle(
                  color: kLightBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Status + Logout
          Row(
            children: [
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isCheckedIn
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isCheckedIn
                        ? Colors.green.shade300
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isCheckedIn ? Colors.green : kGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isCheckedIn ? "Active" : "Offline",
                      style: TextStyle(
                        color:
                            _isCheckedIn ? Colors.green.shade300 : kGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Logout
              GestureDetector(
                onTap: _signOut,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timer Circle ───────────────────────────────────────────
  Widget _buildTimerCircle() {
    return ScaleTransition(
      scale: _isCheckedIn ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: (_isCheckedIn ? kBlue : kGrey).withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: _isCheckedIn
                    ? (_elapsed.inSeconds % 3600) / 3600
                    : 0,
                strokeWidth: 10,
                backgroundColor: kBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isCheckedIn ? kBlue : kGrey.withOpacity(0.3),
                ),
              ),
            ),
            // Timer text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isCheckedIn
                      ? _formatDuration(_elapsed)
                      : "00:00:00",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _isCheckedIn ? kNavy : kGrey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isCheckedIn ? "Time elapsed" : "Not checked in",
                  style: TextStyle(
                    fontSize: 11,
                    color: kGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Check In / Check Out
        if (!_isCheckedIn)
          _buildMainButton(
            label: "Check In",
            icon: Icons.login_rounded,
            color: kBlue,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AttendanceScreen(isCheckIn: true),
                ),
              );
              _checkTodayStatus();
            },
          ),

        if (_isCheckedIn)
          _buildMainButton(
            label: "Check Out",
            icon: Icons.logout_rounded,
            color: const Color(0xFFE53935),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceScreen(
                    isCheckIn: false,
                    checkInDocId: _checkInDocId,
                  ),
                ),
              );
              _checkTodayStatus();
            },
          ),

        const SizedBox(height: 16),

        // Secondary Buttons Row
        Row(
  children: [
    Expanded(
      child: _buildSecondaryButton(
        label: "Excuse",
        icon: Icons.description_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitExcusePage()),
          );
        },
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildSecondaryButton(
        label: "History",
        icon: Icons.history_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()),
          );
        },
      ),
    ),
  ],
),
      ],
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: kNavy),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kNavy,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}