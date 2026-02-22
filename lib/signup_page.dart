import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'face_verify_page.dart';

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

    // ✅ Validation
    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => error = "Please fill all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => error = "Please enter a valid email");
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
        'createdAt': FieldValue.serverTimestamp(),
        'faceEmbedding': null,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 12),

            TextField(
              controller: confirmC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (error != null) ...[
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _signUp,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}