import 'package:flutter/services.dart';

class OcrService {
  static const MethodChannel _kanal = MethodChannel('sefim/ocr');

  Future<String> metniOku(String imagePath) async {
    final metin = await _kanal.invokeMethod<String>('recognizeText', {
      'path': imagePath,
    });
    return metin ?? '';
  }

  Future<void> dispose() async {}
}
