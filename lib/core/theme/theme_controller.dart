import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// เก็บโหมดสว่าง/มืด/ตามระบบ และจำค่าไว้ในเครื่อง
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// เรียกครั้งเดียวก่อนเปิดแอป เพื่อไม่ให้ธีมกะพริบตอนเริ่ม
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } catch (_) {
      // อ่านค่าที่บันทึกไว้ไม่ได้ ใช้ค่าเริ่มต้น (ตามระบบ)
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners(); // เปลี่ยนทันที ไม่รอบันทึก
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // บันทึกไม่สำเร็จ ธีมยังเปลี่ยนในรอบนี้ แต่จะไม่ถูกจำ
    }
  }
}
