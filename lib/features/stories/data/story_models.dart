import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final String mediaType; // 'image' | 'video'
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption = '',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isVideo => mediaType == 'video';

  factory Story.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final now = DateTime.now();
    return Story(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? 'ผู้ใช้',
      authorPhotoUrl: d['authorPhotoUrl'],
      mediaUrl: d['mediaUrl'] ?? '',
      mediaType: d['mediaType'] ?? 'image',
      caption: d['caption'] ?? '',
      // serverTimestamp ที่ยังไม่ถึงเซิร์ฟเวอร์จะเป็น null ชั่วคราว
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? now,
      expiresAt:
          (d['expiresAt'] as Timestamp?)?.toDate() ??
          now.add(const Duration(hours: 24)),
    );
  }
}

/// คนที่เข้ามาดูสตอรี่ (และอิโมจิที่กดไว้ ถ้ามี)
class StoryViewer {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final DateTime? viewedAt;
  final String? reaction;

  const StoryViewer({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.viewedAt,
    this.reaction,
  });

  factory StoryViewer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return StoryViewer(
      uid: doc.id,
      displayName: d['displayName'] ?? 'ผู้ใช้',
      photoUrl: d['photoUrl'],
      viewedAt: (d['viewedAt'] as Timestamp?)?.toDate(),
      reaction: d['reaction'] as String?,
    );
  }
}

/// สตอรี่ทั้งหมดของผู้ใช้หนึ่งคน เรียงเก่า -> ใหม่
class UserStories {
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final List<Story> stories;

  const UserStories({
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.stories,
  });
}
