import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';
import 'story_models.dart';

class StoryException implements Exception {
  final String message;
  StoryException(this.message);
}

/// สตอรี่อยู่ 24 ชั่วโมง (คอลเลกชัน stories) ส่วนคนที่มาดู/อิโมจิเก็บใน
/// stories/{id}/views/{uid} เพื่อให้ผู้ชมเขียนได้แค่เอกสารของตัวเอง
class StoryRepository {
  StoryRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const ttl = Duration(hours: 24);
  static const _views = 'views';

  final FirebaseFirestore _db;

  /// สตอรี่ที่เปิดดูแล้วในรอบการใช้งานนี้ (ใช้เปลี่ยนสีวงแหวน)
  final Set<String> _seen = {};
  bool isSeen(String storyId) => _seen.contains(storyId);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.stories);

  // ---------- อ่าน (เรียลไทม์) ----------

  /// สตอรี่ที่ยังไม่หมดอายุ อัปเดตทันทีเมื่อมีคนโพสต์/ลบ
  Stream<List<Story>> watchActive() {
    return _col
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .snapshots()
        .map((snap) => snap.docs.map(Story.fromDoc).toList());
  }

  /// จัดกลุ่มตามเจ้าของ: ของฉันมาก่อน ที่เหลือเรียงตามสตอรี่ล่าสุด
  static List<UserStories> group(List<Story> all, String myUid) {
    final now = DateTime.now();
    final byAuthor = <String, List<Story>>{};
    for (final s in all) {
      if (!s.expiresAt.isAfter(now)) continue;
      byAuthor.putIfAbsent(s.authorId, () => []).add(s);
    }
    final groups = <UserStories>[];
    for (final e in byAuthor.entries) {
      final list = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      groups.add(
        UserStories(
          authorId: e.key,
          authorName: list.last.authorName,
          authorPhotoUrl: list.last.authorPhotoUrl,
          stories: list,
        ),
      );
    }
    groups.sort((a, b) {
      if (a.authorId == myUid) return -1;
      if (b.authorId == myUid) return 1;
      return b.stories.last.createdAt.compareTo(a.stories.last.createdAt);
    });
    return groups;
  }

  /// รายชื่อคนที่เข้ามาดู (ใช้เฉพาะเจ้าของสตอรี่) ใหม่สุดก่อน
  Stream<List<StoryViewer>> watchViewers(String storyId) {
    return _col.doc(storyId).collection(_views).limit(200).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map(StoryViewer.fromDoc).toList();
      list.sort((a, b) {
        final ta = a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  Future<String?> getMyReaction(String storyId, String uid) async {
    try {
      final snap = await _col.doc(storyId).collection(_views).doc(uid).get();
      return snap.data()?['reaction'] as String?;
    } on FirebaseException {
      return null;
    }
  }

  // ---------- เขียน ----------

  Future<void> createStory(
    AppUser me, {
    required String mediaUrl,
    required String mediaType,
    String caption = '',
  }) async {
    try {
      await _col.add({
        'authorId': me.uid,
        'authorName': me.displayName,
        'authorPhotoUrl': me.photoUrl,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(ttl)),
      });
    } on FirebaseException catch (e) {
      throw StoryException(_message(e.code));
    }
  }

  Future<void> deleteStory(String storyId) async {
    final ref = _col.doc(storyId);
    try {
      final views = await ref.collection(_views).limit(400).get();
      final batch = _db.batch();
      for (final d in views.docs) {
        batch.delete(d.reference);
      }
      batch.delete(ref);
      await batch.commit();
    } on FirebaseException catch (e) {
      throw StoryException(_message(e.code));
    }
  }

  /// บันทึกว่าฉันดูแล้ว (ครั้งแรกครั้งเดียว) ไม่นับการดูสตอรี่ของตัวเอง
  Future<void> markViewed(Story story, AppUser me) async {
    _seen.add(story.id);
    if (story.authorId == me.uid) return;
    try {
      final ref = _col.doc(story.id).collection(_views).doc(me.uid);
      final snap = await ref.get();
      if (snap.exists) return;
      await ref.set({
        'displayName': me.displayName,
        'photoUrl': me.photoUrl,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // บันทึกการดูไม่สำเร็จ ไม่ควรขัดการดูสตอรี่
    }
  }

  /// กดอิโมจิ (emoji = null คือยกเลิก) เฉพาะสตอรี่ของคนอื่น
  Future<void> setReaction(Story story, AppUser me, String? emoji) async {
    if (story.authorId == me.uid) return;
    try {
      await _col.doc(story.id).collection(_views).doc(me.uid).set({
        'displayName': me.displayName,
        'photoUrl': me.photoUrl,
        'reaction': emoji ?? FieldValue.delete(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw StoryException(_message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้ (ตรวจสอบ Security Rules ของ stories)';
      case 'unavailable':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
