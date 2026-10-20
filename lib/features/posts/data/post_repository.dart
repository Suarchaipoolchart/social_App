import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';
import 'comment_model.dart';
import 'post_model.dart';

class PostException implements Exception {
  final String message;
  PostException(this.message);
}

class PostPage {
  final List<Post> posts;
  final DocumentSnapshot<Map<String, dynamic>>? last;
  final bool hasMore;

  const PostPage({
    required this.posts,
    required this.last,
    required this.hasMore,
  });
}

class PostRepository {
  PostRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  static const _reactions = 'reactions';

  final FirebaseFirestore _db;

  static final _tagPattern = RegExp(r'#([\p{L}\p{M}\p{N}_]+)', unicode: true);

  /// ดึงแฮชแท็กจากข้อความ (ตัวพิมพ์เล็ก ไม่ซ้ำ ไม่เกิน 10 แท็ก)
  static List<String> extractTags(String text) {
    final tags = <String>{};
    for (final m in _tagPattern.allMatches(text)) {
      final tag = m.group(1)!.toLowerCase();
      if (tag.length <= 50) tags.add(tag);
      if (tags.length >= 10) break;
    }
    return tags.toList();
  }

  /// groupId == null = ฟีดหลัก (posts) / มีค่า = โพสต์ในกลุ่ม (groups/{id}/posts)
  CollectionReference<Map<String, dynamic>> _posts([String? groupId]) {
    if (groupId == null) return _db.collection(FirestorePaths.posts);
    return _db
        .collection(FirestorePaths.groups)
        .doc(groupId)
        .collection(FirestorePaths.posts);
  }

  // ---------- ฟีด ----------

  Stream<List<Post>> watchFeed({int limit = 50}) {
    return _posts()
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Post.fromDoc).toList());
  }

  /// โหลดฟีดทีละหน้า เรียงใหม่สุดก่อน
  Future<PostPage> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = 10,
    String? groupId,
  }) async {
    try {
      var query = _posts(
        groupId,
      ).orderBy('createdAt', descending: true).limit(limit);
      if (after != null) query = query.startAfterDocument(after);
      final snap = await query.get();
      return PostPage(
        posts: snap.docs.map(Post.fromDoc).toList(),
        last: snap.docs.isEmpty ? after : snap.docs.last,
        hasMore: snap.docs.length == limit,
      );
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  /// โพสต์ของผู้ใช้คนหนึ่งในฟีดหลัก (ต้องสร้าง composite index ก่อน ดู Step 9)
  Future<List<Post>> fetchByAuthor(String authorId, {int limit = 20}) async {
    try {
      final snap = await _posts()
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(Post.fromDoc).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        throw PostException(
          'ต้องสร้าง index ใน Firestore ก่อน (ดูขั้นตอน Index): ${e.message}',
        );
      }
      throw PostException(_message(e.code));
    }
  }

  /// โพสต์ที่ติดแท็กนี้ในฟีดหลัก เรียงใหม่สุดก่อน (ต้องมี composite index: hashtags + createdAt)
  Future<List<Post>> fetchByTag(String tag, {int limit = 30}) async {
    try {
      final snap = await _posts()
          .where('hashtags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(Post.fromDoc).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        throw PostException(
          'ต้องสร้าง index ใน Firestore ก่อน (ดูขั้นตอน Index): ${e.message}',
        );
      }
      throw PostException(_message(e.code));
    }
  }

  // ---------- โพสต์ ----------

  Future<void> createPost(
    AppUser author,
    String text, {
    String? mediaUrl,
    String? mediaType,
    String? groupId,
  }) async {
    try {
      await _posts(groupId).add({
        'authorId': author.uid,
        'authorName': author.displayName,
        'authorPhotoUrl': author.photoUrl,
        'text': text,
        'hashtags': extractTags(text),
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'reactionCounts': <String, int>{},
        'commentCount': 0,
      });
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  Future<void> updatePost(String postId, String text, {String? groupId}) async {
    try {
      await _posts(groupId).doc(postId).update({
        'text': text,
        'hashtags': extractTags(text),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  Future<void> deletePost(String postId, {String? groupId}) async {
    try {
      await _posts(groupId).doc(postId).delete();
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  // ---------- รีแอคชัน ----------

  /// รีแอคชันของผู้ใช้คนนี้ในโพสต์ (null = ยังไม่ได้รีแอคชัน)
  Future<String?> getMyReaction(
    String postId,
    String uid, {
    String? groupId,
  }) async {
    try {
      final snap = await _posts(
        groupId,
      ).doc(postId).collection(_reactions).doc(uid).get();
      return snap.data()?['type'] as String?;
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  /// ตั้งรีแอคชัน (type = null คือยกเลิก) พร้อมปรับตัวนับในโพสต์
  Future<void> setReaction(
    String postId,
    String uid,
    String? type, {
    String? groupId,
  }) async {
    final postRef = _posts(groupId).doc(postId);
    final reactRef = postRef.collection(_reactions).doc(uid);
    try {
      await _db.runTransaction((tx) async {
        final existing = await tx.get(reactRef);
        final old = existing.data()?['type'] as String?;
        if (old == type) return;

        final counts = <String, dynamic>{};
        if (old != null) {
          counts['reactionCounts.$old'] = FieldValue.increment(-1);
        }
        if (type != null) {
          counts['reactionCounts.$type'] = FieldValue.increment(1);
        }

        if (type == null) {
          tx.delete(reactRef);
        } else {
          tx.set(reactRef, {
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        tx.update(postRef, counts);
      });
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  // ---------- คอมเมนต์ ----------

  Future<int> getCommentCount(String postId, {String? groupId}) async {
    try {
      final snap = await _posts(groupId).doc(postId).get();
      return (snap.data()?['commentCount'] as num?)?.toInt() ?? 0;
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  Stream<List<Comment>> watchComments(
    String postId, {
    int limit = 200,
    String? groupId,
  }) {
    return _posts(groupId)
        .doc(postId)
        .collection(FirestorePaths.comments)
        .orderBy('createdAt')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Comment.fromDoc).toList());
  }

  Future<void> addComment(
    String postId,
    AppUser author,
    String text, {
    String? groupId,
  }) async {
    final postRef = _posts(groupId).doc(postId);
    final commentRef = postRef.collection(FirestorePaths.comments).doc();
    try {
      final batch = _db.batch();
      batch.set(commentRef, {
        'authorId': author.uid,
        'authorName': author.displayName,
        'authorPhotoUrl': author.photoUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(postRef, {'commentCount': FieldValue.increment(1)});
      await batch.commit();
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  Future<void> deleteComment(
    String postId,
    String commentId, {
    String? groupId,
  }) async {
    final postRef = _posts(groupId).doc(postId);
    try {
      final batch = _db.batch();
      batch.delete(postRef.collection(FirestorePaths.comments).doc(commentId));
      batch.update(postRef, {'commentCount': FieldValue.increment(-1)});
      await batch.commit();
    } on FirebaseException catch (e) {
      throw PostException(_message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้ (กลุ่ม: ต้องเป็นสมาชิก / เพจ: เฉพาะผู้ดูแล)';
      case 'unavailable':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      case 'not-found':
        return 'ไม่พบโพสต์นี้ (อาจถูกลบไปแล้ว)';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
