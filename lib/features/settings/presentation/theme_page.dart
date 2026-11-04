import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// หน้า Theme / UI Design: สลับโหมดสว่าง/มืด และเลือกสีสำหรับโหมดมืด
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

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
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.primary,
              selectedForegroundColor: theme.colorScheme.onPrimary,
            ),
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('ตามระบบ')),
              ButtonSegment(value: ThemeMode.light, label: Text('สว่าง')),
              ButtonSegment(value: ThemeMode.dark, label: Text('มืด')),
            ],
            selected: {ctrl.mode},
            onSelectionChanged: (s) => ctrl.setMode(s.first),
          ),
          const SizedBox(height: 20),
          Text('สีสำหรับโหมดมืด', style: titleStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField<AccentPreset>(
            key: ValueKey(
              ctrl.accent,
            ), // สร้างใหม่เมื่อค่าเปลี่ยน (เช่นกดคืนค่าเริ่มต้น)
            initialValue: ctrl.accent,
            decoration: const InputDecoration(),
            items: [
              for (final a in AccentPreset.values)
                DropdownMenuItem(
                  value: a,
                  child: Row(
                    children: [
                      CircleAvatar(radius: 9, backgroundColor: a.color),
                      const SizedBox(width: 12),
                      Text(a.label),
                    ],
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) ctrl.setAccent(v);
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: ctrl.resetDefaults,
              icon: const Icon(Icons.restart_alt),
              label: const Text('คืนค่าเริ่มต้น'),
            ),
          ),
          Text(
            'โหมดมืดใช้กรมท่าเข้มแทนสีดำ และเปลี่ยนสีหลักได้ตามที่เลือก',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
