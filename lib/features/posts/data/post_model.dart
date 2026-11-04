import 'package:cloud_firestore/cloud_firestore.dart';

/// สำเนาโพสต์ต้นฉบับที่ถูกแชร์ (ฝังอยู่ในโพสต์ของคนแชร์)
class SharedPost {
  final String postId;
  final String? groupId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final String? mediaUrl;
  final String? mediaType;

  const SharedPost({
    required this.postId,
    this.groupId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    this.mediaUrl,
    this.mediaType,
  });

  factory SharedPost.fromPost(Post p) => SharedPost(
    postId: p.id,
    groupId: p.groupId,
    authorId: p.authorId,
    authorName: p.authorName,
    authorPhotoUrl: p.authorPhotoUrl,
    text: p.text,
    mediaUrl: p.mediaUrl,
    mediaType: p.mediaType,
  );

  factory SharedPost.fromMap(Map<String, dynamic> m) => SharedPost(
    postId: m['postId'] ?? '',
    groupId: m['groupId'],
    authorId: m['authorId'] ?? '',
    authorName: m['authorName'] ?? '',
    authorPhotoUrl: m['authorPhotoUrl'],
    text: m['text'] ?? '',
    mediaUrl: m['mediaUrl'],
    mediaType: m['mediaType'],
  );

  Map<String, dynamic> toMap() => {
    'postId': postId,
    'groupId': groupId,
    'authorId': authorId,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'text': text,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
  };
}

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
  final int shareCount;
  final SharedPost? shared; // มีค่า = โพสต์นี้เป็นการแชร์โพสต์ของคนอื่น
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
    this.shareCount = 0,
    this.shared,
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
    final rawShared = data['shared'];
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
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
      shared: rawShared is Map
          ? SharedPost.fromMap(Map<String, dynamic>.from(rawShared))
          : null,
      groupId: _groupIdFromPath(doc.reference.path),
    );
  }
}
