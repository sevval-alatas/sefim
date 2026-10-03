import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sefim/servis/libredwg_ffi.dart';

class KayitliProje {
  final String id;
  final String ad;
  final String dxfYolu;
  final String? dwgYolu;
  final DateTime kayitTarihi;
  final int dosyaBoyutu;

  KayitliProje({
    required this.id,
    required this.ad,
    required this.dxfYolu,
    this.dwgYolu,
    required this.kayitTarihi,
    required this.dosyaBoyutu,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'dxfYolu': dxfYolu,
        'dwgYolu': dwgYolu,
        'kayitTarihi': kayitTarihi.toIso8601String(),
        'dosyaBoyutu': dosyaBoyutu,
      };

  factory KayitliProje.fromJson(Map<String, dynamic> json) => KayitliProje(
        id: json['id'] as String,
        ad: json['ad'] as String,
        dxfYolu: json['dxfYolu'] as String,
        dwgYolu: json['dwgYolu'] as String?,
        kayitTarihi: DateTime.parse(json['kayitTarihi'] as String),
        dosyaBoyutu: (json['dosyaBoyutu'] as num?)?.toInt() ?? 0,
      );
}

class CadDonusumServisi {
  static const String _prefApiKey = 'cad_api_base_url';

  CadDonusumServisi();

