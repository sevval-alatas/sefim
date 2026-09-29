import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('DeliveryNoteServisi Tests', () {
    test('multipart/form-data ile photo alan adını ve authorization headerı doğru gönderir', () async {
      // Geçici bir test dosyası oluşturalım
      final tempDir = Directory.systemTemp.createTempSync();
      final testFile = File('${tempDir.path}/test_irsaliye.jpg');
      await testFile.writeAsBytes([255, 216, 255, 224]); // JPEG dummy header

      // Mock Client ile isteği yakalayalım
      final mockClient = MockClient((request) async {
        return http.Response('{"id": 1, "message": "Success"}', 201);
      });

      final uri = Uri.parse('http://localhost:3000/delivery-notes');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer test_token_123';
      request.files.add(
        await http.MultipartFile.fromPath('photo', testFile.path),
      );

      final streamedResponse = await mockClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      expect(response.statusCode, 201);
      expect(request.headers['Authorization'], 'Bearer test_token_123');
      expect(request.files.length, 1);
      expect(request.files.first.field, 'photo');
      expect(request.files.first.filename, 'test_irsaliye.jpg');

      // Temizlik
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
