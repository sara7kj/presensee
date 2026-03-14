import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  bool loading = false;
  bool _obscurePass = true;
  String? error;

  // ── Animations ──
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ──
  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _signIn() async {
    final email = emailC.text.trim();
    final pass = passC.text.trim();

    setState(() {
      error = null;
    });

    if (email.isEmpty || pass.isEmpty) {
      setState(() => error = "Please enter email and password");
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => error = "Please enter a valid email");
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        error = "No account found for this email";
      } else if (e.code == 'wrong-password') {
        error = "Wrong password";
      } else if (e.code == 'invalid-email') {
        error = "Invalid email";
      } else {
        error = e.message ?? e.code;
      }
      setState(() {});
    } catch (e) {
      setState(() {
        error = "Something went wrong";
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailC.text.trim();
    setState(() => error = null);

    if (email.isEmpty) {
      setState(() => error = "Enter your email first");
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => error = "Please enter a valid email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      SnackHelper.success(context, "Password reset email sent");
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? e.code);
    } catch (_) {
      setState(() => error = "Something went wrong");
    }
  }

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [DS.primary900, DS.darkBg]
                : [DS.primary700, DS.primary500],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative bubbles ──
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: _bubble(size.width * 0.6, isDark),
            ),
            Positioned(
              bottom: -size.width * 0.15,
              left: -size.width * 0.2,
              child: _bubble(size.width * 0.5, isDark),
            ),

            // ── Content ──
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: DS.spaceMD),

                          // ── Back button ──
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(DS.radiusMD),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.03),

                          // ── Logo ──
                          Image.asset(
                            'assets/logos/logo_icon.png',
                            width: 56,
                            height: 56,
                          ),

                          const SizedBox(height: DS.spaceLG),

                          // ── Title ──
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: DS.spaceSM),

                          Text(
                            'Sign in to track your field training',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),

                          const SizedBox(height: DS.spaceSM),

                          // ── Feature chips ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildChip(Icons.location_on_outlined, "GPS"),
                              const SizedBox(width: 8),
                              _buildChip(
                                  Icons.face_retouching_natural, "Face ID"),
                              const SizedBox(width: 8),
                              _buildChip(Icons.shield_outlined, "Secure"),
                            ],
                          ),

                          SizedBox(height: size.height * 0.04),

                          // ── Email field ──
                          _buildTextField(
                            controller: emailC,
                            hint: 'University Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: DS.spaceMD),

                          // ── Password field ──
                          _buildTextField(
                            controller: passC,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePass,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.white.withOpacity(0.4),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),

                          // ── Forgot password ──
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: loading ? null : _resetPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.7),
                                padding: const EdgeInsets.only(top: 4),
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // ── Error message ──
                          if (error != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: DS.spaceMD),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DS.spaceMD,
                                  vertical: DS.spaceSM + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DS.error.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(DS.radiusMD),
                                  border: Border.all(
                                    color: DS.error.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: DS.accentCoral,
                                      size: 18,
                                    ),
                                    const SizedBox(width: DS.spaceSM),
                                    Expanded(
                                      child: Text(
                                        error!,
                                        style: const TextStyle(
                                          color: DS.accentCoral,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Sign in button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: loading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: DS.primary700,
                                disabledBackgroundColor:
                                    Colors.white.withOpacity(0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(DS.radiusLG),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: DS.primary500,
                                      ),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: DS.spaceLG),

                          // ── Divider ──
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.45),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                            ],
                          ),

                          const SizedBox(height: DS.spaceMD),

                          // ── Sign up button ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const SignUpPage()),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(DS.radiusLG),
                                ),
                              ),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: DS.spaceXL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Components ──

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: DS.spaceMD, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusMD),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DS.radiusMD),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DS.radiusFull),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DS.primary200, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(isDark ? 0.03 : 0.07),
      ),
    );
  }
}
