// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.
//
// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//
//
import 'package:sefim/servis/irsaliye_verisi.dart';
import 'package:sefim/servis/ocr_ayiklama_servisi.dart';
import 'package:sefim/widget/dxf_goruntuleyici.dart';

void main() {
  group('OcrAyiklamaServisi', () {
    test('standart irsaliye alanlarını ayıklar', () {
      const metin = '''
E-Irsaliye No: BCE2026000003093
27.03.2026 12.55
Mikser Plaka: 34 ABC 123
Beton Miktarı: 5.5 m3
C35
''';

      final veri = OcrAyiklamaServisi.metindenVerileriAyikla(metin);

      expect(veri.irsaliyeNo, 'BCE2026000003093');
      expect(veri.tarih, '27-03-2026');
      expect(veri.zaman, '12:55');
      expect(veri.plaka, '34 ABC 123');
      expect(veri.uretimMiktari, '5.5');
      expect(veri.dayanim, 'C35');
      expect(veri.guvenSkorlari['irsaliyeNo'], greaterThan(0.9));
      expect(veri.kontrolUyarilari, isEmpty);
    });

    test('eksik ve geçersiz alanları işaretler', () {
      final veri = IrsaliyeVerisi(plaka: 'ABC');

      expect(veri.kontrolUyarilari, contains('İrsaliye No okunamadı'));
      expect(veri.kontrolUyarilari, contains('Tarih okunamadı'));
      expect(veri.kontrolUyarilari, contains('Plaka biçimini kontrol edin'));
    });
  });

  test('DXF TEXT ve MTEXT entitylerini parse eder', () {
    const dxf = '''
0
SECTION
2
ENTITIES
0
TEXT
10
10
20
20
40
2.5
1
Baslik
0
MTEXT
10
30
20
40
40
3
3
Satir 1
1
\\PSatir 2
0
ENDSEC
0
EOF
''';

    final entityler = DxfParser.parse(dxf);

    expect(entityler, hasLength(2));
    expect(entityler.whereType<DxfText>().map((entity) => entity.text), [
      'Baslik',
      'Satir 1\nSatir 2',
    ]);
  });
}
// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());
//
//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);
//
//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();
//
//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }
