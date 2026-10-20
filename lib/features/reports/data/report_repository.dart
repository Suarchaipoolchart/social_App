import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/app_user.dart';
import '../../posts/data/post_model.dart';
import 'report_models.dart';

class ReportException implements Exception {
  final String message;
  ReportException(this.message);
}

class ReportRepository {
  ReportRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reports');

  /// รายงานโพสต์ รหัสเอกสารทำให้คนเดียวรายงานโพสต์เดียวได้ครั้งเดียว
  Future<void> report({
    required AppUser reporter,
    required Post post,
    required String reason,
    required String detail,
  }) async {
    final id = '${post.groupId ?? 'main'}__${post.id}__${reporter.uid}';
    final snippet = post.text.length > 200
        ? post.text.substring(0, 200)
        : post.text;
    try {
      await _col.doc(id).set({
        'reporterId': reporter.uid,
        'reporterName': reporter.displayName,
        'postId': post.id,
        'groupId': post.groupId,
        'postAuthorId': post.authorId,
        'postAuthorName': post.authorName,
        'postText': snippet,
        'reason': reason,
        'detail': detail,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // ส่งซ้ำ (เอกสารมีอยู่แล้ว) หรือรายงานโพสต์ของตัวเอง
        throw ReportException(
          'คุณรายงานโพสต์นี้ไปแล้ว หรือไม่สามารถรายงานโพสต์ของตัวเองได้',
        );
      }
      throw ReportException(_message(e.code));
    }
  }

  /// รายงานที่รอตรวจ (เฉพาะแอดมิน) เรียงใหม่สุดก่อน เรียงฝั่งแอปเพื่อไม่ต้องใช้ index
  Stream<List<Report>> watchOpen({int limit = 100}) {
    return _col.where('status', isEqualTo: 'open').limit(limit).snapshots().map(
      (snap) {
        final list = snap.docs.map(Report.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  /// ปิดรายงานหลายใบพร้อมกัน (เฉพาะแอดมิน)
  Future<void> resolve(
    List<String> reportIds,
    String adminUid,
    String resolution, // 'dismissed' | 'post_deleted'
  ) async {
    try {
      final batch = _db.batch();
      for (final id in reportIds) {
        batch.update(_col.doc(id), {
          'status': 'resolved',
          'resolution': resolution,
          'resolvedBy': adminUid,
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ReportException(_message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้';
      case 'unavailable':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
