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
                    const Spacer(flex: 2),

                    // ── Logo ──
                    Image.asset(
                      'assets/models/logos/logo_full_dark.png',
                      width: size.width * 0.6,
                      fit: BoxFit.contain,
                    ),

                    const Spacer(flex: 1),

                    // Welcome card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DS.spaceLG),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DS.darkCard.withOpacity(0.8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(DS.radiusXL + 8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : DS.primary900,
                            ),
                          ),

                          const SizedBox(height: DS.spaceSM),

                          Text(
                            'Mark your attendance with ease.\nSign in to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? DS.neutral400
                                  : DS.neutral500,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: DS.spaceLG),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DS.primary500,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(DS.radiusLG),
                                ),
                              ),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: DS.spaceSM + 4),

                          // Sign up button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpPage()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    isDark ? DS.primary300 : DS.primary500,
                                side: BorderSide(
                                  color: isDark
                                      ? DS.primary700
                                      : DS.primary200,
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
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Bottom quote
                    Text(
                      'There is no time like the PRESENT',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.45),
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

  /// Decorative translucent circle
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