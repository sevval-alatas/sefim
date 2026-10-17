import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sefim/servis/api_config.dart';
import 'package:sefim/servis/cad_mobil_sahnesi.dart';
import 'package:sefim/servis/libredwg_ffi.dart';

class KayitliProje {
  final String id;
  final String ad;
  final String? pdfYolu;
  final String dxfYolu;
  final String? dwgYolu;
  final String? sahneYolu;
  final DateTime kayitTarihi;
  final int dosyaBoyutu;

  KayitliProje({
    required this.id,
    required this.ad,
    this.pdfYolu,
    String? dxfYolu,
    this.dwgYolu,
    this.sahneYolu,
    required this.kayitTarihi,
    required this.dosyaBoyutu,
  }) : dxfYolu = dxfYolu ?? (pdfYolu ?? '');

  /// Görüntülenecek dosya yolu (PDF öncelikli, yoksa DXF, yoksa DWG)
  String get goruntulemeYolu {
    if (pdfYolu != null && pdfYolu!.isNotEmpty) return pdfYolu!;
    if (dxfYolu.isNotEmpty) return dxfYolu;
    return dwgYolu ?? '';
  }

  bool get pdfMi =>
      (pdfYolu != null && pdfYolu!.isNotEmpty) ||
      dxfYolu.toLowerCase().endsWith('.pdf');

  KayitliProje copyWith({
    String? id,
    String? ad,
    String? pdfYolu,
    String? dxfYolu,
    String? dwgYolu,
    String? sahneYolu,
    DateTime? kayitTarihi,
    int? dosyaBoyutu,
  }) {
    return KayitliProje(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      pdfYolu: pdfYolu ?? this.pdfYolu,
      dxfYolu: dxfYolu ?? this.dxfYolu,
      dwgYolu: dwgYolu ?? this.dwgYolu,
      sahneYolu: sahneYolu ?? this.sahneYolu,
      kayitTarihi: kayitTarihi ?? this.kayitTarihi,
      dosyaBoyutu: dosyaBoyutu ?? this.dosyaBoyutu,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ad': ad,
    'pdfYolu': pdfYolu,
    'dxfYolu': dxfYolu,
    'dwgYolu': dwgYolu,
    'sahneYolu': sahneYolu,
    'kayitTarihi': kayitTarihi.toIso8601String(),
    'dosyaBoyutu': dosyaBoyutu,
  };

  factory KayitliProje.fromJson(Map<dynamic, dynamic> json) => KayitliProje(
    id: json['id'] as String,
    ad: json['ad'] as String,
    pdfYolu: json['pdfYolu'] as String?,
    dxfYolu: (json['dxfYolu'] ?? json['pdfYolu']) as String?,
    dwgYolu: json['dwgYolu'] as String?,
    sahneYolu: json['sahneYolu'] as String?,
    kayitTarihi: DateTime.parse(json['kayitTarihi'] as String),
    dosyaBoyutu: (json['dosyaBoyutu'] as num?)?.toInt() ?? 0,
  );
}

/// Backend CAD API yanıtını (DXF veya PDF) temsil eden sonuç modeli
class CadDonusumSonucu {
  final File dosya;
  final String format; // 'dxf' veya 'pdf'
  final Uint8List bytes;

  const CadDonusumSonucu({
    required this.dosya,
    required this.format,
    required this.bytes,
  });

  bool get dxfMi => format == 'dxf';
  bool get pdfMi => format == 'pdf';
}

class CadMobileSceneSonucu {
  const CadMobileSceneSonucu({required this.scene, required this.dxfFile});

  final CadMobileScene scene;
  final File dxfFile;
}

class CadDonusumServisi {
  static const String _prefApiKey = 'cad_api_base_url';
  static const String _prefDeviceIdKey = 'sefim_cad_device_id';
  static const String _hiveProjelerBoxAdi = 'kayitli_projeler';
  static const String _hiveProjeIcerikBoxAdi = 'kayitli_proje_icerikleri';
  static String? _aktifHiveDizini;

  CadDonusumServisi({this.client});

  final http.Client? client;

  /// Uygulama başlangıcında Hive kutularını hazırlar.
  static Future<void> hiveBaslat() async {
    await CadDonusumServisi()._hiveHazirla();
  }

  /// `.env` (ApiConfig) üzerinden varsayılan CAD API adresini döndürür.
  static String varsayilanApiUrl() {
    return ApiConfig.cadConvertUrl;
  }

  /// Verilen URL'yi CAD dönüştürme endpoint'ine normalize eder.
  /// Örneğin 'http://localhost:3000' verilirse 'http://localhost:3000/api/cad/convert' döndürür.
  static String endpointUrl(String inputUrl) {
    var url = inputUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api/docs')) {
      url = url.substring(0, url.length - '/api/docs'.length);
    }
    if (url.endsWith('/api/cad/convert')) {
      return url;
    }
    if (url.endsWith('/convert')) {
      return url;
    }
    return '$url/api/cad/convert';
  }

