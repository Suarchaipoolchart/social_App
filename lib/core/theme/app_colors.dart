import 'package:flutter/material.dart';

class AppColors {
  // ใช้ร่วมกันทั้ง light / dark (โทนน้ำเงินกรมท่า)
  static const primary = Color(0xFF3B82F6); // blue
  static const accent = Color(0xFF22D3EE); // cyan
  static const error = Color(0xFFEF4444);

  // Light
  static const lightBackground = Color(0xFFF1F5FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF0F1B33);
  static const lightTextSecondary = Color(0xFF64748B);

  // Dark (กรมท่าเข้ม)
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF131C2E);
  static const darkText = Color(0xFFE6ECF5);
  static const darkTextSecondary = Color(0xFF8FA0B8);
}

/// สีหลักที่เลือกได้สำหรับโหมดมืด (เหมือนตัวเลือก "สีสำหรับโหมดมืด")
enum AccentPreset {
  defaultBlue('ค่าเริ่มต้น', Color(0xFF3B82F6)),
  blue('สีน้ำเงิน', Color(0xFF8FA8FF)),
  green('สีเขียว', Color(0xFF4ADE9E)),
  yellow('สีเหลือง', Color(0xFFFFC928)),
  pink('สีชมพู', Color(0xFFFF8FC7)),
  orange('สีส้ม', Color(0xFFFFA87A)),
  purple('สีม่วง', Color(0xFFC4A5FF)),
  mono('ขาว / ดำ', Color(0xFFFFFFFF));

  const AccentPreset(this.label, this.color);

  final String label;
  final Color color;
}
