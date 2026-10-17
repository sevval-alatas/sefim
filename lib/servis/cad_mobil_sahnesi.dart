import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

class CadMobileScene {
  const CadMobileScene({
    required this.schema,
    required this.units,
    required this.extents,
    required this.layers,
    required this.blocks,
    required this.entities,
    required this.warnings,
    required this.unsupportedEntities,
  });

  final String? schema;
  final String? units;
  final Rect? extents;
  final List<CadSceneLayer> layers;
  final List<CadSceneBlock> blocks;
  final List<CadSceneEntity> entities;
  final List<String> warnings;
  final List<String> unsupportedEntities;

  static Future<CadMobileScene> decode(String source) =>
      compute(_decodeSceneJson, source);

  static Future<CadMobileScene> decodeBytes(Uint8List source) =>
      compute(_decodeSceneBytes, source);

  factory CadMobileScene.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['layers'];
    final layerValues = rawLayers is List
        ? rawLayers
        : rawLayers is Map
        ? rawLayers.entries
              .where((entry) => entry.value is Map)
              .map(
                (entry) => {
                  'name': entry.key,
                  ...Map<String, dynamic>.from(entry.value as Map),
                },
              )
              .toList()
        : const <dynamic>[];
    final layers = layerValues
        .whereType<Map>()
        .map(
          (layer) => CadSceneLayer.fromJson(Map<String, dynamic>.from(layer)),
        )
        .toList(growable: false);
    final layerMap = {for (final layer in layers) layer.name: layer};
    final entityValues = _asList(json['entities']);
    final entities = entityValues
        .whereType<Map>()
        .map(
          (entity) => CadSceneEntity.fromJson(
            Map<String, dynamic>.from(entity),
            layerMap,
          ),
        )
        .toList(growable: false);
    final rawBlocks = json['blocks'];
    final blocks = <CadSceneBlock>[];
    if (rawBlocks is List) {
      for (final value in rawBlocks.whereType<Map>()) {
        blocks.add(_parseBlock(Map<String, dynamic>.from(value), layerMap));
      }
    } else if (rawBlocks is Map) {
      for (final entry in rawBlocks.entries) {
        if (entry.value is Map) {
          blocks.add(
            _parseBlock({
              'name': entry.key,
              ...Map<String, dynamic>.from(entry.value as Map),
            }, layerMap),
          );
        }
      }
    }

    return CadMobileScene(
      schema: json['schema']?.toString(),
      units: json['units']?.toString(),
      extents: _rectFromJson(json['extents']),
      layers: layers,
      blocks: List.unmodifiable(blocks),
      entities: List.unmodifiable(entities),
      warnings: _asList(json['warnings']).map(_displayValue).toList(),
      unsupportedEntities: _asList(
        json['unsupportedEntities'] ?? json['unsupported_entities'],
      ).map(_displayValue).toList(),
    );
  }

  List<CadSceneEntity> get visibleEntities => entities
      .where((entity) => entity.isVisible(layerVisibility))
      .toList(growable: false);

  Map<String, bool> get layerVisibility => {
    for (final layer in layers) layer.name: layer.visible && !layer.frozen,
  };

  Rect? get drawingExtents {
    final declared = extents;
    if (declared != null && declared.width >= 0 && declared.height >= 0) {
      return declared;
    }
    final visible = visibleEntities;
    if (visible.isEmpty) return null;
    var result = visible.first.bounds;
    for (final entity in visible.skip(1)) {
      result = result.expandToInclude(entity.bounds);
    }
    return result;
  }
}

class CadSceneLayer {
  const CadSceneLayer({
    required this.name,
    required this.visible,
    required this.frozen,
    this.color,
    this.trueColor,
  });

  final String name;
  final bool visible;
  final bool frozen;
  final int? color;
  final Color? trueColor;

  factory CadSceneLayer.fromJson(Map<String, dynamic> json) {
    return CadSceneLayer(
      name: (json['name'] ?? json['id'] ?? '0').toString(),
      visible: _asBool(
        json['visible'] ?? json['isVisible'] ?? json['is_visible'],
        fallback: true,
      ),
      frozen: _asBool(json['frozen'] ?? json['isFrozen'] ?? json['is_frozen']),
      color: _asInt(json['color']),
      trueColor: _parseTrueColor(json['trueColor'] ?? json['true_color']),
    );
  }
}

