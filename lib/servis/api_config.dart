import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Uygulama genelindeki tüm HTTP isteklerinin gönderileceği sunucu adresini
/// `.env` / `assets/app.env` dosyasından tek bir merkezden yöneten yapılandırma sınıfı.
class ApiConfig {
  ApiConfig._();

  static const String _varsayilanBaseUrl = 'http://localhost:3000';
  static const List<String> _envAdayYollari = ['.env', 'assets/app.env'];

  static final Map<String, String> _envVerisi = {};
  static bool _envYuklendi = false;

  /// Uygulama başlangıcında `.env` veya `assets/app.env` dosyasını okur ve belleğe yükler.
  static Future<void> yukle({String? dosyaYolu}) async {
    final adaylar = dosyaYolu != null ? [dosyaYolu] : _envAdayYollari;

    // 1. Önce yerel dosya sisteminden kontrol et (.env varsa önceliklidir)
    for (final yol in adaylar) {
      try {
        final dosya = File(yol);
        if (await dosya.exists()) {
          final icerik = await dosya.readAsString();
          _envVerisi.clear();
          _ayristir(icerik);
          _envYuklendi = true;
          return;
        }
      } catch (_) {}
    }

    // 2. Flutter asset bundle üzerinden kontrol et (mobil/masaüstü paket içi çalışma)
    for (final yol in adaylar) {
      try {
        final icerik = await rootBundle.loadString(yol);
        _envVerisi.clear();
        _ayristir(icerik);
        _envYuklendi = true;
        return;
      } catch (_) {}
    }

    debugPrint(
      'ApiConfig: .env dosyası bulunamadı, varsayılan adres ($_varsayilanBaseUrl) kullanılacak.',
    );
  }

  /// Senkron erişimlerde henüz `yukle()` çağrılmadıysa yerel `.env` / `assets/app.env` dosyasını senkron okur.
  static void _senkronYuklemeyiGarantiEt() {
    if (_envYuklendi) return;
    _envYuklendi = true;
    for (final yol in _envAdayYollari) {
      try {
        final dosya = File(yol);
        if (dosya.existsSync()) {
          _ayristir(dosya.readAsStringSync());
          return;
        }
      } catch (_) {}
    }
  }

  /// Test veya çalışma zamanında bellekteki yapılandırmayı doğrudan (veya `.env` metninden) günceller.
  static void iceriktenYukle(String envIcerigi) {
    _envVerisi.clear();
    _ayristir(envIcerigi);
    _envYuklendi = true;
  }

  static void _ayristir(String icerik) {
    for (final hamSatir in icerik.split('\n')) {
      final satir = hamSatir.trim();
      if (satir.isEmpty || satir.startsWith('#')) continue;

      final esittirIndeksi = satir.indexOf('=');
      if (esittirIndeksi <= 0) continue;

      final anahtar = satir.substring(0, esittirIndeksi).trim();
      var deger = satir.substring(esittirIndeksi + 1).trim();

      if ((deger.startsWith('"') && deger.endsWith('"')) ||
          (deger.startsWith("'") && deger.endsWith("'"))) {
        deger = deger.substring(1, deger.length - 1);
      }

      if (anahtar.isNotEmpty) {
        _envVerisi[anahtar] = deger;
      }
    }
  }

  /// `.env` içerisinden belirtilen anahtarı okur.
  static String? degerAl(String anahtar) {
    _senkronYuklemeyiGarantiEt();
    return _envVerisi[anahtar];
  }

  /// API taban adresi (`API_BASE_URL`); Swagger dokümantasyon yolu temizlenir.
  static String get baseUrl {
    _senkronYuklemeyiGarantiEt();
    var url = (_envVerisi['API_BASE_URL'] ?? _varsayilanBaseUrl).trim();
    if (url.isEmpty) {
      url = _varsayilanBaseUrl;
    }
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.path.replaceFirst(RegExp(r'/$'), '').endsWith('/api/docs')) {
      final path = uri.path.replaceFirst(RegExp(r'/api/docs/?$'), '');
      url = uri.replace(path: path, query: null, fragment: null).toString();
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// CAD dönüştürme (DWG -> DXF/PDF) endpoint adresi.
  static String get cadConvertUrl {
    _senkronYuklemeyiGarantiEt();
    final ozelUrl = _envVerisi['CAD_CONVERT_URL']?.trim();
    if (ozelUrl != null && ozelUrl.isNotEmpty) {
      return ozelUrl;
    }
    return '$baseUrl/api/cad/convert';
  }

  /// Kimlik doğrulama (Auth) endpoint taban adresi.
  static String get authUrl => '$baseUrl/auth';

  /// Şantiye servisi endpoint taban adresi.
  static String get santiyeUrl => '$baseUrl/santiye';

  /// İrsaliye (Delivery Notes) endpoint adresi.
  static String get deliveryNotesUrl => '$baseUrl/delivery-notes';

  /// Kolon analiz endpoint adresi.
  static String get columnAnalyzeUrl => '$baseUrl/column/analyze';
}
