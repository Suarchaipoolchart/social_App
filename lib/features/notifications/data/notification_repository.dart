import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';
import 'notification_models.dart';

/// การแจ้งเตือนในแอป: เมธอดที่ "ส่ง" จะไม่ throw เพื่อไม่ให้การแจ้งเตือน
/// ทำให้การกระทำหลัก (โพสต์ ติดตาม ฯลฯ) ล้มเหลว
class NotificationRepository {
  NotificationRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid).collection('notifications');

  static String _cut(String s) => s.length > 80 ? '${s.substring(0, 80)}…' : s;

  Map<String, dynamic> _data({
    required String type,
    required AppUser actor,
    String? postId,
    String? groupId,
    String? groupName,
    String snippet = '',
    String extra = '',
  }) {
    return {
      'type': type,
      'actorId': actor.uid,
      'actorName': actor.displayName,
      'actorPhotoUrl': actor.photoUrl,
      'postId': postId,
      'groupId': groupId,
      'groupName': groupName,
      'snippet': _cut(snippet),
      'extra': extra,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // ---------- อ่าน ----------

  Stream<List<AppNotification>> watchMine(String uid, {int limit = 50}) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromDoc).toList());
  }

  Stream<int> watchUnreadCount(String uid) {
    return _items(uid)
        .where('read', isEqualTo: false)
        .limit(99)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markRead(String uid, String id) async {
    try {
      await _items(uid).doc(id).update({'read': true});
    } on FirebaseException {
      // ไม่สำคัญ ข้ามได้
    }
  }

  Future<void> markAllRead(String uid) async {
    try {
      final snap = await _items(
        uid,
      ).where('read', isEqualTo: false).limit(100).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    } on FirebaseException {
      // ไม่สำคัญ ข้ามได้
    }
  }

  // ---------- ส่ง ----------

  /// ส่งแจ้งเตือนให้คนเดียว ถ้าระบุ id จะไม่ซ้ำ (ส่งซ้ำจะถูกข้ามเงียบๆ)
  Future<void> send({
    required String toUid,
    required String type,
    required AppUser actor,
    String? id,
    String? postId,
    String? groupId,
    String? groupName,
    String snippet = '',
    String extra = '',
  }) async {
    if (toUid.isEmpty || toUid == actor.uid) return;
    try {
      final ref = id == null ? _items(toUid).doc() : _items(toUid).doc(id);
      await ref.set(
        _data(
          type: type,
          actor: actor,
          postId: postId,
          groupId: groupId,
          groupName: groupName,
          snippet: snippet,
          extra: extra,
        ),
      );
    } on FirebaseException {
      // เช่น รีแอคชันซ้ำที่มีแจ้งเตือนอยู่แล้ว ข้ามได้
    }
  }

  /// แจ้งผู้ติดตาม (ฟีดหลัก) หรือสมาชิกกลุ่ม/เพจ ว่ามีโพสต์ใหม่ (ไม่เกิน 300 คน)
  Future<void> notifyPost({
    required AppUser author,
    required String postId,
    required String text,
    String? groupId,
  }) async {
    try {
      final recipients = <String>{};
      String type = 'post';
      String? groupName;

      if (groupId == null) {
        final snap = await _db
            .collection(FirestorePaths.follows)
            .where('followeeId', isEqualTo: author.uid)
            .where('status', isEqualTo: 'accepted')
            .limit(300)
            .get();
        for (final d in snap.docs) {
          final id = d.data()['followerId'];
          if (id is String) recipients.add(id);
        }
      } else {
        final g = await _db
            .collection(FirestorePaths.groups)
            .doc(groupId)
            .get();
        final data = g.data();
        groupName = data?['name'] as String?;
        recipients.addAll(List<String>.from(data?['memberIds'] ?? const []));
        type = 'group_post';
      }

      recipients.remove(author.uid);
      if (recipients.isEmpty) return;

      final batch = _db.batch();
      for (final uid in recipients.take(300)) {
        batch.set(
          _items(uid).doc('post_$postId'),
          _data(
            type: type,
            actor: author,
            postId: postId,
            groupId: groupId,
            groupName: groupName,
            snippet: text,
          ),
        );
      }
      await batch.commit();
    } on FirebaseException {
      // ไม่ให้การแจ้งเตือนทำให้การโพสต์ล้มเหลว
    }
  }
}
