import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefim/servis/cad_mobil_sahnesi.dart';
import 'package:sefim/widget/cad_sahne_goruntuleyici.dart';
import 'package:sefim/widget/dxf_goruntuleyici.dart';

const _ornekDxf = '''
  0
SECTION
  2
ENTITIES
  0
LINE
  8
0
 10
0.0
 20
0.0
 11
50000.0
 21
0.0
  0
LWPOLYLINE
  8
0
 70
1
 10
1000.0
 20
1000.0
 10
40000.0
 20
1000.0
 10
40000.0
 20
30000.0
 10
1000.0
 20
30000.0
  0
ARC
  8
0
 10
20000.0
 20
15000.0
 40
5000.0
 50
0.0
 51
180.0
  0
ELLIPSE
  8
0
 10
30000.0
 20
15000.0
 11
3000.0
 21
0.0
 40
0.5
  0
POLYLINE
  8
0
 70
1
  0
VERTEX
  8
0
 10
45000.0
 20
5000.0
  0
VERTEX
  8
0
 10
48000.0
 20
5000.0
  0
VERTEX
  8
0
 10
48000.0
 20
10000.0
  0
SEQEND
  0
TEXT
  8
0
 10
5000.0
 20
20000.0
 40
250.0
  1
KOLON P1
  0
ENDSEC
  0
EOF
''';

void main() {
  test('gerçekçi DXF içeriği tüm varlık tipleriyle parse edilir', () {
    final entities = DxfParser.parse(_ornekDxf);

    final cizgi = entities.whereType<DxfLine>().length;
    final kapalilar = entities.whereType<DxfPolyline>().toList();
    final metinler = entities.whereType<DxfText>().length;

    expect(cizgi, 1, reason: '1 LINE bekleniyor');
    // LWPOLYLINE + ARC + ELLIPSE + eski POLYLINE = 4 polyline
    expect(kapalilar.length, 4, reason: '4 polyline bekleniyor');
    expect(metinler, 1, reason: '1 TEXT bekleniyor');

    // ARC yaklaşımı doğru merkez etrafında mı?
    final yay = kapalilar[1];
    for (final p in yay.points) {
      final mesafe = (p - const Offset(20000, 15000)).distance;
      expect(mesafe, closeTo(5000, 1));
    }

    // Eski tip POLYLINE 3 köşeli ve kapalı olmalı
    final eski = kapalilar.last;
    expect(eski.points.length, 3);
    expect(eski.closed, isTrue);
  });

  testWidgets('görüntüleyici CustomPaint boyutunu ekrana eşitler', (
    tester,
  ) async {
    final entities = DxfParser.parse(_ornekDxf);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DxfGoruntuleyici(entities: entities)),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DxfGoruntuleyici),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter != null && w.size != Size.zero,
        ),
      ),
    );
    final govde = tester.getSize(find.byType(Scaffold));
    // Çizim alanı viewport ile aynı boyutta olmalı ki çizim ekranda
    // ortalansın (eski sabit 1200x800 hatası geri gelmemeli).
    expect(paint.size, govde);
    expect(paint.size, isNot(const Size(1200, 800)));
  });

  test('birleşik sınırlar mm ölçeğinde mantıklı fit ölçeği üretir', () {
    final entities = DxfParser.parse(_ornekDxf);
    var bounds = entities.first.bounds;
    for (final e in entities.skip(1)) {
      bounds = bounds.expandToInclude(e.bounds);
    }
    const ekran = Size(1200, 800);
    final scale = math.min(
      (ekran.width - 64) / bounds.width,
      (ekran.height - 64) / bounds.height,
    );
    // mm ölçeğinde ölçek çok küçük olur; çizgi kalınlığı telafi edilmeli.
    expect(scale, lessThan(0.05));
    final gorunenKalinlik = 2.0 * (1.0 / scale) * scale;
    expect(gorunenKalinlik, closeTo(2.0, 1e-9));
  });

  testWidgets('DxfGoruntuleyici normal çizgi kalınlığını varsayılan seçer', (
    tester,
  ) async {
    final entities = DxfParser.parse(_ornekDxf);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DxfGoruntuleyici(entities: entities)),
      ),
    );

    // Çizgi kalınlığı butonu mevcut olmalı
    expect(find.byIcon(Icons.line_weight_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.line_weight_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Saç Teli (0.0 px)'), findsOneWidget);
    expect(find.text('Çok İnce (0.4 px)'), findsOneWidget);
    expect(find.text('İnce (0.8 px)'), findsOneWidget);
    expect(find.text('Normal (1.2 px)'), findsOneWidget);
    expect(
      tester
          .widget<CheckedPopupMenuItem<double>>(
            find.ancestor(
              of: find.text('Normal (1.2 px)'),
              matching: find.byType(CheckedPopupMenuItem<double>),
            ),
          )
          .checked,
      isTrue,
    );
  });

  testWidgets('JSON CAD sahnesi katmanları ve dönüşüm uyarılarını gösterir', (
    tester,
  ) async {
    final scene = CadMobileScene.fromJson({
      'extents': {
        'min': [0, 0],
        'max': [100, 100],
      },
      'layers': [
        {'name': 'Walls', 'visible': true, 'frozen': false},
        {'name': 'Frozen', 'visible': true, 'frozen': true},
      ],
      'entities': [
        {
          'type': 'LINE',
          'layer': 'Walls',
          'start': [0, 0],
          'end': [100, 100],
        },
        {
          'type': 'CIRCLE',
          'layer': 'Walls',
          'center': [50, 50],
          'radius': 10,
          'trueColor': 'FF0000',
        },
        {
          'type': 'ARC',
          'layer': 'Walls',
          'center': [50, 50],
          'radius': 5,
          'startAngle': 0,
          'endAngle': 90,
        },
        {
          'type': 'LWPOLYLINE',
          'layer': 'Walls',
          'points': [
            [0, 0],
            [10, 0],
            [10, 10],
          ],
          'closed': true,
        },
        {
          'type': 'TEXT',
          'layer': 'Walls',
          'position': [20, 20],
          'text': 'Room A',
          'height': 2,
        },
        {
          'type': 'LINE',
          'layer': 'Frozen',
          'start': [0, 0],
          'end': [1, 1],
        },
      ],
      'warnings': ['Metin biçimlendirmesi sadeleştirildi.'],
      'unsupportedEntities': ['ACAD_PROXY_ENTITY'],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CadSahneGoruntuleyici(scene: scene)),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Yakınlaştır'), findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(
      find.descendant(
        of: find.byType(CadSahneGoruntuleyici),
        matching: find.byType(InteractiveViewer),
      ),
    );
    final controller = viewer.transformationController!;
    await tester.tap(find.byTooltip('Yakınlaştır'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));

    await tester.tap(find.byTooltip('Çizimi ekrana sığdır'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), 1);

    expect(find.text('Katmanlar'), findsOneWidget);
    await tester.tap(find.text('Katmanlar'));
    await tester.pumpAndSettle();
    expect(find.text('Dondurulmuş'), findsOneWidget);
    expect(find.text('1 desteklenmeyen nesne'), findsOneWidget);
    await tester.tap(find.text('1 desteklenmeyen nesne'));
    await tester.pumpAndSettle();
    expect(find.text('Metin biçimlendirmesi sadeleştirildi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
