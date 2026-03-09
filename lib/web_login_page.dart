import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'supervisor_shell.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'supervisor';
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      final role = userDoc.data()!['role'] as String? ?? '';

      if (_selectedRole == 'supervisor' && role == 'supervisor') {
        final supQuery = await FirebaseFirestore.instance
            .collection('Supervisors')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();

        if (supQuery.docs.isEmpty) {
          setState(() {
            _error = 'Supervisor profile not found';
            _isLoading = false;
          });
          return;
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SupervisorShell(supervisorId: supQuery.docs.first.id),
          ),
        );
      } else if (_selectedRole == 'admin' && role == 'admin') {
        setState(() {
          _error = 'Admin dashboard coming soon';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Invalid credentials or role mismatch';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email';
          break;
        case 'wrong-password':
          msg = 'Incorrect password';
          break;
        case 'invalid-email':
          msg = 'Invalid email format';
          break;
        default:
          msg = 'Login failed. Please try again.';
      }
      setState(() {
        _error = msg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DS.primary900,
              DS.primary800,
              DS.primary700,
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Animated floating orbs ──
            ..._buildOrbs(size),

            // ── Content ──
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildLoginCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrbs(Size size) {
    return [
      AnimatedBuilder(
        animation: _animController,
        builder: (_, __) {
          final t = _animController.value * 2 * math.pi;
          return Positioned(
            top: -80 + math.sin(t) * 20,
            right: -60 + math.cos(t) * 15,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DS.primary500.withOpacity(0.15),
                    DS.primary500.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _animController,
        builder: (_, __) {
          final t = _animController.value * 2 * math.pi;
          return Positioned(
            bottom: -100 + math.cos(t * 0.7) * 25,
            left: -80 + math.sin(t * 0.7) * 20,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DS.accentTeal.withOpacity(0.1),
                    DS.accentTeal.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _animController,
        builder: (_, __) {
          final t = _animController.value * 2 * math.pi;
          return Positioned(
            top: size.height * 0.4 + math.sin(t * 1.3) * 15,
            right: size.width * 0.15 + math.cos(t * 1.3) * 10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DS.accentViolet.withOpacity(0.08),
                    DS.accentViolet.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Icon container
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: DS.primary500.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(40, 48),
              painter: _LogoPainter(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Presen',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'See',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: DS.primary300,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SMART ATTENDANCE SYSTEM',
          style: TextStyle(
            fontSize: 12,
            color: DS.primary300.withOpacity(0.7),
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 440,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to manage attendance',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 28),

          // Role Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(DS.radiusLG),
            ),
            child: Row(
              children: [
                _roleTab('Admin', 'admin', Icons.admin_panel_settings_rounded),
                _roleTab('Supervisor', 'supervisor', Icons.supervisor_account_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _label(_selectedRole == 'supervisor' ? 'Supervisor ID / Email' : 'Admin Email'),
          const SizedBox(height: 8),
          _field(
            controller: _emailController,
            hint: _selectedRole == 'supervisor' ? 'Enter your supervisor ID' : 'Enter your admin email',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),

          // Password
          _label('Password'),
          const SizedBox(height: 8),
          _field(
            controller: _passwordController,
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: Colors.white.withOpacity(0.4),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DS.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(DS.radiusMD),
                border: Border.all(color: DS.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, size: 18, color: DS.accentCoral),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: DS.accentCoral))),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          // Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: DS.primary500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DS.primary500.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusLG)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'PresenSee Management Portal v2.0',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25), letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTab(String label, String value, IconData icon) {
    final sel = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? DS.primary500.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(DS.radiusMD),
            border: Border.all(
              color: sel ? DS.primary400.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: sel ? Colors.white : Colors.white.withOpacity(0.35)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                fontSize: 14,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? Colors.white : Colors.white.withOpacity(0.35),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.6)));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(DS.radiusMD),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15, color: Colors.white),
        cursorColor: DS.primary300,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.25)),
          prefixIcon: Icon(icon, size: 20, color: Colors.white.withOpacity(0.35)),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Logo Painter — Draws the PresenSee P icon (no image needed)
// ═══════════════════════════════════════════════════════════════

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DS.primary300
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // S-like path
    final path = Path();
    path.moveTo(w * 0.25, h * 0.05);
    path.cubicTo(w * 0.05, h * 0.05, w * 0.05, h * 0.25, w * 0.25, h * 0.25);
    path.lineTo(w * 0.45, h * 0.25);
    path.cubicTo(w * 0.65, h * 0.25, w * 0.65, h * 0.5, w * 0.45, h * 0.5);
    path.lineTo(w * 0.25, h * 0.5);
    path.cubicTo(w * 0.05, h * 0.5, w * 0.05, h * 0.75, w * 0.25, h * 0.75);
    path.cubicTo(w * 0.05, h * 0.75, w * 0.05, h * 0.95, w * 0.25, h * 0.95);
    canvas.drawPath(path, paint);

    // Top arm
    final topArm = Path();
    topArm.moveTo(w * 0.55, h * 0.05);
    topArm.lineTo(w * 0.7, h * 0.05);
    topArm.cubicTo(w * 0.9, h * 0.05, w * 0.9, h * 0.25, w * 0.7, h * 0.25);
    topArm.lineTo(w * 0.55, h * 0.25);
    canvas.drawPath(topArm, paint);

    // Eye dot
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.12),
      3.5,
      Paint()..color = DS.primary400..style = PaintingStyle.fill,
    );

    // Bottom teal dot
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.92),
      2.8,
      Paint()..color = DS.accentTeal..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}