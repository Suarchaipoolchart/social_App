import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String type; // 'group' | 'page'
  final String ownerId;
  final String ownerName;
  final int memberCount;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.memberCount,
    required this.memberIds,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPage => type == 'page';
  String get typeLabel => isPage ? 'เพจ' : 'กลุ่ม';
  String get memberLabel => isPage ? 'ผู้ติดตาม' : 'สมาชิก';
  String get joinLabel => isPage ? 'ติดตาม' : 'เข้าร่วม';
  String get leaveLabel => isPage ? 'เลิกติดตาม' : 'ออกจากกลุ่ม';

  bool isMember(String uid) => memberIds.contains(uid);
  bool isOwner(String uid) => ownerId == uid;

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'group',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class GroupMember {
  final String uid;
  final String displayName;
  final String? photoUrl;

  const GroupMember({
    required this.uid,
    required this.displayName,
    this.photoUrl,
  });

  factory GroupMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GroupMember(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }
}
