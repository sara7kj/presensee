import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'attendance_screen.dart';
import 'login_page.dart';
import 'submit_excuse_page.dart';
import 'attendance_history_page.dart';
import 'theme.dart';
import 'notification_service.dart';

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
  static const targetDuration = Duration(hours: 6); // Required training time
  bool _notified = false; // Prevents repeated in-app notifications

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

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

  // ── Original logic (unchanged) ─────────────────────────────
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
          _notified = false;
          _startTimer();

          // Schedule reminder notification (if not yet expired)
          NotificationService.scheduleTrainingEndReminder(
            checkInTime: _checkInTime!,
          );
        }
      } else {
        _isCheckedIn = false;
        _checkInDocId = null;
        _checkInTime = null;
        _notified = false;
        _stopTimer();

        // Cancel any old reminder
        NotificationService.cancelTrainingReminder();
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
        // If 6 hours reached and no checkout yet
        if (_elapsed >= targetDuration && !_notified && _isCheckedIn) {
          _notified = true;
          _showMsg("Training time ended. Please check out.");
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
        backgroundColor: DS.primary900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusLG)),
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

  // ══════════════════════════════════════════════════════════════
  //  UI
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? "Student";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedScaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DS.primary500),
            )
          : Column(
              children: [
                _buildHeader(name, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DS.spaceLG),
                    child: Column(
                      children: [
                        const SizedBox(height: DS.spaceXL),
                        _buildTimerCircle(isDark),
                        const SizedBox(height: DS.spaceXL),
                        _buildActionSection(isDark),
                        const SizedBox(height: DS.spaceXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Header (CustomHeader style with logo) ──────────────────
  Widget _buildHeader(String name, bool isDark) {
    final Color gradStart = isDark ? DS.darkSurface : DS.primary700;
    final Color gradEnd = isDark ? DS.primary900 : DS.primary500;
    final Color bubbleColor =
        Colors.white.withOpacity(isDark ? 0.03 : 0.06);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + DS.spaceMD,
        bottom: DS.spaceLG,
        left: DS.spaceLG,
        right: DS.spaceLG,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(DS.spaceXL),
          bottomRight: Radius.circular(DS.spaceXL),
        ),
        boxShadow: [
          BoxShadow(
            color: DS.primary900.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: bubbleColor),
            ),
          ),
          Positioned(
            bottom: -30, left: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: bubbleColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/logos/logo_full_dark.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isCheckedIn
                              ? DS.success.withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(DS.radiusFull),
                          border: Border.all(
                            color: _isCheckedIn
                                ? DS.success.withOpacity(0.5)
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: _isCheckedIn
                                    ? DS.success
                                    : DS.neutral400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isCheckedIn ? "Active" : "Offline",
                              style: TextStyle(
                                color: _isCheckedIn
                                    ? DS.success
                                    : DS.neutral400,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DS.spaceSM),
                      // Notification test button (remove after testing)
                      GestureDetector(
                        onTap: () {
                          NotificationService.showInstantNotification(
                            title: 'Test Notification',
                            body: 'Notifications are working correctly!',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(DS.radiusMD),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: DS.spaceSM),
                      GestureDetector(
                        onTap: _signOut,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(DS.radiusMD),
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
              const SizedBox(height: DS.spaceMD),
              Text(
                "Welcome, $name 👋",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timer Circle ───────────────────────────────────────────
  Widget _buildTimerCircle(bool isDark) {
    return ScaleTransition(
      scale: _isCheckedIn ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? DS.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: (_isCheckedIn ? DS.primary500 : DS.neutral400)
                  .withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: _isCheckedIn
                    ? (_elapsed.inSeconds % 3600) / 3600
                    : 0,
                strokeWidth: 10,
                backgroundColor:
                    isDark ? DS.darkBg : DS.neutral100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isCheckedIn ? DS.primary500 : DS.neutral300,
                ),
              ),
            ),
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
                    color: _isCheckedIn
                        ? (isDark ? Colors.white : DS.primary900)
                        : DS.neutral400,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: DS.spaceXS),
                Text(
                  _isCheckedIn ? "Time elapsed" : "Not checked in",
                  style: TextStyle(
                    fontSize: 11,
                    color: DS.neutral500,
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

  // ── Action Section (new layout) ────────────────────────────
  Widget _buildActionSection(bool isDark) {
    return Column(
      children: [
        _buildMainAction(isDark),
        const SizedBox(height: DS.spaceMD),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.description_outlined,
                label: "Excuse",
                subtitle: "Submit request",
                color: DS.accentAmber,
                isDark: isDark,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SubmitExcusePage()));
                },
              ),
            ),
            const SizedBox(width: DS.spaceMD),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.history_rounded,
                label: "History",
                subtitle: "View records",
                color: DS.accentViolet,
                isDark: isDark,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainAction(bool isDark) {
    final isCheckIn = !_isCheckedIn;
    final actionColor = isCheckIn ? DS.primary500 : DS.error;
    final actionIcon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final actionLabel = isCheckIn ? "Check In" : "Check Out";
    final actionSubtitle = isCheckIn
        ? "Verify identity & mark attendance"
        : "End your session";

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceScreen(
              isCheckIn: isCheckIn,
              checkInDocId: isCheckIn ? null : _checkInDocId,
            ),
          ),
        );
        _checkTodayStatus();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DS.spaceLG),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [actionColor, actionColor.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DS.radiusXL),
          boxShadow: [
            BoxShadow(
              color: actionColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(DS.radiusLG),
              ),
              child: Icon(actionIcon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: DS.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(actionLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(actionSubtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DS.spaceMD),
        decoration: BoxDecoration(
          color: isDark ? DS.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusXL),
          border: Border.all(
              color: isDark ? DS.neutral700 : DS.neutral200),
          boxShadow: isDark ? null : DS.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(DS.radiusLG),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: DS.spaceMD),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : DS.neutral800)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: DS.neutral500)),
          ],
        ),
      ),
    );
  }
}