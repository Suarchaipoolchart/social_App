import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';

class UserException implements Exception {
  final String message;
  UserException(this.message);
}

class UserRepository {
  UserRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// ค้นหาผู้ใช้ที่ชื่อขึ้นต้นด้วยคำที่พิมพ์ (ไม่แยกตัวพิมพ์เล็ก-ใหญ่)
  /// คำว่างจะคืนรายชื่อเรียงตามตัวอักษร
  Future<List<AppUser>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim().toLowerCase();
    try {
      Query<Map<String, dynamic>> ref = _db
          .collection(FirestorePaths.users)
          .orderBy('displayNameLower');
      if (q.isNotEmpty) {
        ref = ref.startAt([q]).endAt(['$q\uf8ff']);
      }
      final snap = await ref.limit(limit).get();
      return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      throw UserException(
        e.code == 'unavailable'
            ? 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต'
            : 'ค้นหาไม่สำเร็จ (${e.code})',
      );
    }
  }
}
