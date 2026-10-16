import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_motion.dart';

/// AppTheme – Carbon Pro (VALEX Pro Design System)
/// Tipografia: Poppins (corpo) + Bebas Neue (KPIs/labels)
class AppTheme {
  AppTheme._();

  static TextStyle _poppins({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Poppins',
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );

  // ── Aliases públicos de cor para acesso direto nas views ──────────────────
  static const primaryColor = AppColors.blue;
  static const secondaryColor = AppColors.gold;
  static const backgroundColor = AppColors.carbon;
  static const surfaceColor = AppColors.carbon2;
  static const cardColor = AppColors.carbon2;

  // ── Text styles tipográficos nomeados (Poppins + Bebas Neue) ───────
  static TextStyle displayLg({Color color = Colors.white}) => _poppins(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.96,
    height: 56 / 48,
    color: color,
  );

  static TextStyle headlineLg({Color color = Colors.white}) => _poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    color: color,
  );

  static TextStyle headlineMd({Color color = Colors.white}) => _poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: color,
  );

  static TextStyle headlineSm({Color color = Colors.white}) => _poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: color,
  );

  static TextStyle headingSm({Color color = Colors.white}) =>
      headlineSm(color: color);
  static TextStyle headingLg({Color color = Colors.white}) =>
      headlineLg(color: color);

  static TextStyle bodyLg({Color color = Colors.white}) => _poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    color: color,
  );

  static TextStyle bodyMd({Color color = AppColors.steel}) => _poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: color,
  );

  static TextStyle bodySm({Color color = AppColors.steel}) => _poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: color,
  );

  static TextStyle inputText({Color color = Colors.white}) => _poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: color,
  );

  // Bebas Neue — KPIs / scorecard numérico
  static TextStyle kpiXl({Color color = AppColors.blue}) => const TextStyle(
    fontFamily: 'BebasNeue',
    fontSize: 40,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.6,
    color: AppColors.blue,
  ).copyWith(color: color);

  static TextStyle kpiMd({Color color = AppColors.blue}) => const TextStyle(
    fontFamily: 'BebasNeue',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.48,
    color: AppColors.blue,
  ).copyWith(color: color);

  // Rótulos de interface usam a mesma família do corpo; Bebas fica nos KPIs.
  static TextStyle labelCaps({Color color = AppColors.steel}) => _poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: color,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.carbon,
      primaryColor: AppColors.blue,
      canvasColor: AppColors.carbon,
      hoverColor: AppColors.blue.withValues(alpha: 0.07),
      focusColor: AppColors.blue.withValues(alpha: 0.18),
      splashColor: AppColors.blue.withValues(alpha: 0.12),
      highlightColor: AppColors.blue.withValues(alpha: 0.08),
      dividerColor: AppColors.dividerColor,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),

      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.blue,
        onPrimary: AppColors.carbon1,
        primaryContainer: AppColors.blueLight,
        onPrimaryContainer: AppColors.carbon1,
        secondary: AppColors.gold,
        onSecondary: AppColors.carbon1,
        secondaryContainer: AppColors.goldLight,
        onSecondaryContainer: AppColors.carbon1,
        surface: AppColors.carbon,
        onSurface: Colors.white,
        surfaceContainerLow: AppColors.carbon1,
        surfaceContainer: AppColors.carbon2,
        surfaceContainerHigh: AppColors.carbon3,
        onSurfaceVariant: AppColors.steel,
        outline: AppColors.steelDim,
        outlineVariant: AppColors.carbon3,
        error: AppColors.crimson,
        onError: AppColors.carbon1,
      ),

      textTheme: base.textTheme
          .apply(fontFamily: 'Poppins')
          .copyWith(
            displayLarge: _poppins(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.96,
            ),
            headlineLarge: _poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            headlineMedium: _poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            titleLarge: _poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            titleMedium: _poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: _poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            bodyMedium: _poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.steel,
            ),
            bodySmall: _poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.steelDim,
            ),
            labelLarge: _poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            labelMedium: _poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.steel,
            ),
          ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.carbon2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: const BorderSide(
            color: Color(0xFF2A3447),
            width: 1,
          ), // Borda nítida e visível
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.carbon1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Botões ────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueAction,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.carbon3,
              disabledForegroundColor: AppColors.steelDim,
              elevation: 0,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusBtn),
              ),
              textStyle: _poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? Colors.white.withValues(alpha: 0.15)
                    : states.contains(WidgetState.hovered)
                    ? Colors.white.withValues(alpha: 0.08)
                    : null,
              ),
            ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blueAction,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.carbon3,
          disabledForegroundColor: AppColors.steelDim,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusBtn),
          ),
          textStyle: _poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blueLight,
          side: const BorderSide(color: AppColors.dividerColor),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusBtn),
          ),
          textStyle: _poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blueLight,
          minimumSize: const Size(0, 44),
          textStyle: _poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.carbon2,
        hintStyle: _poppins(fontSize: 14, color: AppColors.steelDim),
        labelStyle: _poppins(fontSize: 14, color: AppColors.steel),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(color: Color(0xFF2E384D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(color: Color(0xFF2E384D)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(color: AppColors.blue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(color: AppColors.crimson),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          borderSide: const BorderSide(color: AppColors.crimson, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.steelLight,
          minimumSize: const Size(44, 44),
          highlightColor: AppColors.blue.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.blueLight,
        selectionColor: AppColors.blue.withValues(alpha: 0.36),
        selectionHandleColor: AppColors.blueLight,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.carbon3,
          borderRadius: BorderRadius.circular(AppColors.radiusXs),
          border: Border.all(color: AppColors.dividerColor),
        ),
        textStyle: _poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        waitDuration: const Duration(milliseconds: 450),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        trackVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.steelDim
              : AppColors.carbon3,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blueLight,
        linearTrackColor: AppColors.carbon3,
        circularTrackColor: AppColors.carbon3,
      ),

      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.blueLight,
        collapsedIconColor: AppColors.steelDim,
        textColor: Colors.white,
        collapsedTextColor: Colors.white,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: Border(),
        collapsedShape: Border(),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.steelLight,
        unselectedLabelColor: AppColors.steelDim,
        labelStyle: _poppins(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: _poppins(fontSize: 13),
        indicatorColor: AppColors.blueLight,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.dividerColor,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.blue.withValues(alpha: 0.24)
                : AppColors.carbon2,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.steel,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? AppColors.blue
                  : AppColors.dividerColor,
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            _poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),

      // ── NavigationBar (mobile bottom) ────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.carbon1,
        indicatorColor: AppColors.blue.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.blue);
          }
          return const IconThemeData(color: AppColors.steelDim);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.blue,
            );
          }
          return _poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.steelDim,
          );
        }),
      ),

      // ── NavigationRail (desktop side) ─────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.carbon1,
        indicatorColor: AppColors.blue.withValues(alpha: 0.18),
        selectedIconTheme: const IconThemeData(color: AppColors.blueLight),
        unselectedIconTheme: const IconThemeData(color: AppColors.steelDim),
        selectedLabelTextStyle: _poppins(
          color: AppColors.steelLight,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: _poppins(
          color: AppColors.steelDim,
          fontSize: 12,
        ),
      ),

      // ── BottomNavigationBar legado ────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.carbon1,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.steelDim,
        selectedLabelStyle: _poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: _poppins(fontSize: 11),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Divisores ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFF283548),
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.steelLight,
        titleTextStyle: _poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        subtitleTextStyle: _poppins(fontSize: 12, color: AppColors.steel),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusXs),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.carbon3,
        labelStyle: _poppins(fontSize: 12, color: Colors.white),
        side: const BorderSide(color: Color(0xFF2E384D)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusXs),
        ),
      ),

      // ── Dialog / BottomSheet ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: const BorderSide(color: AppColors.dividerColor),
        ),
        titleTextStyle: _poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.steelDim,
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.blueAction,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusBtn),
        ),
      ),

      // ── Switch / Checkbox ─────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.white : AppColors.steel,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.carbon3,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.blue
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.steel, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.carbon3,
        contentTextStyle: _poppins(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusXs),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
