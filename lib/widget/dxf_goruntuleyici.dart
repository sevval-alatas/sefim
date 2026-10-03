import 'dart:math' as math;
import 'package:flutter/material.dart';

/// AutoCAD Standart İndeks Renkleri (Group Code 62)
Color _dxfRengiBul(int colorCode, {Color defaultColor = Colors.white}) {
  switch (colorCode) {
    case 1:
      return const Color(0xFFFF3333); // Kırmızı
    case 2:
      return const Color(0xFFFFFF00); // Sarı
    case 3:
      return const Color(0xFF00FF00); // Yeşil
    case 4:
      return const Color(0xFF00FFFF); // Cyan (Açık Mavi)
    case 5:
      return const Color(0xFF3366FF); // Mavi
    case 6:
      return const Color(0xFFFF00FF); // Magenta (Eflatun)
    case 7:
      return Colors.white; // Beyaz/Siyah (Koyu temada Beyaz)
    case 8:
      return const Color(0xFF808080); // Koyu Gri
    case 9:
      return const Color(0xFFC0C0C0); // Açık Gri
    default:
      if (colorCode > 9 && colorCode <= 255) {
        // Halka renk hesabı
        final hue = ((colorCode % 10) * 36) % 360;
        return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.8, 0.6).toColor();
      }
      return defaultColor;
  }
}

class _DxfPair {
  _DxfPair(this.code, this.value);
  final int code;
  final String value;
}

abstract class DxfEntity {
  Rect get bounds;
  Color? get color;

  void draw(Canvas canvas, Paint defaultPaint, {double inverseScale = 1});

  /// Blok yerleştirmelerinde (INSERT) varlığı döndürme ve ölçekleme
  DxfEntity transform(Offset offset, double scaleX, double scaleY, double rotationRad);
}

class DxfBlock {
  DxfBlock(this.name, this.basePoint, this.entities);
  final String name;
  final Offset basePoint;
  final List<DxfEntity> entities;
}

class DxfParser {
  static List<DxfEntity> parse(String content) {
    final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final pairs = <_DxfPair>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final code = int.tryParse(line);
      if (code != null && i + 1 < lines.length) {
        final val = lines[i + 1].trim();
        pairs.add(_DxfPair(code, val));
        i++;
      }
    }

    final entities = <DxfEntity>[];
    final blocks = <String, DxfBlock>{};

    var inEntities = false;
    var inBlocks = false;
    String? currentBlockName;
    Offset currentBlockBase = Offset.zero;
    List<DxfEntity>? currentBlockEntities;

    var oldPolylinePoints = <Offset>[];
    var oldPolylineClosed = false;
    var insideOldPolyline = false;
    Color? oldPolylineColor;

