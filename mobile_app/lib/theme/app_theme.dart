import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static Brightness _brightness = Brightness.light;
  static Brightness get currentBrightness => _brightness;
  static void updateBrightness(Brightness b) { _brightness = b; }

  // ── Core palette ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF312E81);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  static Color get background => _brightness == Brightness.dark ? const Color(0xFF0B0E1A) : const Color(0xFFF8F9FE);
  static Color get foreground => _brightness == Brightness.dark ? const Color(0xFFE8ECF4) : const Color(0xFF0F1419);

  static Color get card => _brightness == Brightness.dark ? const Color(0xFF131827) : const Color(0xFFFFFFFF);
  static Color get cardForeground => _brightness == Brightness.dark ? const Color(0xFFE8ECF4) : const Color(0xFF0F1419);

  static Color get muted => _brightness == Brightness.dark ? const Color(0xFF1E2740) : const Color(0xFFF1F3F9);
  static Color get mutedForeground => _brightness == Brightness.dark ? const Color(0xFF8B93AB) : const Color(0xFF6B7280);

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentForeground = Color(0xFF1A1A2E);

  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFAFAFA);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static Color get border => _brightness == Brightness.dark ? const Color(0xFF2A3350) : const Color(0xFFE2E5F0);
  static Color get borderLight => _brightness == Brightness.dark ? const Color(0xFF1E2740) : const Color(0xFFF1F3F9);

  static Color get glassBg => _brightness == Brightness.dark ? const Color(0xCC131827) : const Color(0xF2FFFFFF);
  static const Color glassBorder = Color(0x28FFFFFF);
  static const Color glassShadow = Color(0x0A000000);

  // ── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF8F9FE), Color(0xFFEEF0F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> meshColors = [
    Color(0xFF4338CA),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF312E81),
  ];

  static const List<Color> premiumMeshColors = [
    Color(0xFF4338CA),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
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
          color: Colors.black.withValues(alpha: 0.08),
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

  // ── Premium depth cards ────────────────────────────────────────────

  static List<BoxShadow> depthShadows({double depth = 1.0}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06 * depth),
        blurRadius: 20 * depth,
        offset: Offset(0, 8 * depth),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03 * depth),
        blurRadius: 6 * depth,
        offset: Offset(0, 2 * depth),
      ),
      BoxShadow(
        color: primary.withValues(alpha: 0.02 * depth),
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
    final bg = color ?? (b == Brightness.dark ? darkCard : Colors.white);
    final bd = b == Brightness.dark ? darkBorder : border;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: bd, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06 * depth),
          blurRadius: 20 * depth,
          offset: Offset(0, 8 * depth),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03 * depth),
          blurRadius: 6 * depth,
          offset: Offset(0, 2 * depth),
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.03 * depth),
          blurRadius: 1 * depth,
          offset: Offset(0, -1 * depth),
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
  static const Color darkBackground = Color(0xFF0B0E1A);
  static const Color darkForeground = Color(0xFFE8ECF4);
  static const Color darkCard = Color(0xFF131827);
  static const Color darkMuted = Color(0xFF1E2740);
  static const Color darkMutedForeground = Color(0xFF8B93AB);
  static const Color darkBorder = Color(0xFF2A3350);
  static const Color darkGlassBg = Color(0xCC131827);
  static const Color darkGlassBorder = Color(0x28FFFFFF);

  // ── Status Colors ──────────────────────────────────────────────────
  static const Color pendingColor = Color(0xFFF59E0B);
  static const Color completedColor = Color(0xFF10B981);
  static const Color cancelledColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF6366F1);

  // ── ThemeData ──────────────────────────────────────────────────────
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: primaryForeground,
      primaryContainer: primaryLight,
      secondary: accent,
      onSecondary: accentForeground,
      secondaryContainer: accentLight,
      error: destructive,
      onError: destructiveForeground,
      surface: card,
      onSurface: foreground,
      outline: border,
      outlineVariant: borderLight,
      surfaceContainerHighest: muted,
      surfaceContainerHigh: muted,
      surfaceContainer: muted,
      surfaceContainerLow: const Color(0xFFF8F9FE),
      surfaceContainerLowest: Colors.white,
      surfaceTint: Colors.transparent,
      inverseSurface: darkBackground,
      onInverseSurface: darkForeground,
      inversePrimary: primaryLight,
      shadow: Colors.black,
      scrim: Colors.black,
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
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: foreground, size: 20),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
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
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: primary.withValues(alpha: 0.3),
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
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
        labelStyle: TextStyle(color: mutedForeground, fontSize: 13),
        hintStyle: TextStyle(color: mutedForeground, fontSize: 13),
        prefixIconColor: mutedForeground,
        suffixIconColor: mutedForeground,
        isDense: true,
      ),

      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          gradient: primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: mutedForeground,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        textStyle: GoogleFonts.inter(color: foreground, fontSize: 14),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: GoogleFonts.inter(color: primaryForeground, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        width: 340,
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
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: mutedForeground, width: 1.5),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: muted,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: foreground),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: primary);
          }
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: mutedForeground);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 20, color: primary);
          }
          return IconThemeData(size: 20, color: mutedForeground);
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.3);
          return muted.withValues(alpha: 0.5);
        }),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryLight,
      onPrimary: const Color(0xFF0F1419),
      primaryContainer: primary,
      secondary: accent,
      onSecondary: accentForeground,
      secondaryContainer: accentLight,
      error: destructive,
      onError: destructiveForeground,
      surface: darkCard,
      onSurface: darkForeground,
      outline: darkBorder,
      outlineVariant: darkMuted,
      surfaceContainerHighest: darkMuted,
      surfaceContainerHigh: darkMuted,
      surfaceContainer: darkMuted,
      surfaceContainerLow: darkCard,
      surfaceContainerLowest: darkBackground,
      surfaceTint: Colors.transparent,
      inverseSurface: const Color(0xFFF8F9FE),
      onInverseSurface: const Color(0xFF0F1419),
      inversePrimary: primary,
      shadow: Colors.black,
      scrim: Colors.black,
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
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: darkForeground, size: 20),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: const Color(0xFF0F1419),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: primaryLight.withValues(alpha: 0.3),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
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
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkMutedForeground, fontSize: 13),
        hintStyle: const TextStyle(color: darkMutedForeground, fontSize: 13),
        prefixIconColor: darkMutedForeground,
        suffixIconColor: darkMutedForeground,
        isDense: true,
      ),

      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: primaryLight.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: darkMutedForeground,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        textStyle: GoogleFonts.inter(color: darkForeground, fontSize: 14),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkForeground,
        contentTextStyle: GoogleFonts.inter(color: primaryForeground, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        width: 340,
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
        color: primaryLight,
        linearTrackColor: darkMuted,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: const Color(0xFF0F1419),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF0F1419)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: darkMutedForeground, width: 1.5),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkMuted,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: darkForeground),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return darkMutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight.withValues(alpha: 0.3);
          return darkMuted.withValues(alpha: 0.5);
        }),
      ),
    );
  }
}
