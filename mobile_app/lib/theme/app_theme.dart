import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static Brightness _brightness = Brightness.light;
  static Brightness get currentBrightness => _brightness;
  static void updateBrightness(Brightness b) { _brightness = b; }

  // ── Core palette ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5B9BD5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  static Color get background => _brightness == Brightness.dark ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5);
  static Color get foreground => _brightness == Brightness.dark ? const Color(0xFFE8E8F0) : const Color(0xFF1A2332);

  static Color get card => _brightness == Brightness.dark ? const Color(0xFF1C2333) : const Color(0xFFFFFFFF);
  static Color get cardForeground => _brightness == Brightness.dark ? const Color(0xFFE8E8F0) : const Color(0xFF1A2332);

  static Color get muted => _brightness == Brightness.dark ? const Color(0xFF2D2D3A) : const Color(0xFFE8ECF1);
  static Color get mutedForeground => _brightness == Brightness.dark ? const Color(0xFF9E9EB0) : const Color(0xFF6B7280);

  static const Color accent = Color(0xFF00897B);
  static const Color accentLight = Color(0xFF4DB6AC);
  static const Color accentForeground = Color(0xFFFFFFFF);

  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFAFAFA);

  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);

  static Color get border => _brightness == Brightness.dark ? const Color(0xFF333344) : const Color(0xFF8B95A5);

  static Color get glassBg => _brightness == Brightness.dark ? const Color(0xCC1C2333) : const Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);

  // ── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF00695C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF0F2F5), Color(0xFFE8ECF1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const List<Color> meshColors = [
    Color(0xFF1565C0),
    Color(0xFF0D47A1),
    Color(0xFF00897B),
    Color(0xFF1A237E),
  ];

  // ── Glassmorphism helpers ──────────────────────────────────────────

  static Color _surfaceFor(Brightness brightness) =>
    brightness == Brightness.dark ? darkCard : Colors.white;

  static Color _borderFor(Brightness brightness) =>
    brightness == Brightness.dark ? darkBorder : Colors.white;

  static BoxDecoration glassDecoration({
    double blur = 20,
    double borderRadius = 16,
    double opacity = 0.7,
    Brightness? brightness,
  }) {
    final b = brightness ?? _brightness;
    final bg = _surfaceFor(b);
    final bd = _borderFor(b);
    return BoxDecoration(
      color: bg.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: bd.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ── 3D Depth helpers ───────────────────────────────────────────────

  static List<BoxShadow> depthShadows({double depth = 1.0}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08 * depth),
        blurRadius: 16 * depth,
        offset: Offset(0, 6 * depth),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04 * depth),
        blurRadius: 6 * depth,
        offset: Offset(0, 2 * depth),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.6 * depth),
        blurRadius: 1 * depth,
        offset: Offset(0, -1 * depth),
      ),
    ];
  }

  static BoxDecoration depthCard({
    double borderRadius = 16,
    Color? color,
    double depth = 1.0,
    Brightness? brightness,
  }) {
    final b = brightness ?? _brightness;
    final bg = color ?? (b == Brightness.dark ? darkCard : card);
    final bd = b == Brightness.dark ? darkBorder : border;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: bd, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08 * depth),
          blurRadius: 20 * depth,
          offset: Offset(0, 8 * depth),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04 * depth),
          blurRadius: 6 * depth,
          offset: Offset(0, 2 * depth),
        ),
      ],
    );
  }

  // ── Shimmer / reflection helper ────────────────────────────────────

  static Widget shimmerOverlay({double height = 200}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.transparent, Colors.white24, Colors.transparent],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment(-1.0, -1.0),
        end: Alignment(1.0, 1.0),
      ).createShader(bounds),
      child: Container(height: height, color: Colors.white),
    );
  }

  // ── Dark palette extras ─────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkForeground = Color(0xFFE8E8F0);
  static const Color darkCard = Color(0xFF1C2333);
  static const Color darkMuted = Color(0xFF2D2D3A);
  static const Color darkMutedForeground = Color(0xFF9E9EB0);
  static const Color darkBorder = Color(0xFF333344);
  static const Color darkGlassBg = Color(0xCC1C2333);
  static const Color darkGlassBorder = Color(0x33FFFFFF);

  // ── ThemeData ──────────────────────────────────────────────────────
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: primaryForeground,
      secondary: accent,
      onSecondary: accentForeground,
      error: destructive,
      onError: destructiveForeground,
      surface: card,
      onSurface: foreground,
      outline: border,
      outlineVariant: muted,
      surfaceContainerHighest: muted,
    );

    final interText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: interText.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 0),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: foreground, size: 20),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
        labelStyle: TextStyle(color: mutedForeground, fontSize: 14),
        hintStyle: TextStyle(color: mutedForeground, fontSize: 14),
        prefixIconColor: mutedForeground,
        isDense: true,
      ),

      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: mutedForeground,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        textStyle: GoogleFonts.inter(color: foreground, fontSize: 14),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: GoogleFonts.inter(color: primaryForeground, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: foreground),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 12, color: mutedForeground),
        dense: true,
        visualDensity: VisualDensity.comfortable,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: muted,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: mutedForeground, width: 1.5),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: primaryForeground,
      secondary: accent,
      onSecondary: accentForeground,
      error: destructive,
      onError: destructiveForeground,
      surface: darkCard,
      onSurface: darkForeground,
      outline: darkBorder,
      outlineVariant: darkMuted,
      surfaceContainerHighest: darkMuted,
    );

    final interText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: interText.apply(
        bodyColor: darkForeground,
        displayColor: darkForeground,
      ),
      dividerColor: darkBorder,
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 0),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: darkForeground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: darkForeground, size: 20),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkForeground,
          side: const BorderSide(color: darkBorder),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkMutedForeground, fontSize: 14),
        hintStyle: const TextStyle(color: darkMutedForeground, fontSize: 14),
        prefixIconColor: darkMutedForeground,
        isDense: true,
      ),

      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: darkMutedForeground,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: darkForeground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        textStyle: GoogleFonts.inter(color: darkForeground, fontSize: 14),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkForeground,
        contentTextStyle: GoogleFonts.inter(color: primaryForeground, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: darkForeground),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 12, color: darkMutedForeground),
        dense: true,
        visualDensity: VisualDensity.comfortable,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: darkMuted,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: primaryForeground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: darkMutedForeground, width: 1.5),
      ),
    );
  }
}
