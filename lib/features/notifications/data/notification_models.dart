import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String
  type; // follow, follow_request, follow_accepted, reaction, comment, share, post, group_post
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final String? postId;
  final String? groupId;
  final String? groupName;
  final String snippet;
  final String extra; // ใช้เก็บชนิดรีแอคชัน
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    this.postId,
    this.groupId,
    this.groupName,
    this.snippet = '',
    this.extra = '',
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? 'ผู้ใช้',
      actorPhotoUrl: data['actorPhotoUrl'],
      postId: data['postId'],
      groupId: data['groupId'],
      groupName: data['groupName'],
      snippet: data['snippet'] ?? '',
      extra: data['extra'] ?? '',
      read: data['read'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
