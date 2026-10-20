import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../posts/data/post_model.dart';

/// กรองโพสต์ของบัญชีส่วนตัวออกจากฟีด ยกเว้นของตัวเองหรือคนที่ติดตามและได้รับอนุมัติแล้ว
/// (กรองฝั่งแอป ไม่ใช่การบังคับที่ Security Rules)
class FeedVisibility {
  FeedVisibility({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final Map<String, bool> _isPrivate = {};
  Set<String>? _following;

  /// ล้างแคช เรียกตอนรีเฟรชฟีด เพื่อให้การติดตามหรือการสลับโหมดมีผล
  void refresh() {
    _isPrivate.clear();
    _following = null;
  }

  Future<List<Post>> filter(List<Post> posts, String myUid) async {
    final unknown = posts
        .map((p) => p.authorId)
        .where((id) => id != myUid && !_isPrivate.containsKey(id))
        .toSet();

    await Future.wait(
      unknown.map((id) async {
        try {
          final snap = await _db.collection(FirestorePaths.users).doc(id).get();
          _isPrivate[id] = snap.data()?['isPrivate'] == true;
        } on FirebaseException {
          _isPrivate[id] = true; // เช็คไม่ได้ ซ่อนไว้ก่อนเพื่อความเป็นส่วนตัว
        }
      }),
    );

    if (_following == null &&
        posts.any((p) => _isPrivate[p.authorId] == true)) {
      await _loadFollowing(myUid);
    }

    return posts.where((p) {
      if (p.authorId == myUid) return true;
      if (_isPrivate[p.authorId] != true) return true;
      return _following?.contains(p.authorId) ?? false;
    }).toList();
  }

  Future<void> _loadFollowing(String myUid) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.follows)
          .where('followerId', isEqualTo: myUid)
          .where('status', isEqualTo: 'accepted')
          .limit(500)
          .get();
      _following = snap.docs
          .map((d) => d.data()['followeeId'] as String? ?? '')
          .toSet();
    } on FirebaseException {
      _following = <String>{};
    }
  }
}
