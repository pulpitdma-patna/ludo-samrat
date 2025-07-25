import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'board_theme.dart';
import 'board_colors.dart';

class BoardPainter extends CustomPainter {
  final int columns;
  final int boardSize;
  final int? highlightPlayer;
  final bool highContrast;
  final BoardTheme theme;
  final BoardPalette palette;
  final double saturation;
  final bool shadows;

  /// Row/column coordinates of special "star" cells and their owning color.
  static const List<_StarCell> _starCells = [
    _StarCell(1, 6, 0),
    _StarCell(6, 1, 0),
    _StarCell(8, 1, 1),
    _StarCell(13, 6, 1),
    _StarCell(13, 8, 2),
    _StarCell(8, 13, 2),
    _StarCell(6, 13, 3),
    _StarCell(1, 8, 3),
  ];

  static final List<ui.Picture?> _starPics = List<ui.Picture?>.filled(4, null);
  static bool _loadingStars = false;
  static ui.Image? _woodImage;
  static ImageShader? _woodShader;
  static bool _loadingWood = false;
  static final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  @visibleForTesting
  static ui.Picture? starPic(int index) => _starPics[index];

  @visibleForTesting
  static Shader? get woodShader => _woodShader;

  BoardPainter({
    this.columns = 15,
    this.boardSize = 225,
    this.highlightPlayer,
    this.highContrast = false,
    this.theme = BoardTheme.classic,
    this.palette = BoardPalette.classic,
    this.saturation = 1.0,
    this.shadows = true,
  }) : super(repaint: _repaint);

  int get rows => (boardSize / columns).ceil();

