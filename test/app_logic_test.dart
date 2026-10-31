import 'package:flutter_test/flutter_test.dart';
import 'package:social_app/features/chat/data/chat_repository.dart';
import 'package:social_app/features/posts/data/post_repository.dart';

void main() {
  group('PostRepository.extractTags', () {
    test('ดึงแฮชแท็ก เป็นตัวพิมพ์เล็ก และไม่ซ้ำ', () {
      expect(PostRepository.extractTags('Hello #Flutter #flutter #Dart_3'), [
        'flutter',
        'dart_3',
      ]);
    });

    test('จำกัดไม่เกิน 10 แท็ก', () {
      final text = List.generate(15, (i) => '#t$i').join(' ');
      expect(PostRepository.extractTags(text).length, 10);
    });

    test('ไม่มีแท็ก = รายการว่าง', () {
      expect(PostRepository.extractTags('ไม่มีแท็ก'), isEmpty);
    });
  });

  group('ChatRepository.chatIdFor', () {
    test('ได้ห้องเดียวกันไม่ว่าใครเริ่มก่อน', () {
      expect(
        ChatRepository.chatIdFor('b', 'a'),
        ChatRepository.chatIdFor('a', 'b'),
      );
      expect(ChatRepository.chatIdFor('b', 'a'), 'a_b');
    });
  });
}
