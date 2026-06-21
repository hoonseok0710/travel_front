import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';
import 'package:flutter/material.dart';

class SvgRegionCache {
  static final Map<String, Path> _cache = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final svgString = await rootBundle.loadString('assets/maps/korea.svg');
    final document = XmlDocument.parse(svgString);

    for (final path in document.findAllElements('path')) {
      final id = path.getAttribute('id') ?? '';
      final d = path.getAttribute('d') ?? '';
      final transform = path.getAttribute('transform') ?? '';

      if (id.isEmpty || id.startsWith('path') || d.isEmpty) continue;
      if (['Layer_1', 'defs5', 'namedview5', 'style1', 'trash'].contains(id)) continue;

      try {
        final flutterPath = _parseSvgPath(d);
        final transformedPath = _applyTransform(flutterPath, transform);
        _cache[id] = transformedPath;
      } catch (_) {}
    }

    _initialized = true;
  }

  static Path? getPath(String id) => _cache[id];

  static Path _parseSvgPath(String d) {
    final converter = _SvgPathConverter();
    writeSvgPathDataToPath(d, converter);
    return converter.path;
  }

  static Path _applyTransform(Path path, String transform) {
    if (transform.isEmpty) return path;
    final regex = RegExp(r'translate\(([^,)]+)(?:,([^)]+))?\)');
    final match = regex.firstMatch(transform);
    if (match == null) return path;
    final tx = double.tryParse(match.group(1)?.trim() ?? '0') ?? 0;
    final ty = double.tryParse(match.group(2)?.trim() ?? '0') ?? 0;
    if (tx == 0 && ty == 0) return path;
    final matrix = Matrix4.identity()..translate(tx, ty);
    return path.transform(matrix.storage);
  }
}

class _SvgPathConverter extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x, double y) =>
      path.cubicTo(x1, y1, x2, y2, x, y);
  @override
  void close() => path.close();
}