import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'attendance_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _signIn() async {
    final email = emailC.text.trim();
    final pass = passC.text.trim();

    setState(() {
      error = null;
    });

    // ✅ Validation
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

      // ✅ نجاح الدخول -> Attendance
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent ✅")),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? e.code);
    } catch (_) {
      setState(() => error = "Something went wrong");
    }
  }

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

            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _resetPassword,
                child: const Text("Forgot password?"),
              ),
            ),

            if (error != null) ...[
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _signIn,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: loading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                child: const Text('Sign up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}