  /// SharedPreferences üzerinden kayıtlı API adresini veya `.env` varsayılan adresini getirir.
  Future<String> apiAdresiniGetir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kayitli = prefs.getString(_prefApiKey);
      if (kayitli != null && kayitli.trim().isNotEmpty) {
        // Eski geçersiz adresler veya eski ddns önbelleği kaldıysa .env varsayılanına sıfırla
        if (kayitli.contains('onrender.com') ||
            kayitli.contains('34.89.212') ||
            kayitli.contains('cad.sefimbackend') ||
            kayitli.contains('sefim-backend.ddns.net')) {
          await prefs.remove(_prefApiKey);
          return varsayilanApiUrl();
        }
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

  /// Kayıtlı API adresini silerek varsayılan adrese döndürür.
  Future<void> apiAdresiniSifirla() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
    _log('API adresi varsayılana sıfırlandı.');
  }

  /// CAD API'nin zorunlu cihaz kimliğini kurulumlar arasında sabit tutar.
  Future<String> cihazKimliginiGetir() async {
    final prefs = await SharedPreferences.getInstance();
    final mevcut = prefs.getString(_prefDeviceIdKey);
    if (mevcut != null && mevcut.isNotEmpty) return mevcut;

    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await prefs.setString(_prefDeviceIdKey, id);
    return id;
  }

  /// CAD API sunucusuna erişilebilirliğini test eder.
  Future<bool> apiSunucusuTestEt([String? testUrl]) async {
    try {
      final url = testUrl ?? await apiAdresiniGetir();
      final targetEndpoint = endpointUrl(url);

      // 1. Önce conversion endpoint'ini dene
      try {
        final epUri = Uri.parse(targetEndpoint);
        final epResponse = await http
            .get(epUri)
            .timeout(const Duration(seconds: 4));
        if (epResponse.statusCode < 500) {
          return true;
        }
      } catch (_) {
        // Endpoint doğrudan GET kabul etmiyor olabilir, kök adresi dene
      }

      // 2. Kök sunucu adresini dene
      final uri = Uri.parse(url);
      final rootUri = Uri(
        scheme: uri.scheme.isNotEmpty ? uri.scheme : 'http',
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: '/',
      );
      final response = await http
          .get(rootUri)
          .timeout(const Duration(seconds: 4));
      return response.statusCode < 500;
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

  /// Hive kutularını hazırlar ve eski metadata.json kayıtları varsa Hive'a taşır.
  Future<(Box<dynamic>, Box<dynamic>)> _hiveHazirla() async {
    final docDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${docDir.path}/sefim_hive');
    if (!await hiveDir.exists()) {
      await hiveDir.create(recursive: true);
    }

    if (_aktifHiveDizini != hiveDir.path) {
      await Hive.close();
      Hive.init(hiveDir.path);
      _aktifHiveDizini = hiveDir.path;
    }

    final projelerBox = Hive.isBoxOpen(_hiveProjelerBoxAdi)
        ? Hive.box<dynamic>(_hiveProjelerBoxAdi)
        : await Hive.openBox<dynamic>(_hiveProjelerBoxAdi);
    final icerikBox = Hive.isBoxOpen(_hiveProjeIcerikBoxAdi)
        ? Hive.box<dynamic>(_hiveProjeIcerikBoxAdi)
        : await Hive.openBox<dynamic>(_hiveProjeIcerikBoxAdi);

    await _eskiMetadataVarsaHiveaTasi(projelerBox, icerikBox);
    return (projelerBox, icerikBox);
  }

  /// Eski metadata.json dosyasındaki projeleri (varsa) Hive'a taşır.
  Future<void> _eskiMetadataVarsaHiveaTasi(
    Box<dynamic> projelerBox,
    Box<dynamic> icerikBox,
  ) async {
    try {
      final dir = await _projelerDizini();
      final metaDosya = File('${dir.path}/metadata.json');
      if (!await metaDosya.exists()) return;

      final icerik = await metaDosya.readAsString();
      if (icerik.trim().isEmpty) {
        await metaDosya.delete();
        return;
      }

      final List<dynamic> jsonList = jsonDecode(icerik);
      for (final item in jsonList) {
        if (item is Map) {
          final p = KayitliProje.fromJson(item);
          if (!projelerBox.containsKey(p.id)) {
            await projelerBox.put(p.id, p.toJson());
            await _dosyaIceriginiHiveYedekle(icerikBox, p.id, 'pdf', p.pdfYolu);
            await _dosyaIceriginiHiveYedekle(icerikBox, p.id, 'dxf', p.dxfYolu);
            await _dosyaIceriginiHiveYedekle(icerikBox, p.id, 'dwg', p.dwgYolu);
          }
        }
      }
      await projelerBox.flush();
      await icerikBox.flush();
      await metaDosya.delete();
    } catch (e) {
      _log('Eski metadata Hive\'a taşınırken uyarı: $e');
    }
  }

  String _dosyaAdiAyikla(String yol) {
    final parcalar = yol.split(RegExp(r'[/\\]'));
    return parcalar.isNotEmpty ? parcalar.last : yol;
  }

  Future<void> _dosyaIceriginiHiveYedekle(
    Box<dynamic> icerikBox,
    String projeId,
    String turAnahtari,
    String? dosyaYolu,
  ) async {
    if (dosyaYolu == null || dosyaYolu.isEmpty) return;
    try {
      final file = File(dosyaYolu);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          await icerikBox.put('$projeId:$turAnahtari', bytes);
        }
      }
    } catch (e) {
      _log('Dosya Hive yedeği alınırken uyarı ($projeId:$turAnahtari): $e');
    }
  }