    for (var i = 0; i < pairs.length; i++) {
      final p = pairs[i];

      if (p.code == 0) {
        final type = p.value.toUpperCase();

        if (type == 'SECTION') {
          if (i + 1 < pairs.length && pairs[i + 1].code == 2) {
            final secName = pairs[i + 1].value.toUpperCase();
            if (secName == 'BLOCKS') inBlocks = true;
            if (secName == 'ENTITIES') inEntities = true;
          }
          continue;
        }

        if (type == 'ENDSEC') {
          inBlocks = false;
          inEntities = false;
          continue;
        }

        if (inBlocks) {
          if (type == 'BLOCK') {
            currentBlockEntities = <DxfEntity>[];
            currentBlockName = null;
            currentBlockBase = Offset.zero;
            i = _readRecord(pairs, i, (recordPairs) {
              currentBlockName = _firstString(recordPairs, 2);
              final bx = _firstDouble(recordPairs, 10) ?? 0;
              final by = _firstDouble(recordPairs, 20) ?? 0;
              currentBlockBase = Offset(bx, by);
            });
            continue;
          } else if (type == 'ENDBLK') {
            if (currentBlockName != null && currentBlockEntities != null) {
              blocks[currentBlockName!] = DxfBlock(
                currentBlockName!,
                currentBlockBase,
                currentBlockEntities!,
              );
            }
            currentBlockEntities = null;
            currentBlockName = null;
            continue;
          }
        }

        final targetList = inBlocks ? currentBlockEntities : (inEntities ? entities : entities);
        if (targetList == null) continue;

        switch (type) {
          case 'LINE':
            i = _readRecord(pairs, i, (pMap) => _parseLine(pMap, targetList));
            break;
          case 'CIRCLE':
            i = _readRecord(pairs, i, (pMap) => _parseCircle(pMap, targetList));
            break;
          case 'LWPOLYLINE':
            i = _readRecord(pairs, i, (pMap) => _parseLwPolyline(pMap, targetList));
            break;
          case 'ARC':
            i = _readRecord(pairs, i, (pMap) => _parseArc(pMap, targetList));
            break;
          case 'ELLIPSE':
            i = _readRecord(pairs, i, (pMap) => _parseEllipse(pMap, targetList));
            break;
          case 'TEXT':
          case 'MTEXT':
            i = _readRecord(pairs, i, (pMap) => _parseText(pMap, targetList));
            break;
          case 'SOLID':
          case 'TRACE':
            i = _readRecord(pairs, i, (pMap) => _parseSolid(pMap, targetList));
            break;
          case 'HATCH':
            i = _readRecord(pairs, i, (pMap) => _parseHatch(pMap, targetList));
            break;
          case 'DIMENSION':
            i = _readRecord(pairs, i, (pMap) => _parseDimension(pMap, targetList));
            break;
          case 'LEADER':
            i = _readRecord(pairs, i, (pMap) => _parseLeader(pMap, targetList));
            break;
          case 'INSERT':
            i = _readRecord(pairs, i, (pMap) => _parseInsert(pMap, targetList, blocks));
            break;
          case 'POLYLINE':
            oldPolylinePoints = [];
            insideOldPolyline = true;
            i = _readRecord(pairs, i, (pMap) {
              final flags = _firstInt(pMap, 70) ?? 0;
              oldPolylineClosed = (flags & 1) != 0;
              final cCode = _firstInt(pMap, 62);
              oldPolylineColor = cCode != null ? _dxfRengiBul(cCode) : null;
            });
            break;
          case 'VERTEX':
            if (insideOldPolyline) {
              i = _readRecord(pairs, i, (pMap) {
                final x = _firstDouble(pMap, 10);
                final y = _firstDouble(pMap, 20);
                if (x != null && y != null) {
                  oldPolylinePoints.add(Offset(x, y));
                }
              });
            }
            break;
          case 'SEQEND':
            if (insideOldPolyline && oldPolylinePoints.length >= 2) {
              targetList.add(
                DxfPolyline(
                  List<Offset>.from(oldPolylinePoints),
                  closed: oldPolylineClosed,
                  color: oldPolylineColor,
                ),
              );
            }
            oldPolylinePoints = [];
            insideOldPolyline = false;
            break;
        }
      }
    }

