import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/data/app_user.dart';
import 'chat_models.dart';

class ChatException implements Exception {
  final String message;
  ChatException(this.message);
}

class ChatRepository {
  ChatRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection(FirestorePaths.chats);

  /// uid สองคนเรียงแล้วต่อกัน ได้ห้องเดียวเสมอไม่ว่าใครเริ่มก่อน
  static String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  /// รายการห้องแชตของฉัน เรียงล่าสุดก่อน (เรียงฝั่งแอป ไม่ต้องใช้ index)
  Stream<List<ChatSummary>> watchChats(String myUid) {
    return _chats.where('participants', arrayContains: myUid).snapshots().map((
      snap,
    ) {
      final now = DateTime.now();
      final list = snap.docs.map((d) => ChatSummary.fromDoc(d, myUid)).toList();
      list.sort(
        (a, b) => (b.lastMessageAt ?? now).compareTo(a.lastMessageAt ?? now),
      );
      return list;
    });
  }

  /// ข้อความล่าสุดของห้อง (ใหม่สุดอยู่ index 0)
  Stream<List<Message>> watchMessages(String chatId, {int limit = 100}) {
    return _chats
        .doc(chatId)
        .collection(FirestorePaths.messages)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Message.fromDoc).toList());
  }

  Future<void> sendMessage({
    required AppUser me,
    required ChatPeer peer,
    String text = '',
    String? mediaUrl,
    String? mediaType,
  }) async {
    final chatRef = _chats.doc(chatIdFor(me.uid, peer.uid));
    final preview = mediaType == 'image'
        ? '📷 รูปภาพ'
        : mediaType == 'video'
        ? '🎬 วิดีโอ'
        : text;
    final ids = [me.uid, peer.uid]..sort();

    try {
      // 1) สร้าง/อัปเดตห้อง (ให้รายการแชตของทั้งสองฝั่งเห็นข้อความล่าสุด)
      await chatRef.set({
        'participants': ids,
        'participantInfo': {
          me.uid: {'displayName': me.displayName, 'photoUrl': me.photoUrl},
          peer.uid: {'displayName': peer.name, 'photoUrl': peer.photoUrl},
        },
        'lastMessage': preview,
        'lastSenderId': me.uid,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2) เพิ่มข้อความ
      await chatRef.collection(FirestorePaths.messages).add({
        'senderId': me.uid,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ChatException(_message(e.code));
    }
  }

  /// รายชื่อผู้ใช้สำหรับเลือกเริ่มแชต (ข้อ 7 จะทำการค้นหาจริง)
  Future<List<ChatPeer>> fetchUsers(String myUid, {int limit = 50}) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.users)
          .orderBy('displayNameLower')
          .limit(limit)
          .get();
      return snap.docs.where((d) => d.id != myUid).map((d) {
        final data = d.data();
        return ChatPeer(
          uid: d.id,
          name: data['displayName'] ?? '',
          photoUrl: data['photoUrl'],
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw ChatException(_message(e.code));
    }
  }

  String _message(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์ทำรายการนี้ (ตรวจสอบ Security Rules)';
      case 'unavailable':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }
}