  Future<String?> _dosyaYolunuCozumleVeKurtar(
    Directory projelerDir,
    Box<dynamic> icerikBox,
    String projeId,
    String? kayitliYol,
    String turAnahtari,
  ) async {
    if (kayitliYol == null || kayitliYol.isEmpty) return null;

    final dosyaAdi = _dosyaAdiAyikla(kayitliYol);
    final guncelDosya = File('${projelerDir.path}/$dosyaAdi');
    final yedekAnahtari = '$projeId:$turAnahtari';

    if (await guncelDosya.exists() && await guncelDosya.length() > 0) {
      if (!icerikBox.containsKey(yedekAnahtari)) {
        await _dosyaIceriginiHiveYedekle(
          icerikBox,
          projeId,
          turAnahtari,
          guncelDosya.path,
        );
      }
      return guncelDosya.path;
    }

    final eskiDosya = File(kayitliYol);
    if (eskiDosya.path != guncelDosya.path &&
        await eskiDosya.exists() &&
        await eskiDosya.length() > 0) {
      await eskiDosya.copy(guncelDosya.path);
      await _dosyaIceriginiHiveYedekle(
        icerikBox,
        projeId,
        turAnahtari,
        guncelDosya.path,
      );
      return guncelDosya.path;
    }

    final yedekVeri = icerikBox.get(yedekAnahtari);
    if (yedekVeri is List<int> && yedekVeri.isNotEmpty) {
      await guncelDosya.writeAsBytes(yedekVeri, flush: true);
      return guncelDosya.path;
    }

    return guncelDosya.path;
  }

  /// Hive üzerinde kayıtlı projelerin listesini döndürür.
  /// Projeler kullanıcı açıkça silene kadar Hive'dan silinmez.
  Future<List<KayitliProje>> kayitliProjeleriGetir() async {
    try {
      final dir = await _projelerDizini();
      final (projelerBox, icerikBox) = await _hiveHazirla();
      final projeler = <KayitliProje>[];

      for (final key in projelerBox.keys) {
        final raw = projelerBox.get(key);
        if (raw is! Map) continue;

        final p = KayitliProje.fromJson(raw);
        final guncelPdf = await _dosyaYolunuCozumleVeKurtar(
          dir,
          icerikBox,
          p.id,
          p.pdfYolu,
          'pdf',
        );
        final guncelDxf =
            await _dosyaYolunuCozumleVeKurtar(
              dir,
              icerikBox,
              p.id,
              p.dxfYolu,
              'dxf',
            ) ??
            p.dxfYolu;
        final guncelDwg = await _dosyaYolunuCozumleVeKurtar(
          dir,
          icerikBox,
          p.id,
          p.dwgYolu,
          'dwg',
        );
        final guncelSahne = await _dosyaYolunuCozumleVeKurtar(
          dir,
          icerikBox,
          p.id,
          p.sahneYolu,
          'scene',
        );

        final cozumlenmis = p.copyWith(
          pdfYolu: guncelPdf,
          dxfYolu: guncelDxf,
          dwgYolu: guncelDwg,
          sahneYolu: guncelSahne,
        );

        if (cozumlenmis.pdfYolu != p.pdfYolu ||
            cozumlenmis.dxfYolu != p.dxfYolu ||
            cozumlenmis.dwgYolu != p.dwgYolu ||
            cozumlenmis.sahneYolu != p.sahneYolu) {
          await projelerBox.put(p.id, cozumlenmis.toJson());
        }

        projeler.add(cozumlenmis);
      }

      // Tarihe göre yeniden eskiye sırala
      projeler.sort((a, b) => b.kayitTarihi.compareTo(a.kayitTarihi));
      return projeler;
    } catch (e) {
      _log('Kayıtlı projeler Hive\'dan yüklenirken hata: $e');
      return [];
    }
  }