    debugPrint('DXF parse tamamlandı. Toplam varlık: ${entities.length}, Blok sayısı: ${blocks.length}');
    return entities;
  }

  static int _readRecord(List<_DxfPair> pairs, int startIdx, void Function(Map<int, List<String>> pMap) onRecord) {
    final recordMap = <int, List<String>>{};
    var cur = startIdx + 1;
    while (cur < pairs.length && pairs[cur].code != 0) {
      final pair = pairs[cur];
      recordMap.putIfAbsent(pair.code, () => []).add(pair.value);
      cur++;
    }
    onRecord(recordMap);
    return cur - 1;
  }

  static double? _firstDouble(Map<int, List<String>> pMap, int code) {
    final vals = pMap[code];
    return (vals != null && vals.isNotEmpty) ? double.tryParse(vals.first) : null;
  }

  static int? _firstInt(Map<int, List<String>> pMap, int code) {
    final vals = pMap[code];
    return (vals != null && vals.isNotEmpty) ? int.tryParse(vals.first) : null;
  }

  static String? _firstString(Map<int, List<String>> pMap, int code) {
    final vals = pMap[code];
    return (vals != null && vals.isNotEmpty) ? vals.first : null;
  }

  static Color? _extractColor(Map<int, List<String>> pMap) {
    final cCode = _firstInt(pMap, 62);
    return cCode != null ? _dxfRengiBul(cCode) : null;
  }

  static void _parseLine(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final x1 = _firstDouble(pMap, 10);
    final y1 = _firstDouble(pMap, 20);
    final x2 = _firstDouble(pMap, 11);
    final y2 = _firstDouble(pMap, 21);
    if (x1 != null && y1 != null && x2 != null && y2 != null) {
      target.add(DxfLine(Offset(x1, y1), Offset(x2, y2), color: _extractColor(pMap)));
    }
  }

  static void _parseCircle(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final x = _firstDouble(pMap, 10);
    final y = _firstDouble(pMap, 20);
    final r = _firstDouble(pMap, 40);
    if (x != null && y != null && r != null && r > 0) {
      target.add(DxfCircle(Offset(x, y), r, color: _extractColor(pMap)));
    }
  }

  static void _parseLwPolyline(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final xs = pMap[10];
    final ys = pMap[20];
    if (xs == null || ys == null) return;
    final count = math.min(xs.length, ys.length);
    if (count < 2) return;
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final x = double.tryParse(xs[i]);
      final y = double.tryParse(ys[i]);
      if (x != null && y != null) points.add(Offset(x, y));
    }
    if (points.length < 2) return;
    final flags = _firstInt(pMap, 70) ?? 0;
    target.add(DxfPolyline(points, closed: (flags & 1) != 0, color: _extractColor(pMap)));
  }

  static void _parseArc(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final cx = _firstDouble(pMap, 10);
    final cy = _firstDouble(pMap, 20);
    final radius = _firstDouble(pMap, 40);
    if (cx == null || cy == null || radius == null || radius <= 0) return;
    var start = (_firstDouble(pMap, 50) ?? 0) * math.pi / 180.0;
    var end = (_firstDouble(pMap, 51) ?? 360) * math.pi / 180.0;
    if (end <= start) end += 2 * math.pi;
    final sweep = end - start;
    final steps = math.max(16, (sweep / (math.pi / 36)).ceil());
    final points = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = start + sweep * i / steps;
      points.add(Offset(cx + radius * math.cos(t), cy + radius * math.sin(t)));
    }
    target.add(DxfPolyline(points, color: _extractColor(pMap)));
  }

  static void _parseEllipse(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final cx = _firstDouble(pMap, 10);
    final cy = _firstDouble(pMap, 20);
    final mx = _firstDouble(pMap, 11);
    final my = _firstDouble(pMap, 21);
    final ratio = _firstDouble(pMap, 40);
    if (cx == null || cy == null || mx == null || my == null || ratio == null || ratio <= 0) return;
    final majorRadius = math.sqrt(mx * mx + my * my);
    if (majorRadius <= 0) return;
    final minorRadius = majorRadius * ratio;
    final angle = math.atan2(my, mx);
    var start = _firstDouble(pMap, 41) ?? 0;
    var end = _firstDouble(pMap, 42) ?? 2 * math.pi;
    if (end <= start) end += 2 * math.pi;
    final sweep = end - start;
    const steps = 64;
    final points = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = start + sweep * i / steps;
      final ex = majorRadius * math.cos(t);
      final ey = minorRadius * math.sin(t);
      final x = cx + ex * math.cos(angle) - ey * math.sin(angle);
      final y = cy + ex * math.sin(angle) + ey * math.cos(angle);
      points.add(Offset(x, y));
    }
    target.add(DxfPolyline(points, closed: sweep >= 2 * math.pi - 1e-5, color: _extractColor(pMap)));
  }

  static void _parseText(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final x = _firstDouble(pMap, 10);
    final y = _firstDouble(pMap, 20);
    final height = _firstDouble(pMap, 40) ?? 1;
    if (x == null || y == null || height <= 0) return;
    final textParts = [...?pMap[3], ...?pMap[1]];
    final text = _temizleMetin(textParts.join());
    if (text.isEmpty) return;
    target.add(
      DxfText(
        position: Offset(x, y),
        text: text,
        height: height,
        rotation: _firstDouble(pMap, 50) ?? 0,
        color: _extractColor(pMap),
      ),
    );
  }

  static void _parseSolid(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final x0 = _firstDouble(pMap, 10);
    final y0 = _firstDouble(pMap, 20);
    final x1 = _firstDouble(pMap, 11);
    final y1 = _firstDouble(pMap, 21);
    final x2 = _firstDouble(pMap, 12);
    final y2 = _firstDouble(pMap, 22);
    final x3 = _firstDouble(pMap, 13) ?? x2;
    final y3 = _firstDouble(pMap, 23) ?? y2;
    if (x0 != null && y0 != null && x1 != null && y1 != null && x2 != null && y2 != null) {
      target.add(
        DxfPolyline(
          [Offset(x0, y0), Offset(x1, y1), Offset(x3!, y3!), Offset(x2, y2)],
          closed: true,
          color: _extractColor(pMap),
        ),
      );
    }
  }

  static void _parseHatch(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final xs = pMap[10];
    final ys = pMap[20];
    if (xs == null || ys == null) return;
    final count = math.min(xs.length, ys.length);
    if (count < 2) return;
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final x = double.tryParse(xs[i]);
      final y = double.tryParse(ys[i]);
      if (x != null && y != null) points.add(Offset(x, y));
    }
    if (points.length >= 2) {
      target.add(DxfPolyline(points, closed: true, color: _extractColor(pMap)));
    }
  }

  static void _parseDimension(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final x1 = _firstDouble(pMap, 10);
    final y1 = _firstDouble(pMap, 20);
    final x2 = _firstDouble(pMap, 11);
    final y2 = _firstDouble(pMap, 21);
    final text = _firstString(pMap, 1);
    if (x1 != null && y1 != null && x2 != null && y2 != null) {
      target.add(DxfLine(Offset(x1, y1), Offset(x2, y2), color: _extractColor(pMap) ?? Colors.yellow));
      if (text != null && text.isNotEmpty && text != '*') {
        target.add(
          DxfText(
            position: Offset((x1 + x2) / 2, (y1 + y2) / 2),
            text: text,
            height: 12,
            color: _extractColor(pMap) ?? Colors.yellow,
          ),
        );
      }
    }
  }

  static void _parseLeader(Map<int, List<String>> pMap, List<DxfEntity> target) {
    final xs = pMap[10];
    final ys = pMap[20];
    if (xs == null || ys == null) return;
    final count = math.min(xs.length, ys.length);
    if (count < 2) return;
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final x = double.tryParse(xs[i]);
      final y = double.tryParse(ys[i]);
      if (x != null && y != null) points.add(Offset(x, y));
    }
    if (points.length >= 2) {
      target.add(DxfPolyline(points, closed: false, color: _extractColor(pMap) ?? Colors.cyan));
    }
  }

  static void _parseInsert(Map<int, List<String>> pMap, List<DxfEntity> target, Map<String, DxfBlock> blocks) {
    final blockName = _firstString(pMap, 2);
    if (blockName == null) return;
    final block = blocks[blockName];
    if (block == null) return;

    final x = _firstDouble(pMap, 10) ?? 0;
    final y = _firstDouble(pMap, 20) ?? 0;
    final scaleX = _firstDouble(pMap, 41) ?? 1;
    final scaleY = _firstDouble(pMap, 42) ?? 1;
    final rotDeg = _firstDouble(pMap, 50) ?? 0;
    final rotRad = rotDeg * math.pi / 180.0;
    final insertOffset = Offset(x, y) - block.basePoint;

    for (final entity in block.entities) {
      target.add(entity.transform(insertOffset, scaleX, scaleY, rotRad));
    }
  }

  static String _temizleMetin(String value) {
    return value
        .replaceAll(r'\P', '\n')
        .replaceAll(r'\~', ' ')
        .replaceAll(RegExp(r'\\[HfWwAaCcTtQq][^;]*;'), '')
        .replaceAll(RegExp(r'[{}]'), '')
        .trim();
  }
}

