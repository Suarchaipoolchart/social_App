import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/app_user.dart';
import '../../posts/data/post_model.dart';
import '../data/report_models.dart';
import '../data/report_repository.dart';

/// เปิดกล่องเลือกเหตุผลและส่งรายงานโพสต์
Future<void> showReportDialog(
  BuildContext context, {
  required Post post,
  required AppUser reporter,
}) async {
  final repo = context.read<ReportRepository>();
  final messenger = ScaffoldMessenger.of(context);

  final input = await showDialog<_ReportInput>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
  if (input == null) return;

  try {
    await repo.report(
      reporter: reporter,
      post: post,
      reason: input.reason,
      detail: input.detail,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('ส่งรายงานแล้ว ขอบคุณที่ช่วยดูแลชุมชน')),
    );
  } on ReportException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _ReportInput {
  final String reason;
  final String detail;
  const _ReportInput(this.reason, this.detail);
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _detail = TextEditingController();
  String _reason = 'inappropriate';

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('รายงานโพสต์'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เหตุผลที่รายงาน'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final e in kReportReasons.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _reason == e.key,
                    onSelected: (_) => setState(() => _reason = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detail,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _ReportInput(_reason, _detail.text.trim()),
          ),
          child: const Text('ส่งรายงาน'),
        ),
      ],
    );
  }
}