  @override
  void paint(Canvas canvas, Size size) {
    if (saturation != 1.0) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..colorFilter = _saturationFilter(saturation),
      );
    }
    _drawBoard(canvas, size);
    if (saturation != 1.0) {
      canvas.restore();
    }
  }

  void _drawBoard(Canvas canvas, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    final scheme = palette.colors;

    _drawBackground(canvas, size);
    _drawZones(canvas, size, cellWidth, cellHeight, scheme);
    _drawCenterSquare(canvas, cellWidth, cellHeight);
    _drawFinalPaths(canvas, cellWidth, cellHeight, scheme);
    _drawStars(canvas, cellWidth, cellHeight);
    _drawCenterTriangles(canvas, size, cellWidth, cellHeight, scheme);
    _drawCornerEmbellishments(canvas, size, cellWidth, cellHeight);
    _drawGridLines(canvas, size, cellWidth, cellHeight);
    _drawOuterBorder(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint();
    switch (theme) {
      case BoardTheme.modern:
        bgPaint.shader = const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size);
        break;
      case BoardTheme.wooden:
        bgPaint.shader = _woodShader ??
            LinearGradient(
              colors: [Colors.brown.shade700, Colors.brown.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Offset.zero & size);
        break;
      case BoardTheme.glass:
        bgPaint.shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.6), Colors.blueGrey.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size);
        break;
      default:
        bgPaint.color = Colors.white;
    }
    canvas.drawRect(Offset.zero & size, bgPaint);
  }

  void _drawZones(Canvas canvas, Size size, double cellWidth, double cellHeight, BoardColors scheme) {
    final zonePaint = Paint()..style = PaintingStyle.fill;

    void drawZone(Rect rect, Color color) {
      final start = highContrast ? _darken(color, 0.1) : _lighten(color, 0.1);
      final gradient = theme == BoardTheme.modern || theme == BoardTheme.glass
          ? LinearGradient(colors: [start, color], begin: Alignment.topLeft, end: Alignment.bottomRight)
          : RadialGradient(colors: [start, color], center: Alignment.center, radius: 0.8);
      zonePaint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, zonePaint);
    }

    Color zoneColor(Color base, bool highlight) =>
        highlight ? _darken(base, 0.3) : _lighten(base, 0.1);

    drawZone(Rect.fromLTWH(0, 0, cellWidth * 6, cellHeight * 6),
        zoneColor(scheme.red, highlightPlayer == 0));
    drawZone(Rect.fromLTWH(size.width - cellWidth * 6, 0, cellWidth * 6, cellHeight * 6),
        zoneColor(scheme.green, highlightPlayer == 1));
    drawZone(Rect.fromLTWH(0, size.height - cellHeight * 6, cellWidth * 6, cellHeight * 6),
        zoneColor(scheme.blue, highlightPlayer == 2));
    drawZone(
      Rect.fromLTWH(size.width - cellWidth * 6, size.height - cellHeight * 6, cellWidth * 6, cellHeight * 6),
      zoneColor(scheme.yellow, highlightPlayer == 3),
    );
  }

  void _drawCenterSquare(Canvas canvas, double cellWidth, double cellHeight) {
    final rect = Rect.fromLTWH(cellWidth * 6, cellHeight * 6, cellWidth * 3, cellHeight * 3);
    final paint = Paint();
    switch (theme) {
      case BoardTheme.wooden:
        paint.color = Colors.brown.shade300;
        break;
      case BoardTheme.modern:
        paint.color = Colors.grey.shade300;
        break;
      case BoardTheme.glass:
        paint.color = Colors.white70;
        break;
      default:
        paint.color = Colors.grey.shade200;
    }
    canvas.drawRect(rect, paint);
  }

  void _drawFinalPaths(Canvas canvas, double cellWidth, double cellHeight, BoardColors scheme) {
    final pathPaint = Paint()..style = PaintingStyle.fill;

    void drawPathRect(Rect rect, Color color) {
      final start = highContrast ? _darken(color, 0.1) : _lighten(color, 0.1);
      pathPaint.shader = LinearGradient(
        colors: [start, color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
      canvas.drawRect(rect, pathPaint);
    }

    void drawArrow(Offset start, Offset end, Color color) {
      final arrowColor = Color.alphaBlend(Colors.black.withOpacity(0.25), color);
      final paint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..strokeJoin = StrokeJoin.round;
      canvas.drawLine(start, end, paint);

      const headSize = 6.0;
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final path1 = Offset(end.dx - headSize * math.cos(angle - math.pi / 6), end.dy - headSize * math.sin(angle - math.pi / 6));
      final path2 = Offset(end.dx - headSize * math.cos(angle + math.pi / 6), end.dy - headSize * math.sin(angle + math.pi / 6));
      canvas.drawLine(end, path1, paint);
      canvas.drawLine(end, path2, paint);
    }

    /// 🟢 TOP path
    final topPathColor = _lighten(scheme.green, 0.3);
    for (int r = 0; r < 6; r++) {
      drawPathRect(Rect.fromLTWH(cellWidth * 7, cellHeight * (r + 1), cellWidth, cellHeight), topPathColor);
    }
    drawArrow(Offset(cellWidth * 7.5, cellHeight * 1.5), Offset(cellWidth * 7.5, cellHeight * 6.5), topPathColor);

    /// 🟡 RIGHT path
    final rightPathColor = _lighten(scheme.yellow, 0.3);
    for (int c = 0; c < 6; c++) {
      drawPathRect(Rect.fromLTWH(cellWidth * (c + 8), cellHeight * 7, cellWidth, cellHeight), rightPathColor);
    }
    drawArrow(Offset(cellWidth * 13.5, cellHeight * 7.5), Offset(cellWidth * 8.5, cellHeight * 7.5), rightPathColor);

    /// 🔵 BOTTOM path
    final bottomPathColor = _lighten(scheme.blue, 0.3);
    for (int r = 0; r < 6; r++) {
      drawPathRect(Rect.fromLTWH(cellWidth * 7, cellHeight * (r + 8), cellWidth, cellHeight), bottomPathColor);
    }
    drawArrow(Offset(cellWidth * 7.5, cellHeight * 13.5), Offset(cellWidth * 7.5, cellHeight * 8.5), bottomPathColor);

    /// 🔴 LEFT path
    final leftPathColor = _lighten(scheme.red, 0.3);
    for (int c = 0; c < 6; c++) {
      drawPathRect(Rect.fromLTWH(cellWidth * (c + 1), cellHeight * 7, cellWidth, cellHeight), leftPathColor);
    }
    drawArrow(Offset(cellWidth * 1.5, cellHeight * 7.5), Offset(cellWidth * 6.5, cellHeight * 7.5), leftPathColor);
  }

  void _drawStars(Canvas canvas, double cellWidth, double cellHeight) {
    final colors = palette.colors;
    final starColors = [colors.red, colors.green, colors.yellow, colors.blue];

    for (final star in _starCells) {
      final rect = Rect.fromLTWH(star.column * cellWidth, star.row * cellHeight, cellWidth, cellHeight);
      final picture = _starPics[star.colorIndex];

      if (picture != null) {
        canvas.save();
        canvas.translate(rect.left, rect.top);
        final scaleX = rect.width / 100;
        final scaleY = rect.height / 100;
        canvas.scale(scaleX, scaleY);
        canvas.drawPicture(picture);
        canvas.restore();
      } else {
        final center = rect.center;
        final outerRadius = math.min(rect.width, rect.height) * 0.4;
        final innerRadius = outerRadius * 0.5;
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + i * 2 * math.pi / 5;
          final x = center.dx + outerRadius * math.cos(angle);
          final y = center.dy + outerRadius * math.sin(angle);
          if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
          final innerAngle = angle + math.pi / 5;
          path.lineTo(center.dx + innerRadius * math.cos(innerAngle), center.dy + innerRadius * math.sin(innerAngle));
        }
        path.close();
        final paint = Paint()..color = starColors[star.colorIndex];
        if (shadows) canvas.drawShadow(path, Colors.black.withOpacity(0.5), 2.0, false);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawCenterTriangles(Canvas canvas, Size size, double cellWidth, double cellHeight, BoardColors scheme) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final triPaint = Paint()..style = PaintingStyle.fill;

    List<Color> triangleColors = [
      _lighten(scheme.red, 0.4),
      _lighten(scheme.green, 0.4),
      _lighten(scheme.blue, 0.4),
      _lighten(scheme.yellow, 0.4),
    ];

    List<Path> trianglePaths = [
      Path()..moveTo(cellWidth * 6, cellHeight * 6)..lineTo(centerX, centerY)..lineTo(cellWidth * 9, cellHeight * 6)..close(),
      Path()..moveTo(cellWidth * 9, cellHeight * 6)..lineTo(centerX, centerY)..lineTo(cellWidth * 9, cellHeight * 9)..close(),
      Path()..moveTo(cellWidth * 6, cellHeight * 9)..lineTo(centerX, centerY)..lineTo(cellWidth * 9, cellHeight * 9)..close(),
      Path()..moveTo(cellWidth * 6, cellHeight * 6)..lineTo(centerX, centerY)..lineTo(cellWidth * 6, cellHeight * 9)..close(),
    ];

    for (int i = 0; i < 4; i++) {
      triPaint.color = triangleColors[i];
      if (shadows) canvas.drawShadow(trianglePaths[i], Colors.black.withOpacity(0.5), 2.0, false);
      canvas.drawPath(trianglePaths[i], triPaint);
    }
  }

  void _drawCornerEmbellishments(Canvas canvas, Size size, double cellWidth, double cellHeight) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(Rect.fromLTWH(0, 0, cellWidth * 2, cellHeight * 2), 0, math.pi / 2, false, paint);
    canvas.drawArc(Rect.fromLTWH(size.width - cellWidth * 2, 0, cellWidth * 2, cellHeight * 2), math.pi / 2, math.pi / 2, false, paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - cellHeight * 2, cellWidth * 2, cellHeight * 2), -math.pi / 2, math.pi / 2, false, paint);
    canvas.drawArc(Rect.fromLTWH(size.width - cellWidth * 2, size.height - cellHeight * 2, cellWidth * 2, cellHeight * 2), math.pi, math.pi / 2, false, paint);
  }

  void _drawGridLines(Canvas canvas, Size size, double cellWidth, double cellHeight) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill
      ..maskFilter = shadows ? MaskFilter.blur(BlurStyle.inner, 2.0) : null;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final inHome = (r < 6 && c < 6) || (r < 6 && c >= columns - 6) || (r >= rows - 6 && c < 6) || (r >= rows - 6 && c >= columns - 6);
        final inCenter = r >= 6 && r <= 8 && c >= 6 && c <= 8;
        if (inHome || inCenter) continue;

        final rect = Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight);
        if (shadows) canvas.drawRect(rect, shadowPaint);
        canvas.drawRect(rect, gridPaint);
      }
    }
  }

  void _drawOuterBorder(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xffBE5D30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }



  @override
  bool shouldRepaint(covariant BoardPainter old) {
    return old.columns != columns ||
        old.boardSize != boardSize ||
        old.highlightPlayer != highlightPlayer ||
        old.highContrast != highContrast ||
        old.theme != theme ||
        old.palette != palette ||
        old.saturation != saturation ||
        old.shadows != shadows;
  }

  ColorFilter _saturationFilter(double s) {
    final inv = 1 - s;
    final r = 0.213 * inv;
    final g = 0.715 * inv;
    final b = 0.072 * inv;
    return ColorFilter.matrix([
      r + s, g, b, 0, 0,
      r, g + s, b, 0, 0,
      r, g, b + s, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static ui.Picture _generateStarPicture(Color color) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(50, 50);
    const outerRadius = 40.0;
    const innerRadius = outerRadius * 0.5;
    final paint = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final x = center.dx + outerRadius * math.cos(angle);
      final y = center.dy + outerRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final innerAngle = angle + math.pi / 5;
      path.lineTo(
        center.dx + innerRadius * math.cos(innerAngle),
        center.dy + innerRadius * math.sin(innerAngle),
      );
    }
    path.close();
    canvas.drawPath(path, paint);
    return recorder.endRecording();
  }

  // static Future<void> _loadStarSvgs() async {
  //   if (_loadingStars) return;
  //   _loadingStars = true;
  //   const assets = [
  //     'assets/star_red.svg',
  //     'assets/star_green.svg',
  //     'assets/star_yellow.svg',
  //     'assets/star_blue.svg',
  //   ];
  //   for (var i = 0; i < assets.length; i++) {
  //     final data = await rootBundle.loadString(assets[i]);
  //     final svg.DrawableRoot svgRoot =
  //         await svg.fromSvgString(data, assets[i]);
  //     _starPics[i] = svgRoot.toPicture();
  //   }
  //   _loadingStars = false;
  //   _repaint.value++;
  // }

  static Future<void> loadStarSvgs(context) async {
    if (_loadingStars) return;
    _loadingStars = true;
    const assets = [
      'assets/star_red.svg',
      'assets/star_green.svg',
      'assets/star_yellow.svg',
      'assets/star_blue.svg',
    ];
    const fallbacks = [
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.blue,
    ];

    for (var i = 0; i < assets.length; i++) {
      try {
        final svgString = await DefaultAssetBundle.of(context).loadString(assets[i]);
        final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
        // final pictureInfo = await svg.loadPicture(SvgStringLoader(svgString), null);
        _starPics[i] = pictureInfo.picture;
      } catch (e) {
        debugPrint('Error loading SVG ${assets[i]}: $e');
        _starPics[i] = _generateStarPicture(fallbacks[i]);
      }
    }
    _loadingStars = false;
    _repaint.value++;
  }

  static Future<void> loadWoodImage() async {
    if (_loadingWood) return;
    _loadingWood = true;

    try {
      final svgString = await rootBundle.loadString('assets/images/wood_grain.svg');
      final loader = SvgStringLoader(svgString);
      final pictureInfo = await vg.loadPicture(loader, null);
      // final pictureInfo = await svg.loadPicture(loader, null);

      // Create the image at a higher resolution for better quality
      const imageSize = 16;
      _woodImage = await pictureInfo.picture.toImage(imageSize, imageSize);

      _woodShader = ui.ImageShader(
        _woodImage!,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    } catch (e) {
      debugPrint('Error loading wood image: $e');
      const imageSize = 16.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final basePaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(imageSize, imageSize),
          [Colors.brown.shade700, Colors.brown.shade200],
        );
      canvas.drawRect(const Rect.fromLTWH(0, 0, imageSize, imageSize), basePaint);
      final grainPaint = Paint()
        ..color = Colors.brown.shade800.withOpacity(0.3)
        ..strokeWidth = 2;
      canvas.drawLine(const Offset(0, imageSize * 0.3), const Offset(imageSize, imageSize * 0.3), grainPaint);
      canvas.drawLine(const Offset(0, imageSize * 0.6), const Offset(imageSize, imageSize * 0.6), grainPaint);
      final picture = recorder.endRecording();
      _woodImage = await picture.toImage(imageSize.toInt(), imageSize.toInt());
      _woodShader = ui.ImageShader(
        _woodImage!,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    } finally {
      _loadingWood = false;
      _repaint.value++;
    }
  }

  // static Future<void> _loadWoodImage() async {
  //   if (_loadingWood) return;
  //   _loadingWood = true;
  //   final svgString =
  //       await rootBundle.loadString('assets/images/wood_grain.svg');
  //   final svg.DrawableRoot svgRoot =
  //       await svg.fromSvgString(svgString, 'wood_grain.svg');
  //   final ui.Picture picture = svgRoot.toPicture();
  //   _woodImage = await picture.toImage(16, 16);
  //     _woodShader = ui.ImageShader(
  //       _woodImage!,
  //       TileMode.repeated,
  //       TileMode.repeated,
  //       Matrix4.identity().storage,
  //     );
  //   _loadingWood = false;
  //   _repaint.value++;
  // }
}

class _StarCell {
  final int column;
  final int row;
  final int colorIndex;

  const _StarCell(this.column, this.row, this.colorIndex);
}

/*  void _drawBoard(Canvas canvas, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    // Background
    final bgPaint = Paint();
    switch (theme) {
      case BoardTheme.modern:
        bgPaint.shader = const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size);
        break;
      case BoardTheme.wooden:
        if (_woodShader != null) {
          bgPaint.shader = _woodShader!;
        } else {
          bgPaint.shader = LinearGradient(
            colors: [Colors.brown.shade700, Colors.brown.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Offset.zero & size);
        }
        break;
      case BoardTheme.glass:
        bgPaint.shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.6), Colors.blueGrey.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size);
        break;
      case BoardTheme.classic:
      default:
        bgPaint.color = Colors.white;
    }
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Corner home zones (6x6)
    final zonePaint = Paint()..style = PaintingStyle.fill;
    void drawZone(Rect rect, Color color) {
      final start = highContrast ? _darken(color, 0.1) : _lighten(color, 0.1);
      final gradient = theme == BoardTheme.modern || theme == BoardTheme.glass
          ? LinearGradient(
              colors: [start, color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : RadialGradient(
              colors: [start, color],
              center: Alignment.center,
              radius: 0.8,
            );
      zonePaint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, zonePaint);
    }

    final scheme = palette.colors;

    Color zoneBase(Color c) =>
        highContrast ? _darken(c, 0.3) : _lighten(c, 0.2);
    Color zoneNormal(Color c) =>
        highContrast ? _darken(c, 0.1) : _lighten(c, 0.1);

    final highlightRed = highlightPlayer == 0;
    final highlightGreen = highlightPlayer == 1;
    final highlightBlue = highlightPlayer == 2;
    final highlightYellow = highlightPlayer == 3;

    drawZone(
      Rect.fromLTWH(0, 0, cellWidth * 6, cellHeight * 6),
      highlightRed ? zoneBase(scheme.red) : zoneNormal(scheme.red),
    );

    drawZone(
      Rect.fromLTWH(size.width - cellWidth * 6, 0, cellWidth * 6, cellHeight * 6),
      highlightGreen ? zoneBase(scheme.green) : zoneNormal(scheme.green),
    );

    drawZone(
      Rect.fromLTWH(0, size.height - cellHeight * 6, cellWidth * 6, cellHeight * 6),
      highlightBlue ? zoneBase(scheme.blue) : zoneNormal(scheme.blue),
    );

    drawZone(
      Rect.fromLTWH(
        size.width - cellWidth * 6,
        size.height - cellHeight * 6,
        cellWidth * 6,
        cellHeight * 6,
      ),
      highlightYellow ? zoneBase(scheme.yellow) : zoneNormal(scheme.yellow),
    );

    // Central square
    // Central star area (3x3)
    final centerSquare = Rect.fromLTWH(
      cellWidth * 6,
      cellHeight * 6,
      cellWidth * 3,
      cellHeight * 3,
    );
    final centerPaint = Paint();
    switch (theme) {
      case BoardTheme.wooden:
        centerPaint.color = Colors.brown.shade300;
        break;
      case BoardTheme.modern:
        centerPaint.color = Colors.grey.shade300;
        break;
      case BoardTheme.glass:
        centerPaint.color = Colors.white70;
        break;
      default:
        centerPaint.color = Colors.grey.shade200;
    }
    canvas.drawRect(centerSquare, centerPaint);

    // Final stretch paths
    final pathPaint = Paint()..style = PaintingStyle.fill;

    void drawPathRect(Rect rect, Color color) {
      final start = highContrast ? _darken(color, 0.1) : _lighten(color, 0.1);
      pathPaint.shader = LinearGradient(
        colors: [start, color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
      canvas.drawRect(rect, pathPaint);
    }

    void drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
      final arrowColor = Color.alphaBlend(Colors.black.withOpacity(0.25), color);
      final paint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..strokeJoin = StrokeJoin.round;
      canvas.drawLine(start, end, paint);
      const headSize = 6.0;
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final path1 = Offset(
        end.dx - headSize * math.cos(angle - math.pi / 6),
        end.dy - headSize * math.sin(angle - math.pi / 6),
      );
      final path2 = Offset(
        end.dx - headSize * math.cos(angle + math.pi / 6),
        end.dy - headSize * math.sin(angle + math.pi / 6),
      );
      canvas.drawLine(end, path1, paint);
      canvas.drawLine(end, path2, paint);
    }

    // Red path (towards center)
    final redPathColor =
        highContrast ? _darken(scheme.red, 0.2) : _lighten(scheme.red, 0.3);
    for (int r = 0; r < 6; r++) {
      drawPathRect(
        Rect.fromLTWH(cellWidth * 7, cellHeight * (r + 1), cellWidth, cellHeight),
        redPathColor,
      );
    }
    drawArrow(
      canvas,
      Offset(cellWidth * 7 + cellWidth / 2, cellHeight * 1 + cellHeight / 2),
      Offset(cellWidth * 7 + cellWidth / 2, cellHeight * 6 + cellHeight / 2),
      redPathColor,
    );

    // Green path (towards center)
    final greenPathColor =
        highContrast ? _darken(scheme.green, 0.2) : _lighten(scheme.green, 0.3);
    for (int c = 0; c < 6; c++) {
      drawPathRect(
        Rect.fromLTWH(cellWidth * (c + 8), cellHeight * 7, cellWidth, cellHeight),
        greenPathColor,
      );
    }
    drawArrow(
      canvas,
      Offset(cellWidth * 13 + cellWidth / 2, cellHeight * 7 + cellHeight / 2),
      Offset(cellWidth * 8 + cellWidth / 2, cellHeight * 7 + cellHeight / 2),
      greenPathColor,
    );

    // Blue path (towards center)
    final bluePathColor =
        highContrast ? _darken(scheme.blue, 0.2) : _lighten(scheme.blue, 0.3);
    for (int r = 0; r < 6; r++) {
      drawPathRect(
        Rect.fromLTWH(cellWidth * 7, cellHeight * (r + 8), cellWidth, cellHeight),
        bluePathColor,
      );
    }
    drawArrow(
      canvas,
      Offset(cellWidth * 7 + cellWidth / 2, cellHeight * 13 + cellHeight / 2),
      Offset(cellWidth * 7 + cellWidth / 2, cellHeight * 8 + cellHeight / 2),
      bluePathColor,
    );

    // Yellow path (towards center)
    final yellowPathColor =
        highContrast ? _darken(scheme.yellow, 0.2) : _lighten(scheme.yellow, 0.3);
    for (int c = 0; c < 6; c++) {
      drawPathRect(
        Rect.fromLTWH(cellWidth * (c + 1), cellHeight * 7, cellWidth, cellHeight),
        yellowPathColor,
      );
    }
    drawArrow(
      canvas,
      Offset(cellWidth * 1 + cellWidth / 2, cellHeight * 7 + cellHeight / 2),
      Offset(cellWidth * 6 + cellWidth / 2, cellHeight * 7 + cellHeight / 2),
      yellowPathColor,
    );

    // Draw star cells using SVG assets
    final colors = palette.colors;
    final starColors = [colors.red, colors.green, colors.yellow, colors.blue];
    for (final star in _starCells) {
      final rect = Rect.fromLTWH(
        star.column * cellWidth,
        star.row * cellHeight,
        cellWidth,
        cellHeight,
      );
      final picture = _starPics[star.colorIndex];
      if (picture != null) {
        canvas.save();
        canvas.translate(rect.left, rect.top);
        final scaleX = rect.width / 100;
        final scaleY = rect.height / 100;
        canvas.scale(scaleX, scaleY);
        canvas.drawPicture(picture);
        canvas.restore();
      } else {
        final center = rect.center;
        final outerRadius = math.min(rect.width, rect.height) * 0.4;
        final innerRadius = outerRadius * 0.5;
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + i * 2 * math.pi / 5;
          final x = center.dx + outerRadius * math.cos(angle);
          final y = center.dy + outerRadius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
          final innerAngle = angle + math.pi / 5;
          path.lineTo(
            center.dx + innerRadius * math.cos(innerAngle),
            center.dy + innerRadius * math.sin(innerAngle),
          );
        }
        path.close();
        final paint = Paint()..color = starColors[star.colorIndex];
        if (shadows) {
          canvas.drawShadow(path, Colors.black.withOpacity(0.5), 2.0, false);
        }
        canvas.drawPath(path, paint);
      }
    }


    // Center triangles
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final triPaint = Paint()..style = PaintingStyle.fill;

    triPaint.color = _lighten(scheme.red, 0.4);
    var path = Path()
      ..moveTo(cellWidth * 6, cellHeight * 6)
      ..lineTo(centerX, centerY)
      ..lineTo(cellWidth * 9, cellHeight * 6)
      ..close();
    if (shadows) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.5), 2.0, false);
    }
    canvas.drawPath(path, triPaint);

    triPaint.color = _lighten(scheme.green, 0.4);
    path = Path()
      ..moveTo(cellWidth * 9, cellHeight * 6)
      ..lineTo(centerX, centerY)
      ..lineTo(cellWidth * 9, cellHeight * 9)
      ..close();
    if (shadows) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.5), 2.0, false);
    }
    canvas.drawPath(path, triPaint);

    triPaint.color = _lighten(scheme.blue, 0.4);
    path = Path()
      ..moveTo(cellWidth * 6, cellHeight * 9)
      ..lineTo(centerX, centerY)
      ..lineTo(cellWidth * 9, cellHeight * 9)
      ..close();
    if (shadows) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.5), 2.0, false);
    }
    canvas.drawPath(path, triPaint);

    triPaint.color = _lighten(scheme.yellow, 0.4);
    path = Path()
      ..moveTo(cellWidth * 6, cellHeight * 6)
      ..lineTo(centerX, centerY)
      ..lineTo(cellWidth * 6, cellHeight * 9)
      ..close();
    if (shadows) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.5), 2.0, false);
    }
    canvas.drawPath(path, triPaint);

    // Corner embellishments
    final embPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, cellWidth * 2, cellHeight * 2),
      0,
      math.pi / 2,
      false,
      embPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - cellWidth * 2, 0, cellWidth * 2, cellHeight * 2),
      math.pi / 2,
      math.pi / 2,
      false,
      embPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - cellHeight * 2, cellWidth * 2, cellHeight * 2),
      -math.pi / 2,
      math.pi / 2,
      false,
      embPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
          size.width - cellWidth * 2, size.height - cellHeight * 2, cellWidth * 2, cellHeight * 2),
      math.pi,
      math.pi / 2,
      false,
      embPaint,
    );

    // Cell borders
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..strokeJoin = StrokeJoin.round;

    final cellShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill
      ..maskFilter =
          shadows ? MaskFilter.blur(BlurStyle.inner, 2.0) : null;

    // Outline only the playable path cells (15x15 grid minus the four home
    // zones and the 3x3 center area).
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final inHome =
            (r < 6 && c < 6) ||
            (r < 6 && c >= columns - 6) ||
            (r >= rows - 6 && c < 6) ||
            (r >= rows - 6 && c >= columns - 6);
        final inCenter = r >= 6 && r <= 8 && c >= 6 && c <= 8;
        if (inHome || inCenter) continue;

        final rect =
            Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight);
        if (shadows) {
          canvas.drawRect(rect, cellShadowPaint);
        }
        canvas.drawRect(rect, gridPaint);
      }
    }

    // Subtle border around the outer edge
    // canvas.drawRect(Offset.zero & size, gridPaint);

    // Outer black border
    final outerBorderPaint = Paint()
      ..color = const Color(0xffBE5D30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      outerBorderPaint,
    );

// Inner white border (inset by half the outer stroke width)
//     final innerBorderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     const borderInset = 2.0; // Half of outer stroke width
//     canvas.drawRect(
//       Rect.fromLTWH(
//         borderInset,
//         borderInset,
//         size.width - 2 * borderInset,
//         size.height - 2 * borderInset,
//       ),
//       innerBorderPaint,
//     );

  }*/
