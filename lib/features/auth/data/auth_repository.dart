import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import 'app_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> watchUser(String uid) {
    return _db.doc(FirestorePaths.user(uid)).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : AppUser.fromMap(uid, data);
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(displayName);
      await _db.doc(FirestorePaths.user(user.uid)).set({
        'displayName': displayName,
        'displayNameLower': displayName
            .toLowerCase(), // เผื่อใช้ค้นหาผู้ใช้ (ข้อ 7)
        'email': email,
        'photoUrl': null,
        'bio': '',
        'isPrivate': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  Future<void> updateProfile(
    String uid, {
    required String displayName,
    required String bio,
    required bool isPrivate,
    String? photoUrl,
  }) async {
    try {
      await _db.doc(FirestorePaths.user(uid)).update({
        'displayName': displayName,
        'displayNameLower': displayName.toLowerCase(),
        'bio': bio,
        'isPrivate': isPrivate,
        'photoUrl': ?photoUrl,
      });
      await _auth.currentUser?.updateDisplayName(displayName);
      if (photoUrl != null) {
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }
    } on FirebaseException {
      throw AuthException('บันทึกโปรไฟล์ไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  String _message(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป (อย่างน้อย 6 ตัว)';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'too-many-requests':
        return 'ลองบ่อยเกินไป กรุณารอสักครู่';
      case 'network-request-failed':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
