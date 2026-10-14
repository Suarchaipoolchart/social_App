import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadException implements Exception {
  final String message;
  UploadException(this.message);
}

class CloudinaryService {
  static const cloudName = 'wxixt1pj';
  static const uploadPreset = 'social_unsigned'; // เช่น social_unsigned

  /// อัปโหลดแล้วคืนค่าลิงก์ https ของไฟล์
  Future<String> upload(XFile file, {required bool isVideo}) async {
    final type = isVideo ? 'video' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$type/upload',
    );

    try {
      final bytes = await file.readAsBytes(); // ใช้ได้ทั้งเว็บและมือถือ
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: file.name),
        );

      final response = await http.Response.fromStream(await request.send());
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final msg = data['error']?['message'] ?? 'อัปโหลดไม่สำเร็จ';
        throw UploadException('อัปโหลดไม่สำเร็จ: $msg');
      }
      return data['secure_url'] as String;
    } on UploadException {
      rethrow;
    } catch (_) {
      throw UploadException('อัปโหลดไม่สำเร็จ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
    }
  }
}
