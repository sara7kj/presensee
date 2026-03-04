import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
              top: -size.width * 0.25,
              right: -size.width * 0.15,
              child: _bubble(size.width * 0.6, isDark),
            ),
            Positioned(
              top: size.height * 0.15,
              left: -size.width * 0.2,
              child: _bubble(size.width * 0.45, isDark),
            ),
            Positioned(
              bottom: size.height * 0.12,
              right: -size.width * 0.1,
              child: _bubble(size.width * 0.35, isDark),
            ),

            // ── Main content ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ── Logo ──
                    Image.asset(
                      'assets/logos/logo_full_dark.png',
                      width: size.width * 0.55,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: DS.spaceXL),

                    // ── Welcome text ──
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: DS.spaceSM),

                    Text(
                      'Mark your attendance with ease.\nSign in to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.65),
                        height: 1.5,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // ── Sign in button (white solid) ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: DS.primary700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DS.radiusLG),
                          ),
                        ),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: DS.spaceMD),

                    // ── Sign up button (transparent + white border) ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpPage()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DS.radiusLG),
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

                    const Spacer(flex: 1),

                    // ── Bottom quote ──
                    Text(
                      'There is no time like the PRESENT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: DS.spaceLG),
                  ],
                ),
              ),
            ),
          ],
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