class CadSceneBlock {
  const CadSceneBlock({required this.name, required this.entities});

  final String name;
  final List<CadSceneEntity> entities;
}

class CadSceneEntity {
  const CadSceneEntity({
    required this.type,
    required this.layer,
    required this.data,
    this.color,
    this.trueColor,
  });

  final String type;
  final String layer;
  final Map<String, dynamic> data;
  final int? color;
  final Color? trueColor;

  factory CadSceneEntity.fromJson(
    Map<String, dynamic> json,
    Map<String, CadSceneLayer> layers,
  ) {
    final rawLayer =
        (json['layer'] ?? json['layerName'] ?? json['layer_name'] ?? '0')
            .toString();
    final layer = layers[rawLayer];
    final entityColor = _asInt(json['color']);
    final geometry = json['geometry'];
    final data = geometry is Map
        ? {...Map<String, dynamic>.from(geometry), ...json}
        : json;
    return CadSceneEntity(
      type: (json['type'] ?? json['entityType'] ?? '').toString().toUpperCase(),
      layer: rawLayer,
      data: Map.unmodifiable(data),
      color: entityColor == null || entityColor == 0 || entityColor == 256
          ? layer?.color
          : entityColor,
      trueColor:
          _parseTrueColor(json['trueColor'] ?? json['true_color']) ??
          layer?.trueColor,
    );
  }

  bool isVisible(Map<String, bool> visibility) => visibility[layer] ?? true;

  Offset? get start =>
      _point(data['start'] ?? data['startPoint'] ?? data['start_point']) ??
      _xy('startX', 'startY') ??
      _xy('start_x', 'start_y') ??
      _xy('x1', 'y1');

  Offset? get end =>
      _point(data['end'] ?? data['endPoint'] ?? data['end_point']) ??
      _xy('endX', 'endY') ??
      _xy('end_x', 'end_y') ??
      _xy('x2', 'y2');

  Offset? get center =>
      _point(data['center'] ?? data['centre'] ?? data['center_point']) ??
      _xy('centerX', 'centerY') ??
      _xy('center_x', 'center_y');

  double? get radius => _number(data['radius'] ?? data['r']);

  double? get startAngle => _number(
    data['startAngle'] ??
        data['start_angle'] ??
        data['startAngleDegrees'] ??
        data['start_angle_deg'],
  );

  double? get endAngle => _number(
    data['endAngle'] ??
        data['end_angle'] ??
        data['endAngleDegrees'] ??
        data['end_angle_deg'],
  );

  List<Offset> get points {
    final values = _asList(data['points'] ?? data['vertices']);
    return values.map(_point).whereType<Offset>().toList(growable: false);
  }

  String get text =>
      (data['text'] ?? data['value'] ?? data['content'] ?? '').toString();

  double get textHeight =>
      _number(data['height'] ?? data['textHeight'] ?? data['text_height']) ?? 1;

  Offset? get textPosition =>
      _point(
        data['position'] ??
            data['insertionPoint'] ??
            data['insertion_point'] ??
            data['insert_point'] ??
            data['insert'],
      ) ??
      _xy('x', 'y');

  double get rotation =>
      _number(data['rotation'] ?? data['rotationAngle']) ?? 0;

  bool get closed =>
      _asBool(data['closed'] ?? data['isClosed'] ?? data['is_closed']);

  Rect get bounds {
    final kind = _normalizedType(type);
    if (kind == 'LINE') {
      if (start case final a?) {
        if (end case final b?) return Rect.fromPoints(a, b);
      }
    } else if (kind == 'CIRCLE' || kind == 'ARC') {
      final c = center;
      final r = radius;
      if (c != null && r != null) return Rect.fromCircle(center: c, radius: r);
    } else if (kind == 'POLYLINE') {
      final vertices = points;
      if (vertices.isNotEmpty) {
        var result = Rect.fromPoints(vertices.first, vertices.first);
        for (final point in vertices.skip(1)) {
          result = result.expandToInclude(Rect.fromPoints(point, point));
        }
        return result;
      }
    } else if (kind == 'TEXT' || kind == 'MTEXT') {
      final point = textPosition;
      if (point != null) {
        return Rect.fromLTWH(
          point.dx,
          point.dy,
          math.max(text.length * textHeight * 0.65, textHeight),
          textHeight,
        );
      }
    }
    return Rect.zero;
  }

