import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'face_verify_page.dart';
import 'theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmC = TextEditingController();

  bool loading = false;
  String? error;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    confirmC.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _signUp() async {
    final email = emailC.text.trim();
    final pass = passC.text.trim();
    final confirm = confirmC.text.trim();

    setState(() {
      error = null;
    });

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => error = "Please fill all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => error = "Please enter a valid email");
      return;
    }

    if (!email.endsWith('@std.psau.edu.sa')) {
      setState(() => error = "Please use your university email");
      return;
    }

    if (pass.length < 6) {
      setState(() => error = "Password must be at least 6 characters");
      return;
    }

    if (pass != confirm) {
      setState(() => error = "Passwords do not match");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'faceEmbedding': null,
        'faceEnrolled': false,
        'deviceId': null,
        'locationId': null,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FaceVerifyPage(enrollMode: true),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        error = "This email is already in use";
      } else if (e.code == 'invalid-email') {
        error = "Invalid email";
      } else if (e.code == 'weak-password') {
        error = "Weak password";
      } else {
        error = e.message;
      }
      setState(() {});
    } catch (e) {
      setState(() {
        error = "Something went wrong";
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

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
                              borderRadius: BorderRadius.circular(DS.radiusMD),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // ── Logo icon ──
                      Image.asset(
                        'assets/logos/logo_icon.png',
                        width: 56,
                        height: 56,
                      ),

                      const SizedBox(height: DS.spaceLG),

                      // ── Title ──
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: DS.spaceSM),

                      Text(
                        'Use your university email to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // ── Email field ──
                      _buildTextField(
                        controller: emailC,
                        hint: 'University Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                      ),

                      const SizedBox(height: DS.spaceMD),

                      // ── Password field ──
                      _buildTextField(
                        controller: passC,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        isDark: isDark,
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

                      const SizedBox(height: DS.spaceMD),

                      // ── Confirm Password field ──
                      _buildTextField(
                        controller: confirmC,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),

                      const SizedBox(height: DS.spaceSM),

                      // ── Error message ──
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: DS.spaceSM),
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

                      const SizedBox(height: DS.spaceLG),

                      // ── Sign up button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : _signUp,
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
                                  'Sign up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: DS.spaceMD),

                      // ── Already have account ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: DS.spaceXL),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
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