class DxfLine extends DxfEntity {
  DxfLine(this.start, this.end, {this.color});

  final Offset start;
  final Offset end;
  @override
  final Color? color;

  @override
  Rect get bounds => Rect.fromPoints(start, end);

  @override
  void draw(Canvas canvas, Paint defaultPaint, {double inverseScale = 1}) {
    final p = color != null ? (Paint()..color = color!..style = defaultPaint.style..strokeWidth = defaultPaint.strokeWidth) : defaultPaint;
    canvas.drawLine(start, end, p);
  }

  @override
  DxfEntity transform(Offset offset, double scaleX, double scaleY, double rotationRad) {
    return DxfLine(
      _transformPoint(start, offset, scaleX, scaleY, rotationRad),
      _transformPoint(end, offset, scaleX, scaleY, rotationRad),
      color: color,
    );
  }
}

class DxfCircle extends DxfEntity {
  DxfCircle(this.center, this.radius, {this.color});

  final Offset center;
  final double radius;
  @override
  final Color? color;

  @override
  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  @override
  void draw(Canvas canvas, Paint defaultPaint, {double inverseScale = 1}) {
    final p = color != null ? (Paint()..color = color!..style = defaultPaint.style..strokeWidth = defaultPaint.strokeWidth) : defaultPaint;
    canvas.drawCircle(center, radius, p);
  }

