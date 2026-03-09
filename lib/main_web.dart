import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'web_login_page.dart';

/// ═══════════════════════════════════════════════════════
///  main_web.dart — نقطة الدخول للويب فقط
///
///  شغّله بهالأمر:
///  flutter run -d chrome -t lib/main_web.dart
/// ═══════════════════════════════════════════════════════

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PresenSeeWeb());
}

class PresenSeeWeb extends StatelessWidget {
  const PresenSeeWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PresenSee - Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const WebLoginPage(),
    );
  }
}