import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String bio;
  final bool isPrivate;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.bio = '',
    this.isPrivate = false,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      bio: map['bio'] ?? '',
      isPrivate: map['isPrivate'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