  @override
  DxfEntity transform(Offset offset, double scaleX, double scaleY, double rotationRad) {
    final newCenter = _transformPoint(center, offset, scaleX, scaleY, rotationRad);
    return DxfCircle(newCenter, radius * math.max(scaleX.abs(), scaleY.abs()), color: color);
  }
}

class DxfPolyline extends DxfEntity {
  DxfPolyline(this.points, {this.closed = false, this.color});

  final List<Offset> points;
  final bool closed;
  @override
  final Color? color;

  @override
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    var result = Rect.fromPoints(points.first, points.first);
    for (final point in points.skip(1)) {
      result = result.expandToInclude(Rect.fromPoints(point, point));
    }
    return result;
  }

  @override
  void draw(Canvas canvas, Paint defaultPaint, {double inverseScale = 1}) {
    if (points.length < 2) return;
    final p = color != null ? (Paint()..color = color!..style = defaultPaint.style..strokeWidth = defaultPaint.strokeWidth) : defaultPaint;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (closed) path.close();
    canvas.drawPath(path, p);
  }

  @override
  DxfEntity transform(Offset offset, double scaleX, double scaleY, double rotationRad) {
    final newPoints = points.map((pt) => _transformPoint(pt, offset, scaleX, scaleY, rotationRad)).toList();
    return DxfPolyline(newPoints, closed: closed, color: color);
  }
}

class DxfText extends DxfEntity {
  DxfText({
    required this.position,
    required this.text,
    required this.height,
    this.rotation = 0,
    this.color,
  });

  final Offset position;
  final String text;
  final double height;
  final double rotation;
  @override
  final Color? color;

  @override
  Rect get bounds {
    final lines = text.split('\n');
    final width = lines.fold<double>(
      0,
      (largest, line) => math.max(largest, line.length * height * 0.6),
    );
    return Rect.fromLTWH(
      position.dx,
      position.dy - height,
      width,
      math.max(height, lines.length * height * 1.2),
    );
  }

