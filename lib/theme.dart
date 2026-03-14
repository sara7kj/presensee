import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  PresenSee Design System — v2.0
//  Tokens, Theme, Components
// ═══════════════════════════════════════════════════════════════

/// Central design tokens for the entire app.
/// Import this class anywhere you need raw color / spacing values.
class DS {
  DS._(); // non-instantiable

  // ────────── Primary Blues ──────────
  static const Color primary900 = Color(0xFF0B1D3A);
  static const Color primary800 = Color(0xFF122B54);
  static const Color primary700 = Color(0xFF1A3A6E);
  static const Color primary600 = Color(0xFF234B8A);
  static const Color primary500 = Color(0xFF2D5FA5); // main primary
  static const Color primary400 = Color(0xFF4A7EC4);
  static const Color primary300 = Color(0xFF7BA3DB);
  static const Color primary200 = Color(0xFFADC8EC);
  static const Color primary100 = Color(0xFFD6E4F6);
  static const Color primary50 = Color(0xFFEBF2FB);

  // ────────── Accent Colors ──────────
  static const Color accentTeal = Color(0xFF0EA5A0);
  static const Color accentMint = Color(0xFF34D399);
  static const Color accentCoral = Color(0xFFF87171);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentViolet = Color(0xFF8B5CF6);

  // ────────── Neutrals ──────────
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);

  // ────────── Semantic ──────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ────────── Attendance Status ──────────
  static const Color statusPresent = Color(0xFF10B981);
  static const Color statusAbsent = Color(0xFFEF4444);
  static const Color statusLate = Color(0xFFF59E0B);
  static const Color statusExcused = Color(0xFF8B5CF6);

  // Status badge backgrounds (light tint)
  static const Color statusPresentBg = Color(0xFFD1FAE5);
  static const Color statusAbsentBg = Color(0xFFFEE2E2);
  static const Color statusLateBg = Color(0xFFFEF3C7);
  static const Color statusExcusedBg = Color(0xFFEDE9FE);

  // ────────── Dark theme surfaces ──────────
  static const Color darkBg = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D27);
  static const Color darkCard = Color(0xFF222634);

  // ────────── Spacing ──────────
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double space2XL = 48;

  // ────────── Radii ──────────
  static const double radiusSM = 4;
  static const double radiusMD = 8;
  static const double radiusLG = 12;
  static const double radiusXL = 16;
  static const double radiusFull = 999;

  // ────────── Shadows ──────────
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
//  AppTheme — Light & Dark ThemeData builders
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  // Keep legacy aliases so existing code doesn't break
  static const Color primaryPurple = DS.primary500;
  static const Color accentCoral = DS.accentCoral;

  // ────── common widget themes ──────

  static final SwitchThemeData _baseSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((_) => Colors.white),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return DS.primary500;
      return DS.neutral400;
    }),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
  );

  static InputDecorationTheme _inputDecoration({required bool isDark}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DS.radiusMD),
      borderSide: BorderSide(
        color: isDark ? DS.neutral700 : DS.neutral300,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DS.radiusMD),
      borderSide: const BorderSide(color: DS.primary500, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DS.radiusMD),
      borderSide: const BorderSide(color: DS.error, width: 1.5),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? DS.darkCard : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DS.spaceMD,
        vertical: 14,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      hintStyle: TextStyle(
        color: isDark ? DS.neutral500 : DS.neutral400,
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        color: isDark ? DS.neutral400 : DS.neutral600,
        fontSize: 14,
      ),
    );
  }

  // ────────── LIGHT THEME ──────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Calibri', // Design System body font
      primaryColor: DS.primary500,
      scaffoldBackgroundColor: DS.neutral50,
      colorScheme: const ColorScheme.light(
        primary: DS.primary500,
        onPrimary: Colors.white,
        primaryContainer: DS.primary100,
        onPrimaryContainer: DS.primary900,
        secondary: DS.accentTeal,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE6FAF8),
        tertiary: DS.accentViolet,
        error: DS.error,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: DS.neutral800,
        onSurfaceVariant: DS.neutral600,
        outline: DS.neutral300,
        outlineVariant: DS.neutral200,
      ),

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: DS.primary500,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMD),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DS.primary500,
          side: const BorderSide(color: DS.primary300, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMD),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DS.primary500,
          textStyle: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FAB ──
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DS.primary500,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusLG),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: DS.spaceMD,
          vertical: DS.spaceSM,
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: DS.primary50,
        selectedColor: DS.primary500,
        labelStyle: const TextStyle(fontSize: 13, fontFamily: 'Calibri'),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontFamily: 'Calibri',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Input ──
      inputDecorationTheme: _inputDecoration(isDark: false),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: DS.primary500,
        unselectedItemColor: DS.neutral400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: DS.neutral200,
        thickness: 1,
        space: 0,
      ),

      // ── Text ──
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: DS.neutral900,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: DS.neutral900,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DS.neutral800,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DS.neutral800,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DS.neutral800,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: DS.neutral700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: DS.neutral600,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: DS.neutral500,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DS.neutral700,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: DS.neutral400,
          letterSpacing: 0.5,
        ),
      ),

      switchTheme: _baseSwitchTheme,
    );
  }

  // ────────── DARK THEME ──────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Calibri',
      primaryColor: DS.primary400,
      scaffoldBackgroundColor: DS.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: DS.primary400,
        onPrimary: Colors.white,
        primaryContainer: DS.primary800,
        onPrimaryContainer: DS.primary100,
        secondary: DS.accentTeal,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF1A3D3C),
        tertiary: DS.accentViolet,
        error: DS.accentCoral,
        onError: Colors.white,
        surface: DS.darkSurface,
        onSurface: Color(0xFFE2E8F0),
        onSurfaceVariant: DS.neutral400,
        outline: DS.neutral700,
        outlineVariant: DS.neutral800,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: DS.darkSurface,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Calibri',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMD),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Calibri',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DS.primary300,
          side: const BorderSide(color: DS.primary700, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMD),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DS.primary300,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DS.primary500,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: DS.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusLG),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: DS.spaceMD,
          vertical: DS.spaceSM,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DS.primary900,
        selectedColor: DS.primary500,
        labelStyle: const TextStyle(
            fontSize: 13, fontFamily: 'Calibri', color: DS.neutral300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusFull),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: _inputDecoration(isDark: true),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DS.darkSurface,
        selectedItemColor: DS.primary300,
        unselectedItemColor: DS.neutral600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: DS.neutral800,
        thickness: 1,
        space: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFFCBD5E1),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: DS.neutral400,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: DS.neutral500,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFCBD5E1),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: DS.neutral500,
          letterSpacing: 0.5,
        ),
      ),
      switchTheme: _baseSwitchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DS.primary500;
          return DS.neutral700;
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SnackHelper — Toast-style notifications
// ═══════════════════════════════════════════════════════════════

