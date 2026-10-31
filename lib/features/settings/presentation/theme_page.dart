import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// หน้า Theme / UI Design: สลับโหมดสว่าง/มืด ดูตัวอย่าง และพาเลตสี
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ThemeController>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Theme / UI Design')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('โหมดการแสดงผล', style: titleStyle),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('ตามระบบ')),
              ButtonSegment(value: ThemeMode.light, label: Text('สว่าง')),
              ButtonSegment(value: ThemeMode.dark, label: Text('มืด')),
            ],
            selected: {ctrl.mode},
            onSelectionChanged: (s) => ctrl.setMode(s.first),
          ),
          const SizedBox(height: 8),
          Text(
            'พาเลตนี้ไม่ใช้ขาว-ดำล้วนเหมือน wireframe: โทนหลักเป็นม่วงอินดิโก '
            'มีส้มโคราลเป็นสีเน้น โหมดมืดใช้กรมท่าเข้มแทนสีดำ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('ตัวอย่าง', style: titleStyle),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Preview(dark: false)),
              SizedBox(width: 12),
              Expanded(child: _Preview(dark: true)),
            ],
          ),
          const SizedBox(height: 24),
          Text('พาเลตสี', style: titleStyle),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(
                    theme,
                    const Text(''),
                    const Text(
                      'Light',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Dark',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _colorRow(
                    theme,
                    'สีหลัก',
                    AppColors.primary,
                    AppColors.primary,
                  ),
                  _colorRow(
                    theme,
                    'สีเน้น',
                    AppColors.accent,
                    AppColors.accent,
                  ),
                  _colorRow(
                    theme,
                    'พื้นหลัง',
                    AppColors.lightBackground,
                    AppColors.darkBackground,
                  ),
                  _colorRow(
                    theme,
                    'พื้นผิวการ์ด',
                    AppColors.lightSurface,
                    AppColors.darkSurface,
                  ),
                  _colorRow(
                    theme,
                    'ข้อความ',
                    AppColors.lightText,
                    AppColors.darkText,
                  ),
                  _colorRow(
                    theme,
                    'ข้อความรอง',
                    AppColors.lightTextSecondary,
                    AppColors.darkTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, Widget a, Widget b, Widget c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(flex: 3, child: a),
        Expanded(flex: 3, child: b),
        Expanded(flex: 3, child: c),
      ],
    ),
  );

  Widget _swatch(ThemeData theme, Color c) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(_hex(c), style: theme.textTheme.bodySmall),
    ],
  );

  Widget _colorRow(ThemeData theme, String name, Color light, Color dark) =>
      _row(theme, Text(name), _swatch(theme, light), _swatch(theme, dark));
}

/// ตัวอย่างหน้าตาแอปในโหมดสว่าง/มืด ใช้สีตายตัวจาก AppColors
/// (ไม่เปลี่ยนตามโหมดที่เปิดอยู่ จะได้เทียบสองโหมดข้างกันได้)
class _Preview extends StatelessWidget {
  const _Preview({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final text = dark ? AppColors.darkText : AppColors.lightText;
    final sub = dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Semantics(
      label: dark ? 'ตัวอย่างโหมดมืด' : 'ตัวอย่างโหมดสว่าง',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dark ? 'Dark mode' : 'Light mode'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sub.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social App',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              'OM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ohmxz',
                                  style: TextStyle(
                                    color: text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '2 minutes ago',
                                  style: TextStyle(color: sub, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'First post with the new theme.',
                        style: TextStyle(color: text, fontSize: 10),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: dark ? 0.25 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            '24',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('1', style: TextStyle(color: sub, fontSize: 10)),
                          const SizedBox(width: 10),
                          Text('6', style: TextStyle(color: sub, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Create post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
}
