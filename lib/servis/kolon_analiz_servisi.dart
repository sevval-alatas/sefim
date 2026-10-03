/*
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class KolonAnalizServisi {
  KolonAnalizServisi({this.endpoint = 'http://localhost:3000/column/analyze'});

  final String endpoint;

  Future<Map<String, dynamic>> analizEt(
    String fotografYolu, {
    double? referenceWidthPx,
    double? referenceWidthMm,
  }) async {
    final fotograf = File(fotografYolu);
    if (!await fotograf.exists()) {
      throw Exception('Seçilen fotoğraf bulunamadı.');
    }
    final bytes = await fotograf.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Seçilen fotoğraf boş.');
    }

    final istek = http.MultipartRequest('POST', Uri.parse(endpoint));
    final dosyaAdi = fotograf.uri.pathSegments.last;
    istek.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: dosyaAdi,
        contentType: _icerikTuru(dosyaAdi),
      ),
    );
    if (referenceWidthPx != null) {
      istek.fields['referenceWidthPx'] = _sayi(referenceWidthPx);
    }
    if (referenceWidthMm != null) {
      istek.fields['referenceWidthMm'] = _sayi(referenceWidthMm);
    }

    final yanit = await istek.send().timeout(const Duration(seconds: 60));
    final yanitBytes = await yanit.stream.toBytes();
    final govde = utf8.decode(yanitBytes, allowMalformed: true);
    developer.log(
      'POST $endpoint -> ${yanit.statusCode}; '
      'file=$dosyaAdi, bytes=${bytes.length}\n$govde',
      name: 'KolonAnalizServisi',
    );
    if (yanit.statusCode < 200 || yanit.statusCode >= 300) {
      throw Exception(_hataMesaji(govde, yanit.statusCode));
    }

    final veri = jsonDecode(govde);
    if (veri is! Map<String, dynamic>) {
      throw Exception('Sunucu geçerli bir kolon analiz sonucu döndürmedi.');
    }
    return veri;
  }

  String _sayi(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  MediaType _icerikTuru(String dosyaAdi) {
    final uzanti = dosyaAdi.split('.').last.toLowerCase();
    return switch (uzanti) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      'heif' => MediaType('image', 'heif'),
      _ => MediaType('application', 'octet-stream'),
    };
  }

  String _hataMesaji(String govde, int durumKodu) {
    try {
      final veri = jsonDecode(govde);
      if (veri is Map<String, dynamic>) {
        final mesaj = veri['message'] ?? veri['error'] ?? veri['detail'];
        if (mesaj != null) return mesaj.toString();
      }
    } on FormatException {
      // JSON olmayan backend hata gövdeleri aşağıdaki metin olarak gösterilir.
    }
    return govde.trim().isEmpty
        ? 'Kolon analizi başarısız oldu. HTTP $durumKodu'
        : govde.trim();
  }
}
*/