class SnackHelper {
  static void success(BuildContext context, String message) {
    _show(context, message, DS.success, Icons.check_circle_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, DS.error, Icons.error_rounded);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, DS.warning, Icons.warning_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, DS.info, Icons.info_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: DS.spaceSM),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: DS.spaceMD,
          vertical: DS.spaceSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.radiusMD),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  JadeerDialog — Branded dialog
// ═══════════════════════════════════════════════════════════════

class JadeerDialog<T> extends StatelessWidget {
  final String title;
  final Widget? content;
  final String primaryLabel;
  final T? primaryResult;
  final String? secondaryLabel;
  final T? secondaryResult;
  final double width;
  final bool isDanger; // if true, primary button uses error color

  const JadeerDialog({
    super.key,
    required this.title,
    this.content,
    required this.primaryLabel,
    this.primaryResult,
    this.secondaryLabel,
    this.secondaryResult,
    this.width = 420,
    this.isDanger = false,
  });
// أضف هذه الدالة داخل الكلاس لسهولة الاستدعاء
  Future<T?> show<T>(BuildContext context) {
    return showDialog<T>(
      context: context,
      builder: (context) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? DS.darkCard.withOpacity(0.95)
        : DS.primary800.withOpacity(0.92);
    final primaryBtnColor = isDanger ? DS.error : DS.accentTeal;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DS.radiusXL + 4),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: content == null
          ? null
          : ConstrainedBox(
              constraints: BoxConstraints(minWidth: width, maxWidth: width),
              child: SingleChildScrollView(
                child: Center(
                  child: DefaultTextStyle(
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    child: content!,
                  ),
                ),
              ),
            ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (secondaryLabel != null)
          TextButton(
            onPressed: () => Navigator.pop<T>(context, secondaryResult),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.radiusLG),
              ),
            ),
            child: Text(
              secondaryLabel!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        if (secondaryLabel != null) const SizedBox(width: 12),
        TextButton(
          onPressed: () => Navigator.pop<T>(context, primaryResult),
          style: TextButton.styleFrom(
            backgroundColor: primaryBtnColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DS.radiusLG),
            ),
          ),
          child: Text(
            primaryLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AppSettingsNotifier — Theme mode controller
// ═══════════════════════════════════════════════════════════════

class AppSettingsNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  EmptyState — Placeholder for empty screens
// ═══════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action; // optional CTA button

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DS.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 48, color: scheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: DS.spaceMD),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: DS.spaceSM),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: DS.spaceLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CustomHeader — Gradient app bar with decorative bubbles
// ═══════════════════════════════════════════════════════════════

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;

  const CustomHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color gradStart = isDark ? DS.darkSurface : DS.primary700;
    final Color gradEnd = isDark ? DS.primary900 : DS.primary500;
    final Color bubbleColor = Colors.white.withOpacity(isDark ? 0.03 : 0.06);
    final Color shadow = DS.primary900.withOpacity(isDark ? 0.5 : 0.3);

    return Container(
      height: preferredSize.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -40,
            child: _bubble(200, bubbleColor),
          ),
          Positioned(
            bottom: -20,
            left: -30,
            child: _bubble(140, bubbleColor),
          ),
          // Content
          SafeArea(
            child: Stack(
              children: [
                if (leading != null)
                  Align(alignment: Alignment.centerLeft, child: leading!)
                else if (showBack && canPop)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                if (actions != null && actions!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ThemedScaffold — Convenience scaffold with theme-aware bg
// ═══════════════════════════════════════════════════════════════

class ThemedScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool? resizeToAvoidBottomInset;
  final Color? overridePageBgColor;

  const ThemedScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset,
    this.overridePageBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pageBg =
        overridePageBgColor ?? (isDark ? DS.darkBg : DS.neutral50);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  StatusBadge — Attendance status chip
// ═══════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  /// Factory constructors for attendance statuses
  factory StatusBadge.present() => const StatusBadge(
        label: 'Present',
        color: DS.statusPresent,
        backgroundColor: DS.statusPresentBg,
      );

  factory StatusBadge.absent() => const StatusBadge(
        label: 'Absent',
        color: DS.statusAbsent,
        backgroundColor: DS.statusAbsentBg,
      );

  factory StatusBadge.late() => const StatusBadge(
        label: 'Late',
        color: DS.statusLate,
        backgroundColor: DS.statusLateBg,
      );

  factory StatusBadge.excused() => const StatusBadge(
        label: 'Excused',
        color: DS.statusExcused,
        backgroundColor: DS.statusExcusedBg,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DS.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