  /// Kayıtlı bir projeyi yalnızca kullanıcı istediğinde Hive'dan ve diskten siler.
  Future<void> kayitliProjeyiSil(String id) async {
    final (projelerBox, icerikBox) = await _hiveHazirla();
    final projeler = await kayitliProjeleriGetir();
    final silinecek = projeler.where((p) => p.id == id).toList();

    for (final p in silinecek) {
      for (final yol in <String?>[
        p.pdfYolu,
        p.dxfYolu,
        p.dwgYolu,
        p.sahneYolu,
      ]) {
        if (yol != null && yol.isNotEmpty) {
          final file = File(yol);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    }

    await projelerBox.delete(id);
    for (final tur in const ['pdf', 'dxf', 'dwg', 'scene']) {
      await icerikBox.delete('$id:$tur');
    }
    await projelerBox.flush();
    await icerikBox.flush();
    _log('Kayıtlı proje Hive ve yerel depolamadan silindi: $id');
  }

  /// Proje için kayıtlı çevrimdışı mobil CAD sahnesini (varsa) getirir.
  Future<CadMobileScene?> kayitliMobilSahneyiGetir(String projeId) async {
    try {
      final dir = await _projelerDizini();
      final (_, icerikBox) = await _hiveHazirla();
      final sahneDosyasi = File('${dir.path}/$projeId.scene.json');

      if (await sahneDosyasi.exists() && await sahneDosyasi.length() > 0) {
        final bytes = await sahneDosyasi.readAsBytes();
        return await CadMobileScene.decodeBytes(bytes);
      }

      final yedek = icerikBox.get('$projeId:scene');
      if (yedek is List<int> && yedek.isNotEmpty) {
        final bytes = yedek is Uint8List ? yedek : Uint8List.fromList(yedek);
        await sahneDosyasi.writeAsBytes(bytes, flush: true);
        return await CadMobileScene.decodeBytes(bytes);
      }
    } catch (e) {
      _log('Kayıtlı mobil sahne yüklenemedi ($projeId): $e');
    }
    return null;
  }

  /// Proje için benzersiz kimlik (hash) üretir.
  Future<String> _dosyaKimlikOlustur(File dosya) async {
    final ad = _guvenliDosyaAdi(dosya.path);
    final len = await dosya.length();
    return '${ad}_$len';
  }

  /// Seçilen kaynak dosyayı uygulamanın kalıcı proje klasörüne ve Hive'a kaydeder.
  Future<KayitliProje> projeyiKaliciKaydet(String dosyaYolu) async {
    final kaynak = File(dosyaYolu);
    if (!await kaynak.exists()) {
      throw Exception('Seçilen proje dosyası bulunamadı.');
    }
    if (await kaynak.length() > 100 * 1024 * 1024) {
      throw Exception('Dosya boyutu 100 MB sınırını aşamaz.');
    }

    final dir = await _projelerDizini();
    final dosyaAdi = _dosyaAdiAyikla(kaynak.path);
    final uzanti = dosyaAdi.contains('.')
        ? dosyaAdi.split('.').last.toLowerCase()
        : '';
    final id = await _dosyaKimlikOlustur(kaynak);
    final kaliciDosya = File(
      '${dir.path}/$id${uzanti.isEmpty ? '' : '.$uzanti'}',
    );

    if (kaynak.absolute.path != kaliciDosya.absolute.path) {
      await kaynak.copy(kaliciDosya.path);
    }

    final proje = await _projeyiKaydet(
      id: id,
      ad: dosyaAdi,
      pdfYolu: uzanti == 'pdf' ? kaliciDosya.path : null,
      dxfYolu: kaliciDosya.path,
      dwgYolu: uzanti == 'dwg' ? kaliciDosya.path : null,
      dosyaBoyutu: await kaliciDosya.length(),
    );
    _log('Proje Hive ve kalıcı cihaz depolamasına kaydedildi: ${proje.ad}');
    return proje;
  }

  /// Projeyi Hive'a kaydeder veya günceller.
  Future<KayitliProje> _projeyiKaydet({
    required String id,
    required String ad,
    String? pdfYolu,
    String? dxfYolu,
    String? dwgYolu,
    String? sahneYolu,
    required int dosyaBoyutu,
  }) async {
    final (projelerBox, icerikBox) = await _hiveHazirla();
    KayitliProje? mevcut;
    final mevcutRaw = projelerBox.get(id);
    if (mevcutRaw is Map) {
      try {
        mevcut = KayitliProje.fromJson(mevcutRaw);
      } catch (_) {}
    }

    final yeniProje = KayitliProje(
      id: id,
      ad: ad,
      pdfYolu: pdfYolu ?? mevcut?.pdfYolu,
      dxfYolu: dxfYolu ?? pdfYolu ?? mevcut?.dxfYolu ?? '',
      dwgYolu: dwgYolu ?? mevcut?.dwgYolu,
      sahneYolu: sahneYolu ?? mevcut?.sahneYolu,
      kayitTarihi: DateTime.now(),
      dosyaBoyutu: dosyaBoyutu,
    );

    await projelerBox.put(id, yeniProje.toJson());
    await _dosyaIceriginiHiveYedekle(icerikBox, id, 'pdf', yeniProje.pdfYolu);
    await _dosyaIceriginiHiveYedekle(icerikBox, id, 'dxf', yeniProje.dxfYolu);
    await _dosyaIceriginiHiveYedekle(icerikBox, id, 'dwg', yeniProje.dwgYolu);
    await _dosyaIceriginiHiveYedekle(
      icerikBox,
      id,
      'scene',
      yeniProje.sahneYolu,
    );
    await projelerBox.flush();
    await icerikBox.flush();

    _log('Proje Hive\'a kaydedildi (silinene kadar kalıcı): ${yeniProje.ad}');
    return yeniProje;
  }

  Future<String?> _kayitliProjeAdiniBul(String id) async {
    final (projelerBox, _) = await _hiveHazirla();
    final raw = projelerBox.get(id);
    if (raw is Map && raw['ad'] is String) {
      return raw['ad'] as String;
    }
    return null;
  }

  /// DWG/DXF dosyasını DXF formatına dönüştürür ve kalıcı olarak kaydeder.
  ///
  /// Debug modunda her DWG backend'e gönderilir; release modunda kayıtlı dönüşüm
  /// yerel depolamadan kullanılabilir.
  Future<File> dxfyeDonustur(
    String cadYolu, {
    bool zorlaYenidenDonustur = false,
    String format = 'dxf',
    String? projeId,
  }) async {
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
        final id = projeId ?? await _dosyaKimlikOlustur(kaynak);
        final projeAdi = await _kayitliProjeAdiniBul(id) ?? dosyaAdi;
        final kaliciDxf = File('${projelerDir.path}/$id.dxf');

        if (!await kaliciDxf.exists()) {
          await kaynak.copy(kaliciDxf.path);
        }

        await _projeyiKaydet(
          id: id,
          ad: projeAdi,
          dxfYolu: kaliciDxf.path,
          dwgYolu: cadYolu,
          dosyaBoyutu: await kaliciDxf.length(),
        );

        return kaliciDxf;
      }

      // 2. DWG Dönüşüm Akışı
      if (uzanti == 'dwg') {
        final id = projeId ?? await _dosyaKimlikOlustur(kaynak);
        final projeAdi = await _kayitliProjeAdiniBul(id) ?? dosyaAdi;
        final kaliciPdf = File('${projelerDir.path}/$id.pdf');
        final kaliciDxf = File('${projelerDir.path}/$id.dxf');
        final kaliciDwg = File('${projelerDir.path}/$id.dwg');

        // ÖNEMLİ: Proje daha önce dönüştürülüp cihaza kaydedilmiş mi kontrol et!
        if (!kDebugMode &&
            !zorlaYenidenDonustur &&
            ((await kaliciPdf.exists() && await kaliciPdf.length() > 0) ||
                (await kaliciDxf.exists() && await kaliciDxf.length() > 0))) {
          final mevcutDosya =
              (await kaliciPdf.exists() && await kaliciPdf.length() > 0)
              ? kaliciPdf
              : kaliciDxf;
          final isPdf = mevcutDosya.path.endsWith('.pdf');
          _log(
            'Kayıtlı proje cihaz depolamasında bulundu, yerel depolamadan doğrudan açılıyor: ${mevcutDosya.path}',
          );
          await _projeyiKaydet(
            id: id,
            ad: projeAdi,
            pdfYolu: isPdf ? mevcutDosya.path : null,
            dxfYolu: mevcutDosya.path,
            dwgYolu: kaliciDwg.existsSync() ? kaliciDwg.path : cadYolu,
            dosyaBoyutu: await mevcutDosya.length(),
          );
          return mevcutDosya;
        }

        // --- Adım 1: İlk defa dönüştürülüyorsa CAD API isteği at ---
        final baseUrl = await apiAdresiniGetir();
        final endpoint = endpointUrl(baseUrl);

        _log(
          '${kDebugMode ? 'Debug: ' : ''}CAD API ile DWG dönüştürme başlatılıyor: $endpoint',
        );
        String? apiHataDetayi;

        try {
          final deviceId = await cihazKimliginiGetir();
          final uri = Uri.parse(endpoint);
          final requestUri = uri.replace(
            queryParameters: {
              ...uri.queryParameters,
              'format': format,
              'deviceId': deviceId,
            },
          );
          final request = http.MultipartRequest('POST', requestUri);
          request.headers['x-device-id'] = deviceId;
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              cadYolu,
              filename: dosyaAdi.toLowerCase().endsWith('.dwg')
                  ? dosyaAdi
                  : '$dosyaAdi.dwg',
            ),
          );

          final streamedResponse =
              await (client?.send(request) ?? request.send()).timeout(
                const Duration(seconds: 90),
                onTimeout: () =>
                    throw Exception('API isteği zaman aşımına uğradı (90 sn).'),
              );

          if (streamedResponse.statusCode == 200 ||
              streamedResponse.statusCode == 201) {
            // 1. Backend'in döndüğü formatı başlık veya MIME türünden okuyun
            final headerFormat = streamedResponse.headers['x-cad-format']
                ?.toLowerCase()
                .trim();
            final contentType =
                streamedResponse.headers['content-type']?.toLowerCase() ?? '';
            final headerDanFormat =
                headerFormat ??
                (contentType.contains('pdf')
                    ? 'pdf'
                    : (contentType.contains('dxf') ? 'dxf' : null));

            final bytes = await streamedResponse.stream.toBytes();
            if (bytes.isNotEmpty) {
              final isMagicPdf =
                  bytes.length >= 4 &&
                  bytes[0] == 0x25 &&
                  bytes[1] == 0x50 &&
                  bytes[2] == 0x44 &&
                  bytes[3] == 0x46; // %PDF

              // x-cad-format, content-type veya içerik byte'larına göre formatı belirle
              final cadFormat = headerDanFormat ?? (isMagicPdf ? 'pdf' : 'dxf');
              final isPdf = cadFormat == 'pdf';
              final ciktiDosyasi = isPdf ? kaliciPdf : kaliciDxf;

              await ciktiDosyasi.writeAsBytes(bytes, flush: true);
              if (!await kaliciDwg.exists()) {
                await kaynak.copy(kaliciDwg.path);
              }
              _log(
                'CAD API ile DWG dönüştürüldü [Format: $cadFormat] ve cihaza kaydedildi: ${ciktiDosyasi.path}',
              );

              await _projeyiKaydet(
                id: id,
                ad: projeAdi,
                pdfYolu: isPdf ? ciktiDosyasi.path : null,
                dxfYolu: !isPdf
                    ? ciktiDosyasi.path
                    : (await kaliciDxf.exists()
                          ? kaliciDxf.path
                          : ciktiDosyasi.path),
                dwgYolu: kaliciDwg.path,
                dosyaBoyutu: bytes.length,
              );

              return ciktiDosyasi;
            } else {
              apiHataDetayi = 'CAD API boş yanıt döndürdü.';
            }
          } else {
            final errBody = await streamedResponse.stream.bytesToString();
            apiHataDetayi = 'HTTP ${streamedResponse.statusCode}: $errBody';
            _log(
              'CAD API yanıtı başarısız [${streamedResponse.statusCode}]: $errBody',
            );
          }
        } catch (e) {
          apiHataDetayi = '$e';
          _log('CAD API isteği esnasında hata oluştu: $e');
        }

        if (kDebugMode) {
          throw Exception(
            'Debug modunda DWG backend isteği başarısız oldu.\n'
            'Sunucu: $endpoint\n'
            'Hata Detayı: $apiHataDetayi',
          );
        }

        // --- Adım 2: API Çevrimdışı/Başarısız İse Önceden Dönüştürülmüş Yerel DXF Kontrol Et ---
        if (await kaliciDxf.exists() && await kaliciDxf.length() > 0) {
          _log(
            'API çevrimdışı veya başarısız oldu; yerel önbellekteki kaydedilmiş DXF kullanılıyor: ${kaliciDxf.path}',
          );
          await _projeyiKaydet(
            id: id,
            ad: projeAdi,
            dxfYolu: kaliciDxf.path,
            dwgYolu: cadYolu,
            dosyaBoyutu: await kaliciDxf.length(),
          );
          return kaliciDxf;
        }

        // --- Adım 3: Native LibreDWG FFI köprüsünü dene (Yerel Çevrimdışı Yedek) ---
        _log('LibreDWG FFI ile yerel dönüşüm deneniyor...');
        try {
          final geciciDxf = File(
            '${(await getTemporaryDirectory()).path}/$id.dxf',
          );
          final donustu = LibreDwgFfi.convertDwgToDxf(cadYolu, geciciDxf.path);
          if (donustu &&
              await geciciDxf.exists() &&
              await geciciDxf.length() > 0) {
            await geciciDxf.copy(kaliciDxf.path);
            _log(
              'LibreDWG FFI ile DWG dönüştürüldü ve kaydedildi: ${kaliciDxf.path}',
            );

            await _projeyiKaydet(
              id: id,
              ad: projeAdi,
              dxfYolu: kaliciDxf.path,
              dwgYolu: cadYolu,
              dosyaBoyutu: await kaliciDxf.length(),
            );

            return kaliciDxf;
          }
        } catch (e) {
          _log('LibreDWG FFI denenirken hata: $e');
        }

        // --- Adım 4: Masaüstü CLI araçlarını dene (dwg2dxf, odafileconverter) ---
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
              if (sonuc.exitCode == 0 &&
                  await geciciDxf.exists() &&
                  await geciciDxf.length() > 0) {
                await geciciDxf.copy(kaliciDxf.path);
                _log('CLI aracı ($komut) ile DWG dönüştürüldü ve kaydedildi.');

                await _projeyiKaydet(
                  id: id,
                  ad: projeAdi,
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
          'Backend CAD API isteği başarısız oldu.\n'
          'Sunucu: $endpoint\n'
          'Hata Detayı: $apiHataDetayi\n'
          'Yerel önbellek veya cihazdaki dönüştürücülerle de sonuç alınamadı.',
        );
      }

      throw Exception('Yalnızca DWG veya DXF dosyaları desteklenir.');
    } catch (e, stackTrace) {
      debugPrint('CadDonusumServisi Hatası: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Backend'den DWG dosyasını PDF olarak dönüştürür ve dosyayı döndürür.
  /// (Kullanım örneğindeki gibi MultipartFile 'file' alanı ile POST atar ve dönen PDF byte'larını kaydeder)
  Future<File> dwgDosyasiniPdfyeCevir(
    String dwgDosyaYolu, {
    String? hedefPdfYolu,
    String? apiEndpoint,
  }) async {
    final endpoint = apiEndpoint ?? endpointUrl(await apiAdresiniGetir());
    final dosyaAdi = dwgDosyaYolu.split(Platform.pathSeparator).last;

    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        dwgDosyaYolu,
        filename: dosyaAdi.toLowerCase().endsWith('.dwg')
            ? dosyaAdi
            : '$dosyaAdi.dwg',
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () =>
          throw Exception('CAD API isteği zaman aşımına uğradı (90 sn).'),
    );

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final bytes = await streamedResponse.stream.toBytes();
      if (bytes.isEmpty) {
        throw Exception('CAD API sunucusu boş PDF yanıtı döndürdü.');
      }
      File pdfDosyasi;
      if (hedefPdfYolu != null) {
        pdfDosyasi = File(hedefPdfYolu);
      } else {
        final tempDir = await getTemporaryDirectory();
        final guvenliAd = _guvenliDosyaAdi(dwgDosyaYolu);
        pdfDosyasi = File('${tempDir.path}/$guvenliAd.pdf');
      }
      await pdfDosyasi.writeAsBytes(bytes, flush: true);
      _log('PDF başarıyla kaydedildi: ${pdfDosyasi.path}');
      return pdfDosyasi;
    } else {
      final errBody = await streamedResponse.stream.bytesToString();
      throw Exception(
        'CAD API dönüştürme hatası [${streamedResponse.statusCode}]: $errBody',
      );
    }
  }

