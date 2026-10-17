import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sefim/servis/cad_mobil_sahnesi.dart';

class CadSahneGoruntuleyici extends StatefulWidget {
  const CadSahneGoruntuleyici({required this.scene, super.key});

  final CadMobileScene scene;

  @override
  State<CadSahneGoruntuleyici> createState() => _CadSahneGoruntuleyiciState();
}

class _CadSahneGoruntuleyiciState extends State<CadSahneGoruntuleyici> {
  final TransformationController _transformationController =
      TransformationController();
  late Map<String, bool> _layerVisibility;

  @override
  void initState() {
    super.initState();
    _layerVisibility = {
      for (final layer in widget.scene.layers)
        layer.name: layer.visible && !layer.frozen,
    };
  }

  @override
  void didUpdateWidget(covariant CadSahneGoruntuleyici oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) {
      _layerVisibility = {
        for (final layer in widget.scene.layers)
          layer.name: layer.visible && !layer.frozen,
      };
      _transformationController.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _yaklastir(Size viewportSize) {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);
    final zoom = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1.25, 1.25, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1)
      ..multiply(_transformationController.value);
    _transformationController.value = zoom;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extents = widget.scene.drawingExtents;
    final entities = widget.scene.entities
        .where((entity) => _layerVisibility[entity.layer] ?? true)
        .toList(growable: false);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1200,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 800,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.05,
                  maxScale: 50,
                  boundaryMargin: const EdgeInsets.all(1000),
                  child: CustomPaint(
                    size: size,
                    painter: _CadScenePainter(
                      entities: entities,
                      extents: extents,
                      isDark: theme.brightness == Brightness.dark,
                      defaultColor: theme.brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1B2430),
                    ),
                  ),
                ),
              ),
              if (widget.scene.layers.isNotEmpty)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _layerControls(theme.colorScheme),
                ),
              Positioned(
                right: 12,
                top: 12,
                child: Material(
                  color: theme.colorScheme.surface,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Yakınlaştır',
                        onPressed: () => _yaklastir(size),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Çizimi ekrana sığdır',
                        onPressed: () {
                          _transformationController.value = Matrix4.identity();
                        },
                        icon: const Icon(Icons.fit_screen_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.scene.warnings.isNotEmpty ||
                  widget.scene.unsupportedEntities.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _sceneNotices(theme.colorScheme),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _layerControls(ColorScheme colors) {
    return Material(
      color: colors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          title: const Text('Katmanlar'),
          children: [
            SizedBox(
              height: math
                  .min(widget.scene.layers.length * 58.0, 240.0)
                  .toDouble(),
              child: ListView(
                children: [
                  for (final layer in widget.scene.layers)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        layer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: layer.frozen ? const Text('Dondurulmuş') : null,
                      value: _layerVisibility[layer.name] ?? false,
                      onChanged: layer.frozen
                          ? null
                          : (visible) => setState(
                              () => _layerVisibility[layer.name] =
                                  visible ?? false,
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneNotices(ColorScheme colors) {
    final count = widget.scene.unsupportedEntities.length;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(12),
      child: ExpansionTile(
        dense: true,
        leading: Icon(Icons.info_outline, color: colors.primary),
        title: Text(
          count == 0
              ? 'Dönüştürme uyarıları (${widget.scene.warnings.length})'
              : '$count desteklenmeyen nesne',
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final warning in widget.scene.warnings)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.warning_amber_outlined, size: 18),
                    title: Text(warning),
                  ),
                if (count > 0)
                  const ListTile(
                    dense: true,
                    title: Text(
                      'JSON sahnesi DWG nesnelerinin tamamını içermeyebilir. '
                      'Tam dönüştürülmüş çizimi DXF olarak indirebilirsiniz.',
                    ),
                  ),
                for (final entity in widget.scene.unsupportedEntities)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.layers_clear_outlined, size: 18),
                    title: Text(entity),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CadScenePainter extends CustomPainter {
  const _CadScenePainter({
    required this.entities,
    required this.extents,
    required this.isDark,
    required this.defaultColor,
  });

  final List<CadSceneEntity> entities;
  final Rect? extents;
  final bool isDark;
  final Color defaultColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = extents ?? _combinedBounds();
    if (bounds == null || size.isEmpty) return;
    final width = math.max(bounds.width, 1e-9);
    final height = math.max(bounds.height, 1e-9);
    final scale = math.min(
      math.max(size.width - 48, 1) / width,
      math.max(size.height - 48, 1) / height,
    );
    if (!scale.isFinite || scale <= 0) return;
    final inverseScale = 1 / scale;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0
      ..isAntiAlias = true;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale, -scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    for (final entity in entities) {
      paint.color = _entityColor(entity);
      switch (_normalizedType(entity.type)) {
        case 'LINE':
          final start = entity.start;
          final end = entity.end;
          if (start != null && end != null) canvas.drawLine(start, end, paint);
        case 'CIRCLE':
          final center = entity.center;
          final radius = entity.radius;
          if (center != null && radius != null && radius >= 0) {
            canvas.drawCircle(center, radius, paint);
          }
        case 'ARC':
          final center = entity.center;
          final radius = entity.radius;
          final start = entity.startAngle;
          final end = entity.endAngle;
          if (center != null &&
              radius != null &&
              start != null &&
              end != null) {
            final rawSweep = end - start;
            final sweep = rawSweep.abs() >= 360
                ? 360.0
                : ((rawSweep % 360) + 360) % 360;
            canvas.drawArc(
              Rect.fromCircle(center: center, radius: radius),
              start * math.pi / 180,
              sweep * math.pi / 180,
              false,
              paint,
            );
          }
        case 'POLYLINE':
          final points = entity.points;
          if (points.length >= 2) {
            final path = Path()..moveTo(points.first.dx, points.first.dy);
            for (final point in points.skip(1)) {
              path.lineTo(point.dx, point.dy);
            }
            if (entity.closed) path.close();
            canvas.drawPath(path, paint);
          }
        case 'TEXT':
        case 'MTEXT':
          final position = entity.textPosition;
          if (position != null && entity.text.isNotEmpty) {
            _drawText(canvas, entity, position, paint.color, inverseScale);
          }
      }
    }
    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    CadSceneEntity entity,
    Offset position,
    Color color,
    double inverseScale,
  ) {
    final height = math.max(entity.textHeight, 0.01);
    final textPainter = TextPainter(
      text: TextSpan(
        text: entity.text,
        style: TextStyle(
          color: color,
          fontSize: height,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: math.max(entity.text.length * height * 1.5, height));

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(entity.rotation * math.pi / 180);
    canvas.scale(1, -1);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  Color _entityColor(CadSceneEntity entity) {
    final color = entity.trueColor ?? _aciColor(entity.color) ?? defaultColor;
    if (isDark || color.computeLuminance() <= 0.38) return color;
    final hsl = HSLColor.fromColor(color);
    if (hsl.hue >= 35 && hsl.hue <= 75) return const Color(0xFF755100);
    return hsl.withLightness(math.min(hsl.lightness, 0.28)).toColor();
  }

  Color? _aciColor(int? index) {
    if (index == null || index == 0 || index == 256) return null;
    const base = {
      1: Color(0xFFFF0000),
      2: Color(0xFFFFFF00),
      3: Color(0xFF00FF00),
      4: Color(0xFF00FFFF),
      5: Color(0xFF0000FF),
      6: Color(0xFFFF00FF),
      7: Color(0xFFFFFFFF),
      8: Color(0xFF808080),
      9: Color(0xFFC0C0C0),
      250: Color(0xFF333333),
      251: Color(0xFF505050),
      252: Color(0xFF696969),
      253: Color(0xFF828282),
      254: Color(0xFFBEBEBE),
      255: Color(0xFFFFFFFF),
    };
    final known = base[index];
    if (known != null) return known;
    if (index < 10 || index > 249) return null;
    final position = index - 10;
    final hue = ((position ~/ 10) * 15).toDouble();
    final shade = position % 10;
    final saturation = switch (shade % 2) {
      0 => 1.0,
      _ => 0.5,
    };
    final lightness = switch (shade ~/ 2) {
      0 => 0.5,
      1 => 0.65,
      2 => 0.8,
      3 => 0.35,
      _ => 0.2,
    };
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
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
  bool shouldRepaint(covariant _CadScenePainter oldDelegate) =>
      oldDelegate.entities != entities ||
      oldDelegate.extents != extents ||
      oldDelegate.isDark != isDark ||
      oldDelegate.defaultColor != defaultColor;
}

String _normalizedType(String value) {
  final type = value.toUpperCase().split('.').last;
  if (type == 'LWPOLYLINE') return 'POLYLINE';
  return type;
}
