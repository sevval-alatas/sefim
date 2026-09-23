import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract class DxfEntity {
  Rect get bounds;

  void draw(Canvas canvas, Paint paint);
}

class DxfLine extends DxfEntity {
  DxfLine(this.start, this.end);

  final Offset start;
  final Offset end;

  @override
  Rect get bounds => Rect.fromPoints(start, end);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawLine(start, end, paint);
  }
}

class DxfCircle extends DxfEntity {
  DxfCircle(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  @override
  void draw(Canvas canvas, Paint paint) {
    canvas.drawCircle(center, radius, paint);
  }
}

class DxfPolyline extends DxfEntity {
  DxfPolyline(this.points, {this.closed = false});

  final List<Offset> points;
  final bool closed;

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
  void draw(Canvas canvas, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (closed) path.close();
    canvas.drawPath(path, paint);
  }
}

class DxfText extends DxfEntity {
  DxfText({
    required this.position,
    required this.text,
    required this.height,
    this.rotation = 0,
  });

  final Offset position;
  final String text;
  final double height;
  final double rotation;

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
  void draw(Canvas canvas, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: paint.color, fontSize: height, height: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation * math.pi / 180);
    canvas.scale(1, -1);
    textPainter.paint(canvas, Offset(0, -height));
    canvas.restore();
  }
}

class DxfParser {
  static List<DxfEntity> parse(String content) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    final entities = <DxfEntity>[];
    var index = 0;

    while (index + 1 < lines.length) {
      final code = int.tryParse(lines[index].trim());
      final value = lines[index + 1].trim();
      index += 2;
      if (code != 0 || value == 'ENDSEC') continue;

      final start = index;
      while (index + 1 < lines.length && lines[index].trim() != '0') {
        index += 2;
      }
      final pairs = <int, List<double>>{};
      final textPairs = <int, List<String>>{};
      final points = <Offset>[];
      for (var cursor = start; cursor + 1 < index; cursor += 2) {
        final pairCode = int.tryParse(lines[cursor].trim());
        if (pairCode == null) continue;
        final rawValue = lines[cursor + 1].trim();
        final number = double.tryParse(rawValue);
        if (number != null) {
          pairs.putIfAbsent(pairCode, () => []).add(number);
        }
        if (pairCode == 1 || pairCode == 3) {
          textPairs.putIfAbsent(pairCode, () => []).add(rawValue);
        }
        if (number == null) continue;
        if (pairCode == 10) {
          final yIndex = points.length;
          final y = _valueAt(lines, start, index, 20, yIndex);
          if (y != null) points.add(Offset(number, y));
        }
      }

      switch (value.toUpperCase()) {
        case 'LINE':
          final x1 = _first(pairs, 10);
          final y1 = _first(pairs, 20);
          final x2 = _first(pairs, 11);
          final y2 = _first(pairs, 21);
          if (x1 != null && y1 != null && x2 != null && y2 != null) {
            entities.add(DxfLine(Offset(x1, y1), Offset(x2, y2)));
          }
        case 'CIRCLE':
          final x = _first(pairs, 10);
          final y = _first(pairs, 20);
          final radius = _first(pairs, 40);
          if (x != null && y != null && radius != null && radius > 0) {
            entities.add(DxfCircle(Offset(x, y), radius));
          }
        case 'LWPOLYLINE':
          if (points.length > 1) {
            entities.add(
              DxfPolyline(points, closed: (_first(pairs, 70) ?? 0) % 2 == 1),
            );
          }
        case 'POLYLINE':
          if (points.length > 1) entities.add(DxfPolyline(points));
        case 'TEXT':
        case 'MTEXT':
          final x = _first(pairs, 10);
          final y = _first(pairs, 20);
          final height = _first(pairs, 40) ?? 1;
          final text = _textValue(textPairs);
          if (x != null && y != null && text.isNotEmpty && height > 0) {
            entities.add(
              DxfText(
                position: Offset(x, y),
                text: _temizleMetin(text),
                height: height,
                rotation: _first(pairs, 50) ?? 0,
              ),
            );
          }
      }
    }
    return entities;
  }

  static double? _first(Map<int, List<double>> pairs, int code) {
    final values = pairs[code];
    return values == null || values.isEmpty ? null : values.first;
  }

  static String _textValue(Map<int, List<String>> textPairs) {
    return [...?textPairs[3], ...?textPairs[1]].join();
  }

  static String _temizleMetin(String value) {
    return value
        .replaceAll(r'\P', '\n')
        .replaceAll(r'\~', ' ')
        .replaceAll(RegExp(r'\\[HfWwAaCcTtQq][^;]*;'), '')
        .replaceAll(RegExp(r'[{}]'), '')
        .trim();
  }

  static double? _valueAt(
    List<String> lines,
    int start,
    int end,
    int wantedCode,
    int occurrence,
  ) {
    var found = 0;
    for (var index = start; index + 1 < end; index += 2) {
      if (int.tryParse(lines[index].trim()) != wantedCode) continue;
      if (found == occurrence) return double.tryParse(lines[index + 1].trim());
      found++;
    }
    return null;
  }
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
    final mevcut = _transformasyon.value.clone()
      ..scaleByDouble(oran, oran, oran, 1);
    _transformasyon.value = mevcut;
  }

  void _sifirla() {
    _transformasyon.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entities.isEmpty) {
      return const Center(
        child: Text('DXF içinde görüntülenebilir çizim bulunamadı.'),
      );
    }
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformasyon,
          constrained: false,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.2,
          maxScale: 20,
          boundaryMargin: const EdgeInsets.all(400),
          child: CustomPaint(
            size: const Size(1200, 800),
            painter: _DxfPainter(widget.entities),
          ),
        ),
        Positioned(
          right: 16,
          top: 16,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 3,
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _yaklastir(1.25),
                  icon: const Icon(Icons.add),
                  tooltip: 'Yaklaştır',
                ),
                IconButton(
                  onPressed: () => _yaklastir(0.8),
                  icon: const Icon(Icons.remove),
                  tooltip: 'Uzaklaştır',
                ),
                IconButton(
                  onPressed: _sifirla,
                  icon: const Icon(Icons.fit_screen_outlined),
                  tooltip: 'Görünümü sıfırla',
                ),
              ],
            ),
          ),
        ),
      ],
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

    final paint = Paint()
      ..color = const Color(0xFF1F497D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    final scale = math.min(
      (size.width - 64) / bounds.width,
      (size.height - 64) / bounds.height,
    );
    final center = bounds.center;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, -scale);
    canvas.translate(-center.dx, -center.dy);
    for (final entity in entities) {
      entity.draw(canvas, paint);
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
  bool shouldRepaint(covariant _DxfPainter oldDelegate) =>
      oldDelegate.entities != entities;
}
