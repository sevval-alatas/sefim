import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CadDonusumServisi {
  CadDonusumServisi({this.endpoint = 'http://localhost:3000/api/cad/convert'});

  final String endpoint;

  Future<File> dxfyeDonustur(String cadYolu) async {
    final kaynak = File(cadYolu);
    if (await kaynak.length() > 100 * 1024 * 1024) {
      throw Exception('Dosya boyutu 100 MB sınırını aşamaz.');
    }

    final istek = http.MultipartRequest('POST', Uri.parse(endpoint));
    istek.files.add(await http.MultipartFile.fromPath('file', cadYolu));

    final yanit = await istek.send().timeout(const Duration(seconds: 70));
    final bytes = await yanit.stream.toBytes();
    final yanitMetni = utf8.decode(bytes, allowMalformed: true);
    _log(
      'POST $endpoint -> ${yanit.statusCode}\n'
      'Response: $yanitMetni',
    );
    if (!_basariliDurumKodu(yanit.statusCode)) {
      final mesaj = _hataMesaji(bytes);
      throw Exception(mesaj.isEmpty ? 'CAD dosyası dönüştürülemedi.' : mesaj);
    }

    final cevap = jsonDecode(yanitMetni) as Map<String, dynamic>;
    final fileId = cevap['fileId'] as String?;
    if (fileId == null || fileId.isEmpty) {
      _log('POST yanıtında fileId bulunamadı. Response: $yanitMetni');
      throw Exception('Sunucu geçerli bir DXF dosya kimliği döndürmedi.');
    }

    final dxfYaniti = await http
        .get(_dxfUri(fileId))
        .timeout(const Duration(seconds: 30));
    _log(
      'GET ${_dxfUri(fileId)} -> ${dxfYaniti.statusCode}\n'
      'Bytes: ${dxfYaniti.bodyBytes.length}',
    );
    if (!_basariliDurumKodu(dxfYaniti.statusCode)) {
      final mesaj = _hataMesaji(dxfYaniti.bodyBytes);
      throw Exception(mesaj.isEmpty ? 'DXF dosyası indirilemedi.' : mesaj);
    }
    if (dxfYaniti.bodyBytes.isEmpty) {
      throw Exception('Sunucu boş bir DXF dosyası döndürdü.');
    }

    final klasor = await getTemporaryDirectory();
    final ad = _guvenliDosyaAdi(cadYolu);
    final dxf = File('${klasor.path}/$ad.dxf');
    final kaydedilenDxf = await dxf.writeAsBytes(
      dxfYaniti.bodyBytes,
      flush: true,
    );
    _log('DXF hazır: ${kaydedilenDxf.path}');
    return kaydedilenDxf;
  }

  bool _basariliDurumKodu(int durumKodu) => durumKodu >= 200 && durumKodu < 300;

  void _log(String mesaj) {
    developer.log(mesaj, name: 'CadDonusumServisi');
  }

  Uri _dxfUri(String fileId) {
    final donusumUri = Uri.parse(endpoint);
    return donusumUri.replace(
      path:
          '${donusumUri.path.replaceFirst(RegExp(r'/convert$'), '')}/files/$fileId',
      query: null,
    );
  }

  String _hataMesaji(List<int> bytes) {
    final metin = utf8.decode(bytes, allowMalformed: true);
    try {
      final veri = jsonDecode(metin);
      if (veri is Map<String, dynamic>) {
        return (veri['message'] ?? veri['detail'] ?? '').toString();
      }
    } on FormatException {
      return metin.trim();
    }
    return metin.trim();
  }

  String _guvenliDosyaAdi(String yol) {
    final ad = yol.split(Platform.pathSeparator).last;
    final nokta = ad.lastIndexOf('.');
    final govde = nokta > 0 ? ad.substring(0, nokta) : ad;
    return govde.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