  Offset? _xy(String xKey, String yKey) {
    final x = _number(data[xKey]);
    final y = _number(data[yKey]);
    if (x == null || y == null) return null;
    return Offset(x, y);
  }
}

String _normalizedType(String value) {
  var type = value.toUpperCase().split('.').last;
  if (type.startsWith('ACDB')) type = type.substring(4);
  if (type == 'LWPOLYLINE' || type == 'POLYLINE') return 'POLYLINE';
  if (type == 'TEXT' ||
      type == 'MTEXT' ||
      type == 'LINE' ||
      type == 'CIRCLE' ||
      type == 'ARC') {
    return type;
  }
  return type;
}

CadSceneBlock _parseBlock(
  Map<String, dynamic> json,
  Map<String, CadSceneLayer> layers,
) {
  final entities = _asList(json['entities'])
      .whereType<Map>()
      .map(
        (entity) =>
            CadSceneEntity.fromJson(Map<String, dynamic>.from(entity), layers),
      )
      .toList(growable: false);
  return CadSceneBlock(
    name: (json['name'] ?? json['id'] ?? '').toString(),
    entities: List.unmodifiable(entities),
  );
}

Map<String, dynamic> _decodeJson(String source) {
  final value = jsonDecode(source);
  if (value is! Map) {
    throw const FormatException('CAD sahne yanıtı bir JSON nesnesi olmalıdır.');
  }
  return Map<String, dynamic>.from(value);
}

CadMobileScene _decodeSceneJson(String source) =>
    CadMobileScene.fromJson(_decodeJson(source));

CadMobileScene _decodeSceneBytes(Uint8List source) =>
    CadMobileScene.fromJson(_decodeJson(utf8.decode(source)));

List<dynamic> _asList(Object? value) {
  if (value is List) return value;
  return const [];
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Offset? _point(Object? value) {
  if (value is List && value.length >= 2) {
    final x = _number(value[0]);
    final y = _number(value[1]);
    if (x != null && y != null) return Offset(x, y);
  }
  if (value is Map) {
    final x = _number(value['x'] ?? value['X']);
    final y = _number(value['y'] ?? value['Y']);
    if (x != null && y != null) return Offset(x, y);
  }
  return null;
}

Rect? _rectFromJson(Object? value) {
  if (value is List && value.length >= 2) {
    final min = _point(value[0]);
    final max = _point(value[1]);
    if (min != null && max != null) {
      return Rect.fromPoints(min, max);
    }
  }
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final min = _point(map['min'] ?? map['minimum']);
  final max = _point(map['max'] ?? map['maximum']);
  final minX = _number(map['minX'] ?? map['min_x'] ?? map['xmin']) ?? min?.dx;
  final minY = _number(map['minY'] ?? map['min_y'] ?? map['ymin']) ?? min?.dy;
  final maxX = _number(map['maxX'] ?? map['max_x'] ?? map['xmax']) ?? max?.dx;
  final maxY = _number(map['maxY'] ?? map['max_y'] ?? map['ymax']) ?? max?.dy;
  if (minX == null || minY == null || maxX == null || maxY == null) {
    return null;
  }
  return Rect.fromPoints(Offset(minX, minY), Offset(maxX, maxY));
}

Color? _parseTrueColor(Object? value) {
  if (value is int) return Color(0xFF000000 | (value & 0xFFFFFF));
  if (value is num) return Color(0xFF000000 | (value.toInt() & 0xFFFFFF));
  if (value is List && value.length >= 3) {
    final channels = value.take(3).map(_number).toList();
    if (channels.every((channel) => channel != null)) {
      return Color.fromARGB(
        255,
        channels[0]!.round().clamp(0, 255).toInt(),
        channels[1]!.round().clamp(0, 255).toInt(),
        channels[2]!.round().clamp(0, 255).toInt(),
      );
    }
  }
  if (value is String) {
    final hex = value.replaceFirst('#', '').replaceFirst('0x', '');
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) return Color(0xFF000000 | (parsed & 0xFFFFFF));
  }
  return null;
}

String _displayValue(Object? value) {
  if (value is String) return value;
  return jsonEncode(value);
}
