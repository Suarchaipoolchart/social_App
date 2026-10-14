import 'package:cloud_firestore/cloud_firestore.dart';

/// คู่สนทนา (อีกฝั่งหนึ่งของห้อง)
class ChatPeer {
  final String uid;
  final String name;
  final String? photoUrl;

  const ChatPeer({required this.uid, required this.name, this.photoUrl});
}

/// ห้องแชตหนึ่งแถวในรายการแชต
class ChatSummary {
  final String id;
  final ChatPeer peer;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;

  const ChatSummary({
    required this.id,
    required this.peer,
    required this.lastMessage,
    required this.lastSenderId,
    this.lastMessageAt,
  });

  factory ChatSummary.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String myUid,
  ) {
    final data = doc.data() ?? {};
    final participants = List<String>.from(data['participants'] ?? const []);
    final otherUid = participants.firstWhere(
      (u) => u != myUid,
      orElse: () => '',
    );
    final info = (data['participantInfo'] as Map?)?[otherUid] as Map?;

    return ChatSummary(
      id: doc.id,
      peer: ChatPeer(
        uid: otherUid,
        name: (info?['displayName'] as String?) ?? 'ผู้ใช้',
        photoUrl: info?['photoUrl'] as String?,
      ),
      lastMessage: data['lastMessage'] ?? '',
      lastSenderId: data['lastSenderId'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' | 'video'
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      // createdAt เป็น null ชั่วคราวระหว่างรอเซิร์ฟเวอร์ตอบกลับ
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
