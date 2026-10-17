import 'package:cloud_firestore/cloud_firestore.dart';

/// คำขอติดตามที่รอฉันอนุมัติ
class FollowRequest {
  final String followerId;
  final String followerName;
  final String? followerPhotoUrl;
  final DateTime createdAt;

  const FollowRequest({
    required this.followerId,
    required this.followerName,
    this.followerPhotoUrl,
    required this.createdAt,
  });

  factory FollowRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FollowRequest(
      followerId: data['followerId'] ?? '',
      followerName: data['followerName'] ?? 'ผู้ใช้',
      followerPhotoUrl: data['followerPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
