import 'package:flutter/material.dart';

/// ไอคอนที่มีตัวเลขแจ้งเตือนซ้อนมุม แสดงเฉพาะเมื่อจำนวน > 0
class StreamBadgeIcon extends StatefulWidget {
  const StreamBadgeIcon({super.key, required this.stream, required this.icon});

  final Stream<int> stream;
  final Widget icon;

  @override
  State<StreamBadgeIcon> createState() => _StreamBadgeIconState();
}

class _StreamBadgeIconState extends State<StreamBadgeIcon> {
  // เก็บสตรีมครั้งแรกไว้ ไม่ให้สมัครรับใหม่ทุกครั้งที่หน้าแม่รีบิลด์
  late final Stream<int> _stream = widget.stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stream,
      initialData: 0,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        return Semantics(
          label: n > 0 ? 'มี $n รายการใหม่' : null,
          child: Badge(
            isLabelVisible: n > 0,
            label: Text('$n'),
            child: widget.icon,
          ),
        );
      },
    );
  }
}
