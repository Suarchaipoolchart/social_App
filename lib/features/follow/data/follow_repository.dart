import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';
import 'follow_models.dart';

class FollowException implements Exception {
  final String message;
  FollowException(this.message);
}

class FollowRepository {
  FollowRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.follows);

  static String idFor(String followerId, String followeeId) =>
      '${followerId}_$followeeId';

  /// สถานะที่ฉันมีต่อคนนี้: null = ยังไม่ได้ติดตาม / 'pending' / 'accepted'
  Stream<String?> watchRelation(String myUid, String targetUid) {
    return _col
        .where('followerId', isEqualTo: myUid)
        .where('followeeId', isEqualTo: targetUid)
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : snap.docs.first.data()['status'] as String?,
        );
  }

  /// ติดตาม: บัญชีสาธารณะ = accepted ทันที / บัญชีส่วนตัว = pending รออนุมัติ
  Future<void> follow(AppUser me, AppUser target) async {
    if (me.uid == target.uid) return;
    try {
      await _col.doc(idFor(me.uid, target.uid)).set({
        'followerId': me.uid,
        'followeeId': target.uid,
        'status': target.isPrivate ? 'pending' : 'accepted',
        'followerName': me.displayName,
        'followerPhotoUrl': me.photoUrl,
        'followeeName': target.displayName,
        'followeePhotoUrl': target.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FollowException(_message(e.code));
    }
  }

  /// เลิกติดตาม หรือยกเลิกคำขอที่ส่งไป
  Future<void> unfollow(String myUid, String targetUid) async {
    try {
      await _col.doc(idFor(myUid, targetUid)).delete();
    } on FirebaseException catch (e) {
      throw FollowException(_message(e.code));
    }
  }

  Future<int> countFollowers(String uid) async {
    try {
      final snap = await _col
          .where('followeeId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();
      return snap.count ?? 0;
    } on FirebaseException catch (e) {
      throw FollowException(_message(e.code));
    }
  }

  Future<int> countFollowing(String uid) async {
    try {
      final snap = await _col
          .where('followerId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .count()
          .get();
      return snap.count ?? 0;
    } on FirebaseException catch (e) {
      throw FollowException(_message(e.code));
    }
  }

  // ---------- คำขอติดตามที่ส่งมาหาฉัน ----------

  Stream<List<FollowRequest>> watchRequests(String myUid) {
    return _col
        .where('followeeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(FollowRequest.fromDoc).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> approve(String followerId, String myUid) async {
    try {
      await _col.doc(idFor(followerId, myUid)).update({'status': 'accepted'});
    } on FirebaseException catch (e) {
      throw FollowException(_message(e.code));
    }
  }

  Future<void> reject(String followerId, String myUid) async {
    try {
      await _col.doc(idFor(followerId, myUid)).delete();
    } on FirebaseException catch (e) {
      throw FollowException(_message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้ (ตรวจสอบ Security Rules)';
      case 'unavailable':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      case 'not-found':
        return 'ไม่พบคำขอนี้ (อาจถูกยกเลิกไปแล้ว)';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
