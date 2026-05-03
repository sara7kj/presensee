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

class _WebLoginPageState extends State<WebLoginPage> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'supervisor';
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  late AnimationController _orbAnim;
  late AnimationController _fadeAnim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _orbAnim = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _fadeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOut);
    _fadeAnim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _orbAnim.dispose();
    _fadeAnim.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text,
      );
      final uid = cred.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        setState(() { _error = 'User not found'; _loading = false; });
        return;
      }

      final userData = userDoc.data()!;
      final role = userData['role'] as String? ?? '';

      if (_role == 'supervisor' && role == 'supervisor') {
        // جيب كل بيانات السوبرفايزر من Firestore
        final supQ = await FirebaseFirestore.instance
            .collection('Supervisors')
            .where('userId', isEqualTo: uid)
            .limit(1)
            .get();

        if (supQ.docs.isEmpty) {
          setState(() { _error = 'Supervisor profile not found'; _loading = false; });
          return;
        }

        final supData = supQ.docs.first.data();
        final supervisorId = supQ.docs.first.id;

        if (!mounted) return;

        // نمرر كل البيانات للداشبورد
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => SupervisorShell(
            supervisorId: supervisorId,
            supervisorName: supData['name']?.toString() ?? userData['username']?.toString() ?? 'Supervisor',
            supervisorEmail: supData['email']?.toString() ?? cred.user!.email ?? '',
            department: supData['department']?.toString() ?? '',
          )),
        );

      } else if (_role == 'admin' && role == 'admin') {
        setState(() { _error = 'Admin dashboard coming soon'; _loading = false; });
      } else {
        setState(() { _error = 'Role mismatch. Select the correct role.'; _loading = false; });
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No account with this email',
        'wrong-password' => 'Incorrect password',
        'invalid-email' => 'Invalid email format',
        _ => 'Login failed. Try again.',
      };
      setState(() { _error = msg; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Something went wrong'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF060D1B), DS.primary900, Color(0xFF0A1628)],
          ),
        ),
        child: Stack(children: [
          CustomPaint(size: sz, painter: _GridPainter()),
          ..._orbs(sz),
          Center(child: FadeTransition(opacity: _fade, child: SingleChildScrollView(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 40),
              _logo(),
              const SizedBox(height: 48),
              _card(),
              const SizedBox(height: 40),
            ]),
          ))),
        ]),
      ),
    );
  }

  List<Widget> _orbs(Size sz) => [
    _orb(sz, -80, null, null, -60, 300, DS.primary500, 0.12, 1.0),
    _orb(sz, null, -100, -80, null, 350, DS.accentTeal, 0.08, 0.7),
    _orb(sz, sz.height * 0.35, null, null, sz.width * 0.1, 200, DS.accentViolet, 0.06, 1.3),
  ];

  Widget _orb(Size sz, double? top, double? bottom, double? left, double? right,
      double size, Color color, double opacity, double speed) {
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, __) {
        final t = _orbAnim.value * 2 * math.pi * speed;
        return Positioned(
          top: top != null ? top + math.sin(t) * 20 : null,
          bottom: bottom != null ? bottom + math.cos(t) * 25 : null,
          left: left != null ? left + math.sin(t) * 20 : null,
          right: right != null ? right + math.cos(t) * 15 : null,
          child: Container(width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withOpacity(opacity), color.withOpacity(0)]))),
        );
      },
    );
  }

  Widget _logo() => Column(children: [
    Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: DS.primary500.withOpacity(0.2), blurRadius: 40, spreadRadius: 8)],
      ),
      padding: const EdgeInsets.all(14),
      child: Image.asset('assets/logos/logo_icon.png', fit: BoxFit.contain),
    ),
    const SizedBox(height: 24),
    Image.asset('assets/logos/logo_full_dark.png', height: 44, fit: BoxFit.contain),
  ]);

  Widget _card() => Container(
    width: 420, padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.03)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 50, offset: const Offset(0, 20))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Welcome back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      Text('Sign in to your management portal', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45))),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          _roleBtn('Admin', 'admin', Icons.shield_rounded),
          _roleBtn('Supervisor', 'supervisor', Icons.supervisor_account_rounded),
        ]),
      ),
      const SizedBox(height: 24),
      _lbl('Email'), const SizedBox(height: 6),
      _input(_emailCtrl, 'Enter your email', Icons.email_outlined, false, null),
      const SizedBox(height: 18),
      _lbl('Password'), const SizedBox(height: 6),
      _input(_passCtrl, 'Enter your password', Icons.lock_outline_rounded, _obscure,
        IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18, color: Colors.white.withOpacity(0.3)),
          onPressed: () => setState(() => _obscure = !_obscure))),
      if (_error != null) ...[
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: DS.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DS.error.withOpacity(0.2))),
          child: Row(children: [
            const Icon(Icons.error_outline, size: 16, color: DS.accentCoral),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: DS.accentCoral))),
          ])),
      ],
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: DS.primary500, foregroundColor: Colors.white,
            disabledBackgroundColor: DS.primary500.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        )),
      const SizedBox(height: 16),
      Center(child: Text('PresenSee Management v2.0', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.2)))),
    ]),
  );

  Widget _roleBtn(String label, String val, IconData icon) {
    final sel = _role == val;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _role = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: sel ? DS.primary500.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? DS.primary400.withOpacity(0.4) : Colors.transparent)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: sel ? Colors.white : Colors.white.withOpacity(0.3)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
            color: sel ? Colors.white : Colors.white.withOpacity(0.3))),
        ]),
      ),
    ));
  }

  Widget _lbl(String t) => Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.5)));

  // ══════════════════════════════════════════════════════════════
  // ✅ تعديل function _input لإصلاح مشكلة autofill (أبيض على أبيض)
  // ══════════════════════════════════════════════════════════════
  Widget _input(TextEditingController ctrl, String hint, IconData icon, bool obs, Widget? suf) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obs,
        // ✅ إجبار لون النص أبيض دائماً (حتى مع autofill)
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          decoration: TextDecoration.none,
        ),
        cursorColor: DS.primary300,
        // ✅ تعطيل autofill عشان المتصفح ما يخرب الألوان
        autofillHints: null,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.3),
          ),
          prefixIcon: Icon(icon, size: 18, color: Colors.white.withOpacity(0.4)),
          suffixIcon: suf,
          // ✅ إجبار خلفية الحقل شفافة (داخل الـ Container الأصلي)
          filled: true,
          fillColor: Colors.transparent,
          // ✅ إزالة كل البوردرات عشان الـ Container الأم يتولى الستايل
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.015)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 60) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 60) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}