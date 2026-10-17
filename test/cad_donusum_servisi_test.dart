import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Color, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sefim/servis/api_config.dart';
import 'package:sefim/servis/cad_donusum_servisi.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  final String docPath;

  MockPathProviderPlatform(this.tempPath, this.docPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docPath;
}

void main() {
  late Directory tempDir;
  late Directory docDir;
  late CadDonusumServisi servis;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    tempDir = await Directory.systemTemp.createTemp('sefim_test_temp_');
    docDir = await Directory.systemTemp.createTemp('sefim_test_doc_');

    PathProviderPlatform.instance = MockPathProviderPlatform(
      tempDir.path,
      docDir.path,
    );

    servis = CadDonusumServisi();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await docDir.exists()) await docDir.delete(recursive: true);
  });

  test('KayitliProje JSON dönüşümü ve alan eşlemesi doğru çalışıyor', () {
    final proje = KayitliProje(
      id: 'test_id_123',
      ad: 'ornek_proje.dwg',
      dxfYolu: '/path/to/ornek.dxf',
      dwgYolu: '/path/to/ornek.dwg',
      kayitTarihi: DateTime(2026, 10, 3, 23, 30),
      dosyaBoyutu: 2048,
    );

    final json = proje.toJson();
    final yeniProje = KayitliProje.fromJson(json);

    expect(yeniProje.id, 'test_id_123');
    expect(yeniProje.ad, 'ornek_proje.dwg');
    expect(yeniProje.dxfYolu, '/path/to/ornek.dxf');
    expect(yeniProje.goruntulemeYolu, '/path/to/ornek.dxf');
    expect(yeniProje.dosyaBoyutu, 2048);
  });

  test('KayitliProje PDF yolu ve goruntulemeYolu dogru calisiyor', () {
    final pdfProje = KayitliProje(
      id: 'pdf_id_456',
      ad: 'statik_proje.dwg',
      pdfYolu: '/path/to/statik.pdf',
      kayitTarihi: DateTime(2026, 10, 14, 10, 0),
      dosyaBoyutu: 4096,
    );

    expect(pdfProje.pdfMi, isTrue);
    expect(pdfProje.goruntulemeYolu, '/path/to/statik.pdf');
    expect(pdfProje.dxfYolu, '/path/to/statik.pdf');

    final json = pdfProje.toJson();
    final parsed = KayitliProje.fromJson(json);
    expect(parsed.pdfYolu, '/path/to/statik.pdf');
    expect(parsed.pdfMi, isTrue);
  });

  test(
    'API adresi okuma, güncelleme ve varsayılan değer mantığı çalışıyor',
    () async {
      final defaultUrl = await servis.apiAdresiniGetir();
      expect(defaultUrl, CadDonusumServisi.varsayilanApiUrl());
      expect(defaultUrl, 'http://localhost:3000/api/cad/convert');

      const yeniUrl = 'http://192.168.1.100:3000';
      await servis.apiAdresiniGuncelle(yeniUrl);

      final okunanUrl = await servis.apiAdresiniGetir();
      expect(okunanUrl, yeniUrl);

      await servis.apiAdresiniSifirla();
      final sifirlananUrl = await servis.apiAdresiniGetir();
      expect(sifirlananUrl, CadDonusumServisi.varsayilanApiUrl());
    },
  );

  test('endpointUrl helper metodu adresi doğru şekilde normalize eder', () {
    expect(
      CadDonusumServisi.endpointUrl('http://localhost:3000'),
      'http://localhost:3000/api/cad/convert',
    );
    expect(
      CadDonusumServisi.endpointUrl('http://localhost:3000/'),
      'http://localhost:3000/api/cad/convert',
    );
    expect(
      CadDonusumServisi.endpointUrl('http://localhost:3000/api/cad/convert'),
      'http://localhost:3000/api/cad/convert',
    );
    expect(
      CadDonusumServisi.endpointUrl('http://localhost:3000/api/docs'),
      'http://localhost:3000/api/cad/convert',
    );
    expect(
      CadDonusumServisi.endpointUrl('http://localhost:3000/api/docs/'),
      'http://localhost:3000/api/cad/convert',
    );
  });

  test('eski CAD sunucusu tercihi yeni API adresine taşınır', () async {
    SharedPreferences.setMockInitialValues({
      'cad_api_base_url': 'https://cad.sefimbackend/api/cad/convert',
    });

    expect(
      await servis.apiAdresiniGetir(),
      'http://localhost:3000/api/cad/convert',
    );
  });

  test('cihaz kimliği yeniden oluşturulmadan kalıcı olarak saklanır', () async {
    final firstId = await servis.cihazKimliginiGetir();
    final secondId = await CadDonusumServisi().cihazKimliginiGetir();

    expect(firstId, hasLength(32));
    expect(firstId, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(secondId, firstId);
  });

  test(
    'DWG isteği yeni API sözleşmesindeki cihaz kimliğini gönderir',
    () async {
      late Uri receivedUri;
      late String receivedDeviceId;
      final client = MockClient((request) async {
        receivedUri = request.url;
        receivedDeviceId = request.headers['x-device-id'] ?? '';
        return http.Response(
          '0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n',
          HttpStatus.ok,
          headers: {'content-type': 'application/dxf', 'x-cad-format': 'dxf'},
        );
      });
      addTearDown(client.close);

      await servis.apiAdresiniGuncelle('http://localhost:3000/api/cad/convert');
      final dwg = File('${tempDir.path}/ornek.dwg');
      await dwg.writeAsBytes([1, 2, 3, 4]);
      final requestServisi = CadDonusumServisi(client: client);

      final result = await requestServisi.dxfyeDonustur(dwg.path);
      final deviceId = await requestServisi.cihazKimliginiGetir();

      expect(await result.exists(), isTrue);
      expect(receivedUri.path, '/api/cad/convert');
      expect(receivedUri.queryParameters['format'], 'dxf');
      expect(receivedUri.queryParameters['deviceId'], deviceId);
      expect(receivedDeviceId, deviceId);
    },
  );

  test('DWG JSON sahnesi ve DXF göreli bağlantılardan indirilir', () async {
    final requests = <http.Request>[];
    final sceneJson = jsonEncode({
      'schema': 'sefim-cad-scene/1',
      'units': 'mm',
      'extents': {
        'min': [0, 0],
        'max': [100, 50],
      },
      'layers': [
        {'name': 'Walls', 'visible': true, 'frozen': false, 'color': 1},
        {'name': 'Hidden', 'visible': true, 'frozen': true},
      ],
      'blocks': {
        'Door': {
          'entities': [
            {
              'type': 'LINE',
              'start': [0, 0],
              'end': [1, 1],
            },
          ],
        },
      },
      'entities': [
        {
          'type': 'LINE',
          'layer': 'Walls',
          'start': [1, 2],
          'end': [10, 20],
          'trueColor': '#123456',
        },
      ],
      'warnings': ['Bir nesne yaklaşık olarak dönüştürüldü.'],
      'unsupportedEntities': ['ACAD_PROXY_ENTITY'],
    });
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST') {
        expect(request.url.queryParameters['format'], 'json');
        expect(request.headers['x-device-id'], isNotEmpty);
        return http.Response(
          jsonEncode({
            'mobileSceneUrl': 'api/cad/scenes/job-1.json',
            'downloadUrl': 'api/cad/download/job-1.dxf',
          }),
          HttpStatus.created,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('.json')) {
        return http.Response(
          sceneJson,
          HttpStatus.ok,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n',
        HttpStatus.ok,
        headers: {'content-type': 'application/dxf'},
      );
    });
    addTearDown(client.close);

    await servis.apiAdresiniGuncelle('http://localhost:3000/api/cad/convert');
    final source = File('${tempDir.path}/scene.dwg');
    await source.writeAsBytes([1, 2, 3, 4]);
    final requestService = CadDonusumServisi(client: client);

    final result = await requestService.dwgDosyasiniMobilSahneyeDonustur(
      source.path,
    );

    expect(requests, hasLength(3));
    expect(
      requests[1].url,
      Uri.parse('http://localhost:3000/api/cad/scenes/job-1.json'),
    );
    expect(
      requests[2].url,
      Uri.parse('http://localhost:3000/api/cad/download/job-1.dxf'),
    );
    expect(requests[1].headers['x-device-id'], isNotEmpty);
    expect(result.scene.schema, 'sefim-cad-scene/1');
    expect(result.scene.units, 'mm');
    expect(result.scene.extents, const Rect.fromLTRB(0, 0, 100, 50));
    expect(result.scene.layers, hasLength(2));
    expect(result.scene.blocks.single.name, 'Door');
    expect(result.scene.entities.single.trueColor, const Color(0xFF123456));
    expect(result.scene.warnings, ['Bir nesne yaklaşık olarak dönüştürüldü.']);
    expect(result.scene.unsupportedEntities, ['ACAD_PROXY_ENTITY']);
    expect(await result.dxfFile.exists(), isTrue);
    expect(await result.dxfFile.readAsString(), contains('ENTITIES'));
  });

  test(
    'debug modunda önceden dönüştürülmüş DWG yine backend isteği yapar',
    () async {
      var requestCount = 0;
      const backendDxf = 'backend-dxf';
      final client = MockClient((request) async {
        requestCount++;
        return http.Response(
          backendDxf,
          HttpStatus.ok,
          headers: {'content-type': 'application/dxf', 'x-cad-format': 'dxf'},
        );
      });
      addTearDown(client.close);

      await servis.apiAdresiniGuncelle('http://localhost:3000/api/cad/convert');
      final sourceDwg = File('${tempDir.path}/cached.dwg');
      await sourceDwg.writeAsBytes([1, 2, 3, 4]);
      final project = await servis.projeyiKaliciKaydet(sourceDwg.path);
      await File('${docDir.path}/sefim_projeler/${project.id}.dxf')
          .writeAsString('stale-local-dxf');

      final requestService = CadDonusumServisi(client: client);
      final result = await requestService.dxfyeDonustur(
        project.goruntulemeYolu,
        projeId: project.id,
      );

      expect(requestCount, 1);
      expect(await result.readAsString(), backendDxf);
    },
  );

  test('debug modunda backend hatası yerel cache ile gizlenmez', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('conversion failed', HttpStatus.badGateway);
    });
    addTearDown(client.close);

    await servis.apiAdresiniGuncelle('http://localhost:3000/api/cad/convert');
    final sourceDwg = File('${tempDir.path}/cached_failure.dwg');
    await sourceDwg.writeAsBytes([1, 2, 3, 4]);
    final project = await servis.projeyiKaliciKaydet(sourceDwg.path);
    await File('${docDir.path}/sefim_projeler/${project.id}.dxf')
        .writeAsString('stale-local-dxf');

    final requestService = CadDonusumServisi(client: client);
    await expectLater(
      requestService.dxfyeDonustur(
        project.goruntulemeYolu,
        projeId: project.id,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Debug modunda DWG backend isteği başarısız oldu'),
        ),
      ),
    );
    expect(requestCount, 1);
  });

  test('DXF dosyası açıldığında yerel projeler arasına kaydedilir', () async {
    final ornekDxf = File('${tempDir.path}/test_proje.dxf');
    await ornekDxf.writeAsString(
      '0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n',
    );

    final sonucDxf = await servis.dxfyeDonustur(ornekDxf.path);
    expect(await sonucDxf.exists(), isTrue);

    final kayitliList = await servis.kayitliProjeleriGetir();
    expect(kayitliList.length, 1);
    expect(kayitliList.first.ad, 'test_proje.dxf');
  });

  test(
    'Yüklenen proje yeniden başlatma sonrasında kalıcı olarak bulunur',
    () async {
      final kaynakPdf = File('${tempDir.path}/mimari_proje.pdf');
      final pdfIcerigi = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37];
      await kaynakPdf.writeAsBytes(pdfIcerigi);

      final kaydedilen = await servis.projeyiKaliciKaydet(kaynakPdf.path);
      expect(kaydedilen.goruntulemeYolu, isNot(kaynakPdf.path));
      expect(
        kaydedilen.goruntulemeYolu,
        startsWith('${docDir.path}/sefim_projeler/'),
      );

      await kaynakPdf.delete();
      final yenidenBaslatilanServis = CadDonusumServisi();
      final acilisSonrasiProjeler = await yenidenBaslatilanServis
          .kayitliProjeleriGetir();

      expect(acilisSonrasiProjeler, hasLength(1));
      expect(acilisSonrasiProjeler.single.ad, 'mimari_proje.pdf');
      expect(acilisSonrasiProjeler.single.pdfMi, isTrue);
      expect(
        await File(acilisSonrasiProjeler.single.goruntulemeYolu).readAsBytes(),
        pdfIcerigi,
      );
    },
  );

  test('Kalıcı kopyadan DXF dönüşümü aynı kayıtlı projeyi günceller', () async {
    final kaynakDxf = File('${tempDir.path}/plan.dxf');
    await kaynakDxf.writeAsString(
      '0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n',
    );

    final proje = await servis.projeyiKaliciKaydet(kaynakDxf.path);
    await servis.dxfyeDonustur(
      proje.goruntulemeYolu,
      zorlaYenidenDonustur: true,
      projeId: proje.id,
    );

    final projeler = await servis.kayitliProjeleriGetir();
    expect(projeler, hasLength(1));
    expect(projeler.single.id, proje.id);
    expect(projeler.single.ad, 'plan.dxf');
  });

  test(
    'Kayıtlı proje silme işlemi yerel depolamadan dosyayı kaldırır',
    () async {
      final ornekDxf = File('${tempDir.path}/silinecek.dxf');
      await ornekDxf.writeAsString(
        '0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n',
      );

      await servis.dxfyeDonustur(ornekDxf.path);
      var list = await servis.kayitliProjeleriGetir();
      expect(list.length, 1);

      final silinecekId = list.first.id;
      await servis.kayitliProjeyiSil(silinecekId);

      list = await servis.kayitliProjeleriGetir();
      expect(list, isEmpty);
    },
  );

  test('CadDonusumSonucu model format ve metodları doğru çalışır', () {
    final pdfSonuc = CadDonusumSonucu(
      dosya: File('proje.pdf'),
      format: 'pdf',
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
    );
    expect(pdfSonuc.pdfMi, isTrue);
    expect(pdfSonuc.dxfMi, isFalse);
    expect(pdfSonuc.format, 'pdf');

    final dxfSonuc = CadDonusumSonucu(
      dosya: File('proje.dxf'),
      format: 'dxf',
      bytes: Uint8List.fromList([0x30, 0x0A]),
    );
    expect(dxfSonuc.dxfMi, isTrue);
    expect(dxfSonuc.pdfMi, isFalse);
    expect(dxfSonuc.format, 'dxf');
  });

  test(
    'ApiConfig .env iceriginden tum endpoint adreslerini tek merkezden uretir',
    () {
      ApiConfig.iceriktenYukle('API_BASE_URL=https://ornek-sunucu.com/\n');
      expect(ApiConfig.baseUrl, 'https://ornek-sunucu.com');
      expect(
        ApiConfig.cadConvertUrl,
        'https://ornek-sunucu.com/api/cad/convert',
      );
      expect(ApiConfig.authUrl, 'https://ornek-sunucu.com/auth');
      expect(ApiConfig.santiyeUrl, 'https://ornek-sunucu.com/santiye');
      expect(
        ApiConfig.deliveryNotesUrl,
        'https://ornek-sunucu.com/delivery-notes',
      );
      expect(
        ApiConfig.columnAnalyzeUrl,
        'https://ornek-sunucu.com/column/analyze',
      );
      expect(
        CadDonusumServisi.varsayilanApiUrl(),
        'https://ornek-sunucu.com/api/cad/convert',
      );

      ApiConfig.iceriktenYukle('API_BASE_URL=http://localhost:3000/api/docs\n');
      expect(ApiConfig.baseUrl, 'http://localhost:3000');
      expect(ApiConfig.cadConvertUrl, 'http://localhost:3000/api/cad/convert');
      expect(ApiConfig.authUrl, 'http://localhost:3000/auth');

      // Varsayılan değere geri yükle
      ApiConfig.iceriktenYukle('API_BASE_URL=http://localhost:3000\n');
    },
  );

  test(
    'Hive uzerindeki projeler fiziksel dosya silinse bile kullanici silene kadar silinmez ve Hive yedeginden geri yuklenir',
    () async {
      final kaynakDxf = File('${tempDir.path}/kalici_proje.dxf');
      const dxfIcerik = '0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n';
      await kaynakDxf.writeAsString(dxfIcerik);

      final kaydedilen = await servis.projeyiKaliciKaydet(kaynakDxf.path);
      final fizikselDosya = File(kaydedilen.goruntulemeYolu);
      expect(await fizikselDosya.exists(), isTrue);

      // Fiziksel dosya dışarıdan silinse bile proje Hive'da kalmalı ve içerik kurtarılmalı
      await fizikselDosya.delete();
      expect(await fizikselDosya.exists(), isFalse);

      final projeler = await servis.kayitliProjeleriGetir();
      expect(projeler, hasLength(1));
      expect(projeler.single.id, kaydedilen.id);
      expect(projeler.single.ad, 'kalici_proje.dxf');
      expect(await File(projeler.single.goruntulemeYolu).exists(), isTrue);
      expect(
        await File(projeler.single.goruntulemeYolu).readAsString(),
        dxfIcerik,
      );

      // Yalnızca kullanıcı kayitliProjeyiSil çağırdığında silinmeli
      await servis.kayitliProjeyiSil(kaydedilen.id);
      expect(await servis.kayitliProjeleriGetir(), isEmpty);
    },
  );
}
