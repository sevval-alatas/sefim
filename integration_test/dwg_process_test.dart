// import 'dart:io';
//
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:path_provider/path_provider.dart';
//
// /// Bu test iOS simülatöründe dart:io Process ile Mac'teki dwg2dxf
// /// aracının çağrılıp çağrılamadığını doğrular.
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   testWidgets('simülatörde Process.run çalışıyor mu', (tester) async {
//     await tester.pumpWidget(const SizedBox());
//
//     // 1) Basit bir process çağrısı
//     final echo = await Process.run('/bin/echo', ['merhaba']);
//     // ignore: avoid_print
//     print('ECHO exit=${echo.exitCode} out=${echo.stdout}');
//     expect(echo.exitCode, 0);
//
//     // 2) Örnek DWG'yi geçici dizine yaz
//     final data = await rootBundle.load('integration_test/assets/dwgDeneme.dwg');
//     final dir = await getTemporaryDirectory();
//     final dwg = File('${dir.path}/ornek.dwg');
//     await dwg.writeAsBytes(data.buffer.asUint8List(), flush: true);
//
//     // 3) dwg2dxf ile gerçek dönüşüm
//     final cikis = File('${dir.path}/ornek.dxf');
//     final sonuc = await Process.run('/opt/homebrew/bin/dwg2dxf', [
//       '-y',
//       '--as',
//       'r2000',
//       '-o',
//       cikis.path,
//       dwg.path,
//     ]);
//     // ignore: avoid_print
//     print('DWG2DXF exit=${sonuc.exitCode}\nstdout=${sonuc.stdout}\nstderr=${sonuc.stderr}');
//
//     expect(sonuc.exitCode, 0);
//     expect(await cikis.exists(), isTrue);
//     expect(await cikis.length(), greaterThan(1000));
//     // ignore: avoid_print
//     print('DXF üretildi: ${cikis.path} (${await cikis.length()} bayt)');
//   }, timeout: const Timeout(Duration(minutes: 3)));
// }
