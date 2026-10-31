import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? coverUrl; // รูปปกโปรไฟล์
  final String bio;
  final bool isPrivate;
  final bool isAdmin; // ตั้งจาก Firebase Console เท่านั้น
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.coverUrl,
    this.bio = '',
    this.isPrivate = false,
    this.isAdmin = false,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      coverUrl: map['coverUrl'],
      bio: map['bio'] ?? '',
      isPrivate: map['isPrivate'] ?? false,
      isAdmin: map['isAdmin'] == true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
