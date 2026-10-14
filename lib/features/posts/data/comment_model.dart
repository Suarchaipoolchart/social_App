import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Comment(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
