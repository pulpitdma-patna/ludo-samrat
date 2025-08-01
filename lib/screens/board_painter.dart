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
  final Map<int, int> corners;
  final Map<int, Color> colors;
  final Map<int, int> playerPoint;
  final List<int> playerOrder;
  final List<int> safeCells;
  final bool isThreeDice;

  /// Row/column coordinates of special "star" cells and their owning color.
  static const List<_StarCell> _starCells = [
    _StarCell(1, 6, 0),
    _StarCell(6, 2, 0),
    _StarCell(8, 1, 1),
    _StarCell(12, 6, 1),
    _StarCell(13, 8, 2),
    _StarCell(8, 12, 2),
    _StarCell(6, 13, 3),
    _StarCell(2, 8, 3),
  ];

  List<_StarCell> convertSafeCellsToStarCells(List<int> safeCells) {
    return safeCells.map((index) {
      switch (index) {
        case 1:
          return _StarCell(1, 6, 0);
        case 9:
          return _StarCell(6, 2, 0);
        case 14:
          return _StarCell(8, 1, 1);
        case 22:
          return _StarCell(12, 6, 1);
        case 27:
          return _StarCell(13, 8, 2);
        case 35:
          return _StarCell(8, 12, 2);
        case 40:
          return _StarCell(6, 13, 3);
        case 48:
          return _StarCell(2, 8, 3);
        default:
        // fallback: calculate via default method if needed
          final row = index ~/ 15;
          final col = index % 15;
          return _StarCell(row, col, 0);
      }
    }).toList();
  }


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
    required this.colors,
    required this.corners,
    required this.playerOrder,
    required this.playerPoint,
    required this.safeCells,
    this.isThreeDice = false,
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

    final redPath = getPlayerPath('red');
    final greenPath = getPlayerPath('green');
    final yellowPath = getPlayerPath('yellow');
    final bluePath = getPlayerPath('blue');

    final scheme = palette.colors;

    _drawBackground(canvas, size);

    _drawZones(canvas, size, cellWidth, cellHeight, scheme, corners,playerPoint,playerOrder,isThreeDice);
    // _dynamicDrawZones(canvas, size, cellWidth, cellHeight, corners, colors);
    _drawCenterSquare(canvas, cellWidth, cellHeight);
    _drawFinalPaths(canvas, cellWidth, cellHeight, scheme);
    // _dynamicDrawFinalPaths(canvas, cellWidth, cellHeight,corners, colors);
    _drawCenterTriangles(canvas, size, cellWidth, cellHeight, scheme);
    _drawCornerEmbellishments(canvas, size, cellWidth, cellHeight);
    // _drawMovementPathOnly(canvas, cellWidth, cellHeight, redPath, Colors.red);
    // _drawMovementPathOnly(canvas, cellWidth, cellHeight, greenPath, Colors.green);
    // _drawMovementPathOnly(canvas, cellWidth, cellHeight, yellowPath, Colors.yellow.shade700);
    _drawMovementPathOnly(canvas, cellWidth, cellHeight, bluePath,);
    _drawStars(canvas, cellWidth, cellHeight);
    // _drawFinalHomePath(canvas, cellWidth, cellHeight, finalPaths['red']!, Colors.red);
    // _drawFinalHomePath(canvas, cellWidth, cellHeight, finalPaths['green']!, Colors.green);
    // _drawFinalHomePath(canvas, cellWidth, cellHeight, finalPaths['blue']!, Colors.blue.shade700);
    // _drawFinalHomePath(canvas, cellWidth, cellHeight, finalPaths['blue']!, Colors.blue);
    // _drawGridLines(canvas, size, cellWidth, cellHeight);
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

  //dynamic zone color and corner
  void _dynamicDrawZones(Canvas canvas, Size size, double cellWidth, double cellHeight,
      Map<int, int> corners, // playerId → cornerIndex
      Map<int, Color> colors, // playerId → color
      ) {
    final zonePaint = Paint()..style = PaintingStyle.fill;
    const neutralColor = Color(0xFFE0E0E0);

    void drawZone(Rect rect, Color color) {
      final start = highContrast ? _darken(color, 0.1) : _lighten(color, 0.1);
      final gradient = theme == BoardTheme.modern || theme == BoardTheme.glass
          ? LinearGradient(colors: [start, color], begin: Alignment.topLeft, end: Alignment.bottomRight)
          : RadialGradient(colors: [start, color], center: Alignment.center, radius: 0.8);
      zonePaint.shader = gradient.createShader(rect);
      canvas.drawRect(rect, zonePaint);
    }

    final positions = {
      0: Rect.fromLTWH(0, 0, cellWidth * 6, cellHeight * 6), // top-left
      1: Rect.fromLTWH(size.width - cellWidth * 6, 0, cellWidth * 6, cellHeight * 6), // top-right
      2: Rect.fromLTWH(0, size.height - cellHeight * 6, cellWidth * 6, cellHeight * 6), // bottom-left
      3: Rect.fromLTWH(size.width - cellWidth * 6, size.height - cellHeight * 6, cellWidth * 6, cellHeight * 6), // bottom-right
    };

    for (int i = 0; i < 4; i++) {
      // Try to find a player whose corner is this index
      final playerEntry = corners.entries.firstWhere(
            (e) => e.value == i,
        orElse: () => const MapEntry(-1, -1),
      );

      final color = playerEntry.key != -1
          ? colors[playerEntry.key] ?? Colors.grey
          : neutralColor;

      drawZone(positions[i]!, color);
    }
  }


  void _drawZones(
      Canvas canvas,
      Size size,
      double cellWidth,
      double cellHeight,
      BoardColors scheme,
      Map<int, int> corners,       // playerId → cornerIndex
      Map<int, int> scores,        // playerId → score
      List<int> playerOrder,       // e.g. [51, 52]
      bool isThreeDicesMode,
      ) {
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

    final double zoneWidth = cellWidth * 6;
    final double zoneHeight = cellHeight * 6;

    final zones = [
      {
        'rect': Rect.fromLTWH(0, 0, zoneWidth, zoneHeight),
        'color': scheme.red,
        'highlight': highlightPlayer == 0,
        'corner': 0,
      },
      {
        'rect': Rect.fromLTWH(size.width - zoneWidth, 0, zoneWidth, zoneHeight),
        'color': scheme.green,
        'highlight': highlightPlayer == 1,
        'corner': 1,
      },
      {
        'rect': Rect.fromLTWH(0, size.height - zoneHeight, zoneWidth, zoneHeight),
        'color': scheme.blue,
        'highlight': highlightPlayer == 2,
        'corner': 2,
      },
      {
        'rect': Rect.fromLTWH(size.width - zoneWidth, size.height - zoneHeight, zoneWidth, zoneHeight),
        'color': scheme.yellow,
        'highlight': highlightPlayer == 3,
        'corner': 3,
      },
    ];

    for (final z in zones) {
      final rect = z['rect'] as Rect;
      final color = z['color'] as Color;
      final highlight = z['highlight'] as bool;
      final cornerIndex = z['corner'] as int;

      drawZone(rect, zoneColor(color, highlight));

      // Get the playerId in this corner
      final playerId = corners.entries.firstWhere(
            (e) => e.value == cornerIndex,
        orElse: () => const MapEntry(-1, -1),
      ).key;

      if (isThreeDicesMode && playerId != -1) {
        final score = scores[playerId]?.toString() ?? '0';

        // Get mover label based on playerOrder list
        final moverIndex = playerOrder.indexOf(playerId);
        final moverLabel = '${_ordinalSuffix(moverIndex + 1)} Mover';

        final smallBoxSize = Size(cellWidth * 2.5, cellHeight * 2.5);
        final boxOffset = Offset(
          rect.left + (zoneWidth - smallBoxSize.width) / 2,
          rect.top + (zoneHeight - smallBoxSize.height) / 2 + 12,
        );
        final smallRect = boxOffset & smallBoxSize;

        final baseColor = color;
        final startColor = highContrast ? _darken(baseColor, 0.1) : _lighten(baseColor, 0.15);

        final boxPaint = Paint()
          ..shader = LinearGradient(
            colors: [startColor, baseColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(smallRect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(smallRect, Radius.circular(cellWidth * 0.5)),
          boxPaint,
        );

        // Mover label
        final labelPainter = TextPainter(
          text: TextSpan(
            text: moverLabel,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: cellHeight * 0.55,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: zoneWidth);

        labelPainter.paint(
          canvas,
          Offset(
            rect.left + (zoneWidth - labelPainter.width) / 2,
            boxOffset.dy - labelPainter.height - 4,
          ),
        );

        // "Score" Label above the number
        final scoreLabelPainter = TextPainter(
          text: TextSpan(
            text: 'Score',
            style: TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w500,
              fontSize: cellHeight * 0.45,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: smallBoxSize.width);

        scoreLabelPainter.paint(
          canvas,
          Offset(
            boxOffset.dx + (smallBoxSize.width - scoreLabelPainter.width) / 2,
            boxOffset.dy + 4, // Small top padding inside box
          ),
        );

        // Score Number (with black color)
        final scorePainter = TextPainter(
          text: TextSpan(
            text: score,
            style: TextStyle(
              color: Colors.black, // ← changed from white to black
              fontWeight: FontWeight.bold,
              fontSize: cellHeight * 1,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: smallBoxSize.width);

        scorePainter.paint(
          canvas,
          Offset(
            boxOffset.dx + (smallBoxSize.width - scorePainter.width) / 2,
            boxOffset.dy + (smallBoxSize.height - scorePainter.height) / 2 + cellHeight * 0.3,
          ),
        );
      }
    }
  }

// Helper to convert 1 → '1st', 2 → '2nd', etc.
  String _ordinalSuffix(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }

    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
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

  void _dynamicDrawFinalPaths(
      Canvas canvas,
      double cellWidth,
      double cellHeight,
      Map<int, int> corners,       // playerId → cornerIndex (0–3)
      Map<int, Color> colors,      // playerId → color
      ) {
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
      final path1 = Offset(end.dx - headSize * math.cos(angle - math.pi / 6),
          end.dy - headSize * math.sin(angle - math.pi / 6));
      final path2 = Offset(end.dx - headSize * math.cos(angle + math.pi / 6),
          end.dy - headSize * math.sin(angle + math.pi / 6));
      canvas.drawLine(end, path1, paint);
      canvas.drawLine(end, path2, paint);
    }

    for (final entry in corners.entries) {
      final pid = entry.key;
      final corner = entry.value;
      final color = _lighten(colors[pid] ?? Colors.grey, 0.3);

      switch (corner) {
        case 0: // 🔴 Top-left → final path horizontal right (row 7)
          for (int c = 1; c <= 6; c++) {
            drawPathRect(
              Rect.fromLTWH(cellWidth * c, cellHeight * 7, cellWidth, cellHeight),
              color,
            );
          }
          drawArrow(
            Offset(cellWidth * 1.5, cellHeight * 7.5),
            Offset(cellWidth * 6.5, cellHeight * 7.5),
            color,
          );
          break;

        case 1: // 🟢 Top-right → final path vertical down (column 7)
          for (int r = 1; r <= 6; r++) {
            drawPathRect(
              Rect.fromLTWH(cellWidth * 7, cellHeight * r, cellWidth, cellHeight),
              color,
            );
          }
          drawArrow(
            Offset(cellWidth * 7.5, cellHeight * 1.5),
            Offset(cellWidth * 7.5, cellHeight * 6.5),
            color,
          );
          break;

        case 2: // 🔵 Bottom-left → final path vertical up (column 7)
          for (int r = 8; r <= 13; r++) {
            drawPathRect(
              Rect.fromLTWH(cellWidth * 7, cellHeight * r, cellWidth, cellHeight),
              color,
            );
          }
          drawArrow(
            Offset(cellWidth * 7.5, cellHeight * 13.5),
            Offset(cellWidth * 7.5, cellHeight * 8.5),
            color,
          );
          break;

        case 3: // 🟡 Bottom-right → final path horizontal left (row 7)
          for (int c = 8; c <= 13; c++) {
            drawPathRect(
              Rect.fromLTWH(cellWidth * c, cellHeight * 7, cellWidth, cellHeight),
              color,
            );
          }
          drawArrow(
            Offset(cellWidth * 13.5, cellHeight * 7.5),
            Offset(cellWidth * 8.5, cellHeight * 7.5),
            color,
          );
          break;
      }
    }
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
    final topPathColor = _lighten(scheme.green, 0.2);
    for (int r = 0; r < 6; r++) {
      drawPathRect(Rect.fromLTWH(cellWidth * 7, cellHeight * (r + 1), cellWidth, cellHeight), topPathColor);
    }
    drawArrow(Offset(cellWidth * 7.5, cellHeight * 1.5), Offset(cellWidth * 7.5, cellHeight * 6.5), topPathColor);

    /// 🟡 RIGHT path
    final rightPathColor = _lighten(scheme.yellow, 0.1);
    for (int c = 0; c < 6; c++) {
      drawPathRect(Rect.fromLTWH(cellWidth * (c + 8), cellHeight * 7, cellWidth, cellHeight), rightPathColor);
    }
    drawArrow(Offset(cellWidth * 13.5, cellHeight * 7.5), Offset(cellWidth * 8.5, cellHeight * 7.5), rightPathColor);

    /// 🔵 BOTTOM path
    final bottomPathColor = _lighten(scheme.blue, 0.2);
    for (int r = 0; r < 6; r++) {
      drawPathRect(Rect.fromLTWH(cellWidth * 7, cellHeight * (r + 8), cellWidth, cellHeight), bottomPathColor);
    }
    drawArrow(Offset(cellWidth * 7.5, cellHeight * 13.5), Offset(cellWidth * 7.5, cellHeight * 8.5), bottomPathColor);

    /// 🔴 LEFT path
    final leftPathColor = _lighten(scheme.red, 0.2);
    for (int c = 0; c < 6; c++) {
      drawPathRect(Rect.fromLTWH(cellWidth * (c + 1), cellHeight * 7, cellWidth, cellHeight), leftPathColor);
    }
    drawArrow(Offset(cellWidth * 1.5, cellHeight * 7.5), Offset(cellWidth * 6.5, cellHeight * 7.5), leftPathColor);
  }

  void _drawStars(Canvas canvas, double cellWidth, double cellHeight) {

    final colors = palette.colors;
    final starColors = [colors.red, colors.green, colors.yellow, colors.blue];

    // final List<_StarCell> stars = safeCells.isNotEmpty
    //     ? convertSafeCellsToStarCells(safeCells)
    //     : _starCells;

    for (final star in _starCells) {
      final rect = Rect.fromLTWH(star.column * cellWidth, star.row * cellHeight, cellWidth, cellHeight);
      final picture = _starPics[star.colorIndex];

      // 🔁 Use same gradient logic as _drawFinalPaths
      final baseColor = starColors[star.colorIndex];
      final startColor = highContrast ? _darken(baseColor, 0.1) : _lighten(baseColor, 0.1);

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [startColor, baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);

      // ✅ Draw gradient background like final path
      canvas.drawRect(rect, paint);

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

  final List<Offset> basePath = [
    Offset(6, 0), Offset(6, 1), Offset(6, 2), Offset(6, 3), Offset(6, 4), Offset(6, 5),
    Offset(5, 6), Offset(4, 6), Offset(3, 6), Offset(2, 6), Offset(1, 6), Offset(0, 6),
    Offset(0, 7), Offset(0, 8), Offset(1, 8), Offset(2, 8), Offset(3, 8), Offset(4, 8),
    Offset(5, 8), Offset(6, 9), Offset(6, 10), Offset(6, 11), Offset(6, 12), Offset(6, 13),
    Offset(6, 14), Offset(7, 14), Offset(8, 14), Offset(8, 13), Offset(8, 12), Offset(8, 11),
    Offset(8, 10), Offset(8, 9), Offset(9, 8), Offset(10, 8), Offset(11, 8), Offset(12, 8),
    Offset(13, 8), Offset(14, 8), Offset(14, 7), Offset(14, 6), Offset(13, 6), Offset(12, 6),
    Offset(11, 6), Offset(10, 6), Offset(9, 6), Offset(8, 5), Offset(8, 4), Offset(8, 3),
    Offset(8, 2), Offset(8, 1), Offset(8, 0), Offset(7, 0),
  ];

  final Map<String, List<Offset>> finalPaths = {
    'red':    [Offset(1,7), Offset(2,7), Offset(3,7), Offset(4,7), Offset(5,7), Offset(6,7)],
    'green':  [Offset(7,1), Offset(7,2), Offset(7,3), Offset(7,4), Offset(7,5), Offset(7,6)],
    'yellow': [Offset(13,7), Offset(12,7), Offset(11,7), Offset(10,7), Offset(9,7), Offset(8,7)],
    'blue':   [Offset(7,13), Offset(7,12), Offset(7,11), Offset(7,10), Offset(7,9), Offset(7,8)],
  };


  List<Offset> getPlayerPath(String color) {
    int offset = 0;

    switch (color.toLowerCase()) {
      case 'red':
        offset = 0;
        break;
      case 'green':
        offset = 13;
        break;
      case 'yellow':
        offset = 26;
        break;
      case 'blue':
        offset = 39;
        break;
      default:
        offset = 0;
    }

    return [
      ...basePath.sublist(offset),
      ...basePath.sublist(0, offset),
    ];
  }


  void _drawMovementPathOnly(
      Canvas canvas,
      double cellWidth,
      double cellHeight,
      List<Offset> path,
      ) {
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final fillPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    for (final cell in path) {
      final rect = Rect.fromLTWH(
        cell.dy * cellWidth,
        cell.dx * cellHeight,
        cellWidth,
        cellHeight,
      );

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawFinalHomePath(
      Canvas canvas,
      double cellWidth,
      double cellHeight,
      List<Offset> path,
      Color color,
      ) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (final cell in path) {
      final rect = Rect.fromLTWH(
        cell.dy * cellWidth,
        cell.dx * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }


  // void _drawMovementPathOnly(
  //     Canvas canvas,
  //     double cellWidth,
  //     double cellHeight,
  //     List<Offset> path,
  //     Color color,
  //     ) {
  //   final pathPaint = Paint()
  //     ..color = color.withOpacity(0.25)
  //     ..style = PaintingStyle.fill;
  //
  //   final borderPaint = Paint()
  //     ..color = Colors.black.withOpacity(0.3)
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = 1;
  //
  //   for (final cell in path) {
  //     final rect = Rect.fromLTWH(
  //       cell.dy * cellWidth,
  //       cell.dx * cellHeight,
  //       cellWidth,
  //       cellHeight,
  //     );
  //     canvas.drawRect(rect, pathPaint);
  //     canvas.drawRect(rect, borderPaint);
  //   }
  // }



  // void _drawGridLines(Canvas canvas, Size size, double cellWidth, double cellHeight) {
  //   final gridPaint = Paint()
  //     ..color = Colors.grey.shade300
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = 1;
  //
  //   final shadowPaint = Paint()
  //     ..color = Colors.black.withOpacity(0.05)
  //     ..style = PaintingStyle.fill
  //     ..maskFilter = shadows ? MaskFilter.blur(BlurStyle.inner, 2.0) : null;
  //
  //   final ludoPathCells = _generateLudoPath();
  //
  //   for (final cell in ludoPathCells) {
  //     final r = cell.dy.toInt();
  //     final c = cell.dx.toInt();
  //     final rect = Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight);
  //     if (shadows) canvas.drawRect(rect, shadowPaint);
  //     canvas.drawRect(rect, gridPaint);
  //   }
  // }

  List<Offset> _generateLudoPath() {
    List<Offset> path = [];

    // ➤ Blue zone → Horizontal from left to center
    for (int c = 0; c < 6; c++) path.add(Offset(c.toDouble(), 6)); // Row 6, Col 0–5
    // ➤ Blue to Green → Vertical up
    for (int r = 5; r >= 0; r--) path.add(Offset(6, r.toDouble())); // Col 6, Row 5–0

    // ➤ Green zone → Horizontal to right
    for (int c = 7; c < 15; c++) path.add(Offset(c.toDouble(), 6)); // Row 6, Col 7–14
    // ➤ Green to Yellow → Vertical down
    for (int r = 7; r < 15; r++) path.add(Offset(8, r.toDouble())); // Col 8, Row 7–14

    // ➤ Yellow zone → Horizontal to left
    for (int c = 13; c >= 0; c--) path.add(Offset(c.toDouble(), 8)); // Row 8, Col 13–0
    // ➤ Yellow to Red → Vertical up
    for (int r = 13; r > 8; r--) path.add(Offset(6, r.toDouble())); // Col 6, Row 13–9

    return path;
  }



  void _drawOuterBorder(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.blue
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