  @override
  void draw(Canvas canvas, Paint defaultPaint, {double inverseScale = 1}) {
    final fontSize = height;
    final textColor = color ?? defaultPaint.color;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation * math.pi / 180);
    canvas.scale(1, -1);
    textPainter.paint(canvas, Offset(0, -fontSize));
    canvas.restore();
  }

  @override
  DxfEntity transform(Offset offset, double scaleX, double scaleY, double rotationRad) {
    final newPos = _transformPoint(position, offset, scaleX, scaleY, rotationRad);
    return DxfText(
      position: newPos,
      text: text,
      height: height * math.max(scaleX.abs(), scaleY.abs()),
      rotation: rotation + (rotationRad * 180 / math.pi),
      color: color,
    );
  }
}

Offset _transformPoint(Offset pt, Offset offset, double scaleX, double scaleY, double rotationRad) {
  final sx = pt.dx * scaleX;
  final sy = pt.dy * scaleY;
  final rx = sx * math.cos(rotationRad) - sy * math.sin(rotationRad);
  final ry = sx * math.sin(rotationRad) + sy * math.cos(rotationRad);
  return Offset(rx, ry) + offset;
}

class DxfGoruntuleyici extends StatefulWidget {
  const DxfGoruntuleyici({required this.entities, super.key});

  final List<DxfEntity> entities;

  @override
  State<DxfGoruntuleyici> createState() => _DxfGoruntuleyiciState();
}

class _DxfGoruntuleyiciState extends State<DxfGoruntuleyici> {
  final TransformationController _transformasyon = TransformationController();

  @override
  void dispose() {
    _transformasyon.dispose();
    super.dispose();
  }

  void _yaklastir(double oran) {
    final mevcut = _transformasyon.value.clone()..scaleByDouble(oran, oran, oran, 1);
    _transformasyon.value = mevcut;
  }

  void _sifirla() {
    _transformasyon.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entities.isEmpty) {
      return Container(
        color: const Color(0xFF1E222A),
        child: const Center(
          child: Text('DXF içinde görüntülenebilir çizim bulunamadı.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E222A), // AutoCAD Koyu CAD Görünüm Arka Planı
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boyut = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1200,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 800,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformasyon,
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.05,
                  maxScale: 50,
                  boundaryMargin: const EdgeInsets.all(1000),
                  child: CustomPaint(
                    size: boyut,
                    painter: _DxfPainter(widget.entities),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: Material(
                  color: const Color(0xFF2D323E),
                  elevation: 4,
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _yaklastir(1.25),
                        icon: const Icon(Icons.add, color: Colors.white),
                        tooltip: 'Yaklaştır',
                      ),
                      IconButton(
                        onPressed: () => _yaklastir(0.8),
                        icon: const Icon(Icons.remove, color: Colors.white),
                        tooltip: 'Uzaklaştır',
                      ),
                      IconButton(
                        onPressed: _sifirla,
                        icon: const Icon(Icons.fit_screen_outlined, color: Colors.white),
                        tooltip: 'Görünümü sıfırla',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DxfPainter extends CustomPainter {
  _DxfPainter(this.entities);

  final List<DxfEntity> entities;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _combinedBounds();
    if (bounds == null || bounds.width == 0 || bounds.height == 0) return;

    final scale = math.min(
      (size.width - 64) / bounds.width,
      (size.height - 64) / bounds.height,
    );
    final inverseScale = 1.0 / scale;
    final defaultPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * inverseScale
      ..isAntiAlias = true;

    final center = bounds.center;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, -scale);
    canvas.translate(-center.dx, -center.dy);

    for (final entity in entities) {
      entity.draw(canvas, defaultPaint, inverseScale: inverseScale);
    }
  }

  Rect? _combinedBounds() {
    if (entities.isEmpty) return null;
    var result = entities.first.bounds;
    for (final entity in entities.skip(1)) {
      result = result.expandToInclude(entity.bounds);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _DxfPainter oldDelegate) => oldDelegate.entities != entities;
}
