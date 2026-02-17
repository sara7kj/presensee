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

  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final email = emailC.text.trim();
      final pass = passC.text.trim();

      if (email.isEmpty || pass.isEmpty) {
        throw Exception("Please enter email and password.");
      }

      // 1) Create user in Auth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final uid = cred.user!.uid;

      // 2) Create user doc in Firestore: users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        // نخليه فاضي لين نسجل الوجه
        'faceEmbedding': null,
      });

      if (!mounted) return;

      // 3) Go to FaceVerifyPage (enroll face next)
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const FaceVerifyPage(enrollMode: true),
  ),
  );

    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.message ?? e.code;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
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
            const SizedBox(height: 16),

            TextField(
              controller: emailC,
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
