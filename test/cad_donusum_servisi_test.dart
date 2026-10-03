import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    PathProviderPlatform.instance =
        MockPathProviderPlatform(tempDir.path, docDir.path);

    servis = CadDonusumServisi();
  });

  tearDown(() async {
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
    expect(yeniProje.dosyaBoyutu, 2048);
  });

  test('API adresi okuma, güncelleme ve varsayılan değer mantığı çalışıyor', () async {
    final defaultUrl = await servis.apiAdresiniGetir();
    expect(defaultUrl, isNotEmpty);

    const yeniUrl = 'http://192.168.1.100:8000';
    await servis.apiAdresiniGuncelle(yeniUrl);

    final okunanUrl = await servis.apiAdresiniGetir();
    expect(okunanUrl, yeniUrl);
  });

  test('DXF dosyası açıldığında yerel projeler arasına kaydedilir', () async {
    final ornekDxf = File('${tempDir.path}/test_proje.dxf');
    await ornekDxf.writeAsString('0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n');

    final sonucDxf = await servis.dxfyeDonustur(ornekDxf.path);
    expect(await sonucDxf.exists(), isTrue);

    final kayitliList = await servis.kayitliProjeleriGetir();
    expect(kayitliList.length, 1);
    expect(kayitliList.first.ad, 'test_proje.dxf');
  });

  test('Kayıtlı proje silme işlemi yerel depolamadan dosyayı kaldırır', () async {
    final ornekDxf = File('${tempDir.path}/silinecek.dxf');
    await ornekDxf.writeAsString('0\nSECTION\n2\nENTITIES\n0\nENDSEC\n0\nEOF\n');

    await servis.dxfyeDonustur(ornekDxf.path);
    var list = await servis.kayitliProjeleriGetir();
    expect(list.length, 1);

    final silinecekId = list.first.id;
    await servis.kayitliProjeyiSil(silinecekId);

    list = await servis.kayitliProjeleriGetir();
    expect(list, isEmpty);
  });
}
