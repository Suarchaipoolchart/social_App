import 'package:cloud_firestore/cloud_firestore.dart';

/// เหตุผลในการรายงาน (key ต้องตรงกับที่ Security Rules อนุญาต)
const kReportReasons = <String, String>{
  'spam': 'สแปม / โฆษณา',
  'harassment': 'คุกคาม / ก้าวร้าว',
  'inappropriate': 'เนื้อหาไม่เหมาะสม',
  'misinformation': 'ข้อมูลเท็จ',
  'other': 'อื่นๆ',
};

class Report {
  final String id;
  final String reporterName;
  final String postId;
  final String? groupId;
  final String postAuthorName;
  final String postText;
  final String reason;
  final String detail;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterName,
    required this.postId,
    this.groupId,
    required this.postAuthorName,
    required this.postText,
    required this.reason,
    required this.detail,
    required this.createdAt,
  });

  String get reasonLabel => kReportReasons[reason] ?? reason;

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Report(
      id: doc.id,
      reporterName: data['reporterName'] ?? 'ผู้ใช้',
      postId: data['postId'] ?? '',
      groupId: data['groupId'],
      postAuthorName: data['postAuthorName'] ?? 'ผู้ใช้',
      postText: data['postText'] ?? '',
      reason: data['reason'] ?? 'other',
      detail: data['detail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