  /// DWG dosyasını doğrudan belirtilen DXF yoluna dönüştürür.
  /// (Kullanım örneğindeki gibi MultipartFile 'file' alanı ile POST atar ve dönen byte dizisini kaydeder)
  Future<File> dwgDosyasiniDxfyeDonustur({
    required String dwgFilePath,
    required String dxfSavePath,
    String? apiEndpoint,
  }) async {
    final endpoint = apiEndpoint ?? endpointUrl(await apiAdresiniGetir());
    final dosyaAdi = dwgFilePath.split(Platform.pathSeparator).last;

    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        dwgFilePath,
        filename: dosyaAdi.toLowerCase().endsWith('.dwg')
            ? dosyaAdi
            : '$dosyaAdi.dwg',
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () =>
          throw Exception('CAD API isteği zaman aşımına uğradı (90 sn).'),
    );

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final bytes = await streamedResponse.stream.toBytes();
      if (bytes.isEmpty) {
        throw Exception('CAD API sunucusu boş DXF yanıtı döndürdü.');
      }
      final hedefDosya = File(dxfSavePath);
      await hedefDosya.writeAsBytes(bytes, flush: true);
      return hedefDosya;
    } else {
      final errBody = await streamedResponse.stream.bytesToString();
      throw Exception(
        'CAD API dönüştürme hatası [${streamedResponse.statusCode}]: $errBody',
      );
    }
  }

  /// DWG'yi backend'de sahne JSON'una dönüştürür, sahneyi indirir ve DXF
  /// çıktısını yerel proje deposuna kaydeder.
  Future<CadMobileSceneSonucu> dwgDosyasiniMobilSahneyeDonustur(
    String dwgFilePath, {
    String? projeId,
  }) async {
    final source = File(dwgFilePath);
    if (!await source.exists()) {
      throw Exception('CAD dosyası bulunamadı: $dwgFilePath');
    }
    if (await source.length() > 100 * 1024 * 1024) {
      throw Exception('Dosya boyutu 100 MB sınırını aşamaz.');
    }

    final endpoint = endpointUrl(await apiAdresiniGetir());
    final deviceId = await cihazKimliginiGetir();
    final endpointUri = Uri.parse(endpoint);
    final uploadUri = endpointUri.replace(
      queryParameters: {
        ...endpointUri.queryParameters,
        'format': 'json',
        'deviceId': deviceId,
      },
    );
    final fileName = dwgFilePath.split(Platform.pathSeparator).last;
    final upload = http.MultipartRequest('POST', uploadUri)
      ..headers['x-device-id'] = deviceId
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          dwgFilePath,
          filename: fileName,
        ),
      );

    final uploadResponse = await (client?.send(upload) ?? upload.send())
        .timeout(const Duration(seconds: 90));
    final uploadBody = await uploadResponse.stream.bytesToString();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw Exception(
        'CAD sahne dönüştürme hatası [${uploadResponse.statusCode}]: '
        '$uploadBody',
      );
    }

    final Map<String, dynamic> responseData;
    try {
      final decoded = jsonDecode(uploadBody);
      if (decoded is! Map) {
        throw const FormatException('Yanıt bir JSON nesnesi değil.');
      }
      responseData = Map<String, dynamic>.from(decoded);
    } on FormatException catch (error) {
      throw FormatException('CAD API JSON yanıtı geçersiz: $error');
    }

    final sceneUrl = responseData['mobileSceneUrl'];
    final downloadUrl = responseData['downloadUrl'];
    if (sceneUrl is! String || sceneUrl.isEmpty) {
      throw const FormatException(
        'CAD API yanıtında mobileSceneUrl alanı bulunamadı.',
      );
    }
    if (downloadUrl is! String || downloadUrl.isEmpty) {
      throw const FormatException(
        'CAD API yanıtında downloadUrl alanı bulunamadı.',
      );
    }

    final apiBaseUri = _apiBaseUri(endpointUri);
    final sceneUri = apiBaseUri.resolve(sceneUrl);
    final sceneResponse = await _get(
      sceneUri,
      deviceId,
    ).timeout(const Duration(seconds: 90));
    if (sceneResponse.statusCode < 200 || sceneResponse.statusCode >= 300) {
      throw Exception(
        'CAD sahnesi indirilemedi [${sceneResponse.statusCode}]: '
        '${sceneResponse.body}',
      );
    }
    final scene = await CadMobileScene.decodeBytes(sceneResponse.bodyBytes);

    final dxfUri = apiBaseUri.resolve(downloadUrl);
    final dxfResponse = await _get(
      dxfUri,
      deviceId,
    ).timeout(const Duration(seconds: 90));
    if (dxfResponse.statusCode < 200 || dxfResponse.statusCode >= 300) {
      throw Exception(
        'DXF çıktısı indirilemedi [${dxfResponse.statusCode}]: '
        '${dxfResponse.body}',
      );
    }
    if (dxfResponse.bodyBytes.isEmpty) {
      throw Exception('CAD API boş DXF çıktısı döndürdü.');
    }

    final projectId = projeId ?? await _dosyaKimlikOlustur(source);
    final projectName = await _kayitliProjeAdiniBul(projectId) ?? fileName;
    final projectsDir = await _projelerDizini();
    final savedDxf = File('${projectsDir.path}/$projectId.dxf');
    final savedDwg = File('${projectsDir.path}/$projectId.dwg');
    final savedScene = File('${projectsDir.path}/$projectId.scene.json');
    await savedDxf.writeAsBytes(dxfResponse.bodyBytes, flush: true);
    await savedScene.writeAsBytes(sceneResponse.bodyBytes, flush: true);
    if (source.path != savedDwg.path && !await savedDwg.exists()) {
      await source.copy(savedDwg.path);
    }
    await _projeyiKaydet(
      id: projectId,
      ad: projectName,
      dxfYolu: savedDxf.path,
      dwgYolu: savedDwg.path,
      sahneYolu: savedScene.path,
      dosyaBoyutu: dxfResponse.bodyBytes.length,
    );

    return CadMobileSceneSonucu(scene: scene, dxfFile: savedDxf);
  }

  Uri _apiBaseUri(Uri endpointUri) {
    var path = endpointUri.path;
    for (final suffix in ['/api/cad/convert', '/convert']) {
      if (path.endsWith(suffix)) {
        path = path.substring(0, path.length - suffix.length);
        break;
      }
    }
    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';
    return endpointUri.replace(path: path, query: null, fragment: null);
  }

  Future<http.Response> _get(Uri uri, String deviceId) {
    final headers = {'x-device-id': deviceId};
    return client?.get(uri, headers: headers) ??
        http.get(uri, headers: headers);
  }

  /// Backend'e DWG gönderip dönen formatı (DXF / PDF) başlık veya MIME türünden okuyarak ayırt eder.
  Future<CadDonusumSonucu> cadDosyasiniDonustur(
    String dwgFilePath, {
    String? apiEndpoint,
  }) async {
    final endpoint = apiEndpoint ?? endpointUrl(await apiAdresiniGetir());
    final dosyaAdi = dwgFilePath.split(Platform.pathSeparator).last;

    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        dwgFilePath,
        filename: dosyaAdi.toLowerCase().endsWith('.dwg')
            ? dosyaAdi
            : '$dosyaAdi.dwg',
      ),
    );

    final response = await request.send().timeout(
      const Duration(seconds: 90),
      onTimeout: () =>
          throw Exception('CAD API isteği zaman aşımına uğradı (90 sn).'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 1. Backend'in döndüğü formatı başlık veya MIME türünden okuyun
      final cadFormat =
          response.headers['x-cad-format'] ??
          (response.headers['content-type']?.contains('pdf') == true
              ? 'pdf'
              : 'dxf');
      final bytes = await response.stream.toBytes();

      if (bytes.isEmpty) {
        throw Exception('CAD API sunucusu boş yanıt döndürdü.');
      }

      final isMagicPdf =
          bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46; // %PDF

      final effectiveFormat = (cadFormat == 'pdf' || isMagicPdf)
          ? 'pdf'
          : 'dxf';

      final tempDir = await getTemporaryDirectory();
      final guvenliAd = _guvenliDosyaAdi(dwgFilePath);
      final hedefDosya = File('${tempDir.path}/$guvenliAd.$effectiveFormat');
      await hedefDosya.writeAsBytes(bytes, flush: true);

      return CadDonusumSonucu(
        dosya: hedefDosya,
        format: effectiveFormat,
        bytes: bytes,
      );
    } else {
      final errBody = await response.stream.bytesToString();
      throw Exception(
        'CAD API dönüştürme hatası [${response.statusCode}]: $errBody',
      );
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
