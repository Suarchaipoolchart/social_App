import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'video'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, int> reactionCounts;
  final int commentCount;
  final String? groupId; // null = โพสต์ในฟีดหลัก

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.updatedAt,
    this.reactionCounts = const {},
    this.commentCount = 0,
    this.groupId,
  });

  bool get edited => updatedAt != null;

  /// พาธเอกสาร: posts/{id} (ฟีดหลัก) หรือ groups/{groupId}/posts/{id} (ในกลุ่ม)
  static String? _groupIdFromPath(String path) {
    final segments = path.split('/');
    if (segments.length == 4 && segments[0] == 'groups') return segments[1];
    return null;
  }

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawCounts = (data['reactionCounts'] as Map?) ?? {};
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      text: data['text'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      reactionCounts: {
        for (final e in rawCounts.entries)
          e.key.toString(): (e.value as num).toInt(),
      },
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      groupId: _groupIdFromPath(doc.reference.path),
    );
  }
}
