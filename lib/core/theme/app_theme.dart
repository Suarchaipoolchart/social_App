import 'package:flutter/material.dart';
import 'app_colors.dart';

/// เก็บ ThemeData ของแอปสำหรับโหมดสว่างและมืด
class AppTheme {
  static final ThemeData light = _build(
    brightness: Brightness.light,
    background: const Color.fromARGB(255, 242, 246, 240),
    surface: AppColors.lightSurface,
    text: AppColors.lightText,
    textSecondary: AppColors.lightTextSecondary,
  );

  /// โหมดสว่างพร้อมสีหลักที่ผู้ใช้เลือก
  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    background: const Color.fromARGB(255, 251, 252, 251),
    surface: AppColors.darkSurface,
    text: const Color.fromARGB(255, 245, 245, 245),
    textSecondary: AppColors.darkTextSecondary,
  );

  /// โหมดมืดพร้อมสีหลักที่ผู้ใช้เลือก
  static ThemeData darkWith(Color primary) => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    text: AppColors.darkText,
    textSecondary: AppColors.darkTextSecondary,
    primary: primary,
  );

  /// โหมดสว่างพร้อมสีหลักที่ผู้ใช้เลือก
  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color textSecondary,
    Color primary = AppColors.primary,
  }) {
    // สีข้อความบนสีหลัก (primary) ขึ้นอยู่กับความสว่างของสีหลัก
    final onPrimary =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? const Color.fromARGB(255, 30, 178, 4)
        : const Color(0xFF0B1220);
    // สร้าง ColorScheme สำหรับ ThemeData
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.accent,
      onSecondary: const Color(0xFF0B1220),
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textSecondary,
    );

    final radius = BorderRadius.circular(14);
    final borderColor = textSecondary.withValues(alpha: 0.35);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: textSecondary.withValues(alpha: 0.18)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: textSecondary.withValues(alpha: 0.18),
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.2),
        side: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
        labelStyle: TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        dividerColor: textSecondary.withValues(alpha: 0.18),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}