  /// Varsayılan Python API Adresini döndürür
  static String varsayilanApiUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// SharedPreferences üzerinden kayıtlı API adresini veya varsayılan adresi getirir.
  Future<String> apiAdresiniGetir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kayitli = prefs.getString(_prefApiKey);
      if (kayitli != null && kayitli.trim().isNotEmpty) {
        return kayitli.trim();
      }
    } catch (e) {
      _log('SharedPreferences okunurken hata: $e');
    }
    return varsayilanApiUrl();
  }

  /// SharedPreferences üzerinde API adresini günceller.
  Future<void> apiAdresiniGuncelle(String yeniUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, yeniUrl.trim());
    _log('API adresi güncellendi: $yeniUrl');
  }

  /// Python API sunucusuna erişilebilirliğini test eder.
  Future<bool> apiSunucusuTestEt([String? testUrl]) async {
    try {
      final baseUrl = testUrl ?? await apiAdresiniGetir();
      final uri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      _log('API sunucu erişim testi başarısız: $e');
      return false;
    }
  }

  /// Kayıtlı projelerin tutulduğu kalıcı klasörü döndürür.
  Future<Directory> _projelerDizini() async {
    final docDir = await getApplicationDocumentsDirectory();
    final projelerDir = Directory('${docDir.path}/sefim_projeler');
    if (!await projelerDir.exists()) {
      await projelerDir.create(recursive: true);
    }
    return projelerDir;
  }

  /// Kayıtlı projelerin metadata listesini döndürür.
  Future<List<KayitliProje>> kayitliProjeleriGetir() async {
    try {
      final dir = await _projelerDizini();
      final metaDosya = File('${dir.path}/metadata.json');
      if (!await metaDosya.exists()) {
        return [];
      }
      final icerik = await metaDosya.readAsString();
      if (icerik.trim().isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(icerik);
      final projeler = jsonList.map((e) => KayitliProje.fromJson(e as Map<String, dynamic>)).toList();

      // Fiziksel olarak var olmayan DXF dosyalarını temizle
      final gecerliProjeler = <KayitliProje>[];
      for (final p in projeler) {
        if (await File(p.dxfYolu).exists()) {
          gecerliProjeler.add(p);
        }
      }

      if (gecerliProjeler.length != projeler.length) {
        await _metadataKaydet(dir, gecerliProjeler);
      }

      // Tarihe göre yeniden eskiye sırala
      gecerliProjeler.sort((a, b) => b.kayitTarihi.compareTo(a.kayitTarihi));
      return gecerliProjeler;
    } catch (e) {
      _log('Kayıtlı projeler yüklenirken hata: $e');
      return [];
    }
  }

  /// Metadata listesini dosyaya yazar.
  Future<void> _metadataKaydet(Directory dir, List<KayitliProje> projeler) async {
    final metaDosya = File('${dir.path}/metadata.json');
    final jsonStr = jsonEncode(projeler.map((e) => e.toJson()).toList());
    await metaDosya.writeAsString(jsonStr, flush: true);
  }

  /// Kayıtlı bir projeyi siler.
  Future<void> kayitliProjeyiSil(String id) async {
    final dir = await _projelerDizini();
    final projeler = await kayitliProjeleriGetir();
    final silinecek = projeler.where((p) => p.id == id).toList();

    for (final p in silinecek) {
      final dxfFile = File(p.dxfYolu);
      if (await dxfFile.exists()) {
        await dxfFile.delete();
      }
    }

    projeler.removeWhere((p) => p.id == id);
    await _metadataKaydet(dir, projeler);
    _log('Kayıtlı proje silindi: $id');
  }

  /// Proje için benzersiz kimlik (hash) üretir.
  Future<String> _dosyaKimlikOlustur(File dosya) async {
    final ad = _guvenliDosyaAdi(dosya.path);
    final len = await dosya.length();
    final modTime = (await dosya.lastModified()).millisecondsSinceEpoch;
    return '${ad}_${len}_$modTime';
  }

  /// Projeyi kaydeder veya günceller.
  Future<KayitliProje> _projeyiKaydet({
    required String id,
    required String ad,
    required String dxfYolu,
    String? dwgYolu,
    required int dosyaBoyutu,
  }) async {
    final dir = await _projelerDizini();
    final projeler = await kayitliProjeleriGetir();

    final yeniProje = KayitliProje(
      id: id,
      ad: ad,
      dxfYolu: dxfYolu,
      dwgYolu: dwgYolu,
      kayitTarihi: DateTime.now(),
      dosyaBoyutu: dosyaBoyutu,
    );

    projeler.removeWhere((p) => p.id == id);
    projeler.insert(0, yeniProje);

    await _metadataKaydet(dir, projeler);
    _log('Proje uygulamaya kaydedildi (offline erişim hazır): ${yeniProje.ad}');
    return yeniProje;
  }

  /// DWG/DXF dosyasını DXF formatına dönüştürür ve kalıcı olarak kaydeder.
  ///
  /// Önceden dönüştürülüp kaydedilmiş bir proje bulunursa doğrudan yerel depolamadan
  /// okunur; internet/API bağlantısı veya tekrar dönüştürme gerekmez.
  Future<File> dxfyeDonustur(String cadYolu, {bool zorlaYenidenDonustur = false}) async {
    try {
      final kaynak = File(cadYolu);
      if (!await kaynak.exists()) {
        throw Exception('CAD dosyası bulunamadı.');
      }
      if (await kaynak.length() > 100 * 1024 * 1024) {
        throw Exception('Dosya boyutu 100 MB sınırını aşamaz.');
      }

      final uzanti = cadYolu.split('.').last.toLowerCase();
      final dosyaAdi = cadYolu.split(Platform.pathSeparator).last;
      final projelerDir = await _projelerDizini();

      // 1. Eğer dosya zaten DXF ise
      if (uzanti == 'dxf') {
        _log('Dosya DXF formatında: $cadYolu');
        final id = await _dosyaKimlikOlustur(kaynak);
        final kaliciDxf = File('${projelerDir.path}/$id.dxf');

        if (!await kaliciDxf.exists()) {
          await kaynak.copy(kaliciDxf.path);
        }

        await _projeyiKaydet(
          id: id,
          ad: dosyaAdi,
          dxfYolu: kaliciDxf.path,
          dwgYolu: cadYolu,
          dosyaBoyutu: await kaliciDxf.length(),
        );

        return kaliciDxf;
      }

      // 2. DWG Dönüşüm Akışı
      if (uzanti == 'dwg') {
        final id = await _dosyaKimlikOlustur(kaynak);
        final kaliciDxf = File('${projelerDir.path}/$id.dxf');

        // ÖNEMLİ: Uygulamada daha önce kaydedilmiş proje var mı kontrol et!
        if (!zorlaYenidenDonustur && await kaliciDxf.exists() && await kaliciDxf.length() > 0) {
          _log('Kayıtlı proje yerel depolamada bulundu, API dönüştürme atlanıyor: ${kaliciDxf.path}');
          await _projeyiKaydet(
            id: id,
            ad: dosyaAdi,
            dxfYolu: kaliciDxf.path,
            dwgYolu: cadYolu,
            dosyaBoyutu: await kaliciDxf.length(),
          );
          return kaliciDxf;
        }

        // --- Adım 1: Python API (/convert) isteği at ---
        final baseUrl = await apiAdresiniGetir();
        final endpoint = baseUrl.endsWith('/convert')
            ? baseUrl
            : (baseUrl.endsWith('/') ? '${baseUrl}convert' : '$baseUrl/convert');

        _log('Python API ile DWG -> DXF dönüştürme deneniyor: $endpoint');

        try {
          final request = http.MultipartRequest('POST', Uri.parse(endpoint));
          request.files.add(await http.MultipartFile.fromPath('file', cadYolu));

          final streamedResponse = await request.send().timeout(
                const Duration(seconds: 90),
                onTimeout: () => throw Exception('API isteği zaman aşımına uğradı (90 sn).'),
              );

          if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
            final bytes = await streamedResponse.stream.toBytes();
            if (bytes.isNotEmpty) {
              await kaliciDxf.writeAsBytes(bytes, flush: true);
              _log('Python API ile DWG dönüştürüldü ve kaydedildi: ${kaliciDxf.path}');

              await _projeyiKaydet(
                id: id,
                ad: dosyaAdi,
                dxfYolu: kaliciDxf.path,
                dwgYolu: cadYolu,
                dosyaBoyutu: bytes.length,
              );

              return kaliciDxf;
            }
          } else {
            final errBody = await streamedResponse.stream.bytesToString();
            _log('Python API yanıtı başarısız [${streamedResponse.statusCode}]: $errBody');
          }
        } catch (e) {
          _log('Python API isteği esnasında hata oluştu: $e');
        }

        // --- Adım 2: Native LibreDWG FFI köprüsünü dene (Yerel Çevrimdışı Yedek) ---
        _log('LibreDWG FFI ile yerel dönüşüm deneniyor...');
        try {
          final geciciDxf = File('${(await getTemporaryDirectory()).path}/$id.dxf');
          final donustu = LibreDwgFfi.convertDwgToDxf(cadYolu, geciciDxf.path);
          if (donustu && await geciciDxf.exists() && await geciciDxf.length() > 0) {
            await geciciDxf.copy(kaliciDxf.path);
            _log('LibreDWG FFI ile DWG dönüştürüldü ve kaydedildi: ${kaliciDxf.path}');

            await _projeyiKaydet(
              id: id,
              ad: dosyaAdi,
              dxfYolu: kaliciDxf.path,
              dwgYolu: cadYolu,
              dosyaBoyutu: await kaliciDxf.length(),
            );

            return kaliciDxf;
          }
        } catch (e) {
          _log('LibreDWG FFI denenirken hata: $e');
        }

        // --- Adım 3: Masaüstü CLI araçlarını dene (dwg2dxf, odafileconverter) ---
        if (!Platform.isIOS && !Platform.isAndroid) {
          _log('Masaüstü CLI araçları deneniyor...');
          const denenecekKomutlar = ['dwg2dxf', 'odafileconverter'];
          final geciciKlasor = await getTemporaryDirectory();
          final geciciDxf = File('${geciciKlasor.path}/$id.dxf');

          for (final komut in denenecekKomutlar) {
            try {
              ProcessResult sonuc;
              if (komut == 'dwg2dxf') {
                sonuc = await Process.run(komut, [
                  '-y',
                  '--as=r2013',
                  '-o',
                  geciciDxf.path,
                  cadYolu,
                ]);
              } else {
                sonuc = await Process.run(komut, [
                  kaynak.parent.path,
                  geciciKlasor.path,
                  'ACAD2018',
                  'DXF',
                  '0',
                  '1',
                ]);
              }
              if (sonuc.exitCode == 0 && await geciciDxf.exists() && await geciciDxf.length() > 0) {
                await geciciDxf.copy(kaliciDxf.path);
                _log('CLI aracı ($komut) ile DWG dönüştürüldü ve kaydedildi.');

                await _projeyiKaydet(
                  id: id,
                  ad: dosyaAdi,
                  dxfYolu: kaliciDxf.path,
                  dwgYolu: cadYolu,
                  dosyaBoyutu: await kaliciDxf.length(),
                );

                return kaliciDxf;
              }
            } catch (e) {
              _log('$komut CLI komutu denendi fakat çalıştırılamadı: $e');
            }
          }
        }

        throw Exception(
          'DWG dosyası dönüştürülemedi.\n'
          '1. Python API sunucusunun çalıştığından ($baseUrl/convert) emin olun.\n'
          '2. Veya önceden çevrilmiş kayıtlı projelerinizi çevrimdışı açın.',
        );
      }

      throw Exception('Yalnızca DWG veya DXF dosyaları desteklenir.');
    } catch (e, stackTrace) {
      debugPrint('CadDonusumServisi Hatası: $e\n$stackTrace');
      rethrow;
    }
  }

  void _log(String mesaj) {
    debugPrint('CadDonusumServisi Log: $mesaj');
    developer.log(mesaj, name: 'CadDonusumServisi');
  }

  String _guvenliDosyaAdi(String yol) {
    final ad = yol.split(Platform.pathSeparator).last;
    final nokta = ad.lastIndexOf('.');
    final govde = nokta > 0 ? ad.substring(0, nokta) : ad;
    return govde.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
