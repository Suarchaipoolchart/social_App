import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';
import 'group_models.dart';

class GroupException implements Exception {
  final String message;
  GroupException(this.message);
}

class GroupRepository {
  GroupRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const _members = 'members';

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.groups);

  // ---------- อ่าน ----------

  /// กลุ่มที่ฉันเป็นสมาชิก (เรียงฝั่งแอป ไม่ต้องใช้ index)
  Stream<List<Group>> watchMyGroups(String uid) {
    return _col.where('memberIds', arrayContains: uid).snapshots().map((snap) {
      final list = snap.docs.map(Group.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// กลุ่มทั้งหมดล่าสุด สำหรับหน้าสำรวจ
  Stream<List<Group>> watchDiscover({int limit = 50}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Group.fromDoc).toList());
  }

  Stream<Group?> watchGroup(String groupId) {
    return _col
        .doc(groupId)
        .snapshots()
        .map((snap) => snap.exists ? Group.fromDoc(snap) : null);
  }

  Stream<List<GroupMember>> watchMembers(String groupId, {int limit = 100}) {
    return _col
        .doc(groupId)
        .collection(_members)
        .orderBy('joinedAt')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(GroupMember.fromDoc).toList());
  }

  // ---------- สร้าง / แก้ไข / ลบ ----------

  Future<void> createGroup(
    AppUser me, {
    required String name,
    required String description,
    required String type,
  }) async {
    final ref = _col.doc();
    try {
      final batch = _db.batch();
      batch.set(ref, {
        'name': name,
        'nameLower': name.toLowerCase(),
        'description': description,
        'type': type,
        'ownerId': me.uid,
        'ownerName': me.displayName,
        'memberCount': 1,
        'memberIds': [me.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
      batch.set(ref.collection(_members).doc(me.uid), {
        'displayName': me.displayName,
        'photoUrl': me.photoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw GroupException(_message(e.code));
    }
  }

  Future<void> updateGroup(
    String groupId, {
    required String name,
    required String description,
  }) async {
    try {
      await _col.doc(groupId).update({
        'name': name,
        'nameLower': name.toLowerCase(),
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw GroupException(_message(e.code));
    }
  }

  /// ลบกลุ่มพร้อมรายชื่อสมาชิก (รองรับสมาชิกไม่เกิน 400 คน)
  Future<void> deleteGroup(String groupId) async {
    final ref = _col.doc(groupId);
    try {
      final members = await ref.collection(_members).limit(400).get();
      final batch = _db.batch();
      for (final d in members.docs) {
        batch.delete(d.reference);
      }
      batch.delete(ref);
      await batch.commit();
    } on FirebaseException catch (e) {
      throw GroupException(_message(e.code));
    }
  }

  // ---------- เข้าร่วม / ออก ----------

  Future<void> join(String groupId, AppUser me) async {
    final ref = _col.doc(groupId);
    final memberRef = ref.collection(_members).doc(me.uid);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(memberRef);
        if (snap.exists) return; // เป็นสมาชิกอยู่แล้ว กันนับซ้ำ
        tx.set(memberRef, {
          'displayName': me.displayName,
          'photoUrl': me.photoUrl,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        tx.update(ref, {
          'memberCount': FieldValue.increment(1),
          'memberIds': FieldValue.arrayUnion([me.uid]),
        });
      });
    } on FirebaseException catch (e) {
      throw GroupException(_message(e.code));
    }
  }

  Future<void> leave(String groupId, String uid) async {
    final ref = _col.doc(groupId);
    final memberRef = ref.collection(_members).doc(uid);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(memberRef);
        if (!snap.exists) return;
        tx.delete(memberRef);
        tx.update(ref, {
          'memberCount': FieldValue.increment(-1),
          'memberIds': FieldValue.arrayRemove([uid]),
        });
      });
    } on FirebaseException catch (e) {
      throw GroupException(_message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้ (ตรวจสอบ Security Rules)';
      case 'unavailable':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      case 'not-found':
        return 'ไม่พบกลุ่มนี้ (อาจถูกลบไปแล้ว)';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
