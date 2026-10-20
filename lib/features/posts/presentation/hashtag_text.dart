import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// ข้อความที่ไฮไลต์ #แท็ก และแตะเพื่อค้นหาได้
class HashtagText extends StatefulWidget {
  const HashtagText({super.key, required this.text, this.style, this.onTagTap});

  final String text;
  final TextStyle? style;
  final void Function(String tag)? onTagTap;

  @override
  State<HashtagText> createState() => _HashtagTextState();
}

class _HashtagTextState extends State<HashtagText> {
  static final _pattern = RegExp(r'#([\p{L}\p{M}\p{N}_]+)', unicode: true);
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final color = Theme.of(context).colorScheme.primary;
    final text = widget.text;
    final spans = <InlineSpan>[];
    var last = 0;

    for (final m in _pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      TapGestureRecognizer? recognizer;
      if (widget.onTagTap != null) {
        final tag = m.group(1)!.toLowerCase();
        recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onTagTap!(tag);
        _recognizers.add(recognizer);
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
          recognizer: recognizer,
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
