import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Updated imports for newton_particles 0.2.2
import 'package:newton_particles/newton_particles.dart';
import '../screens/board_painter.dart';
import 'enhanced_token_widget.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../screens/board_orientation.dart';

class EnhancedLudoBoardWidget extends StatefulWidget {
  final Map<int, List<int>> positions;
  final Map<int, Color> playerColors;
  final Map<int, int> playerCorners;
  final Map<int, int> playerPoint;
  final List<int> playerOrder;
  final List<int> safeCells;
  final Map<int, Map<int, int>>? allowedMoves;
  final void Function(int playerId, int tokenIndex)? onTokenTap;
  final void Function(int capturingPlayerId, int capturedPlayerId)? onCapture;
  final ConfettiController? confettiController;
  // final ParticleController? particleController;
  final int boardSize;
  final int columns;
  final int? currentTurn;
  final bool isThreeDice;

  const EnhancedLudoBoardWidget({
    super.key,
    required this.positions,
    required this.playerColors,
    required this.playerCorners,
    required this.playerPoint,
    required this.playerOrder,
    required this.safeCells,
    this.allowedMoves,
    this.onTokenTap,
    this.onCapture,
    this.confettiController,
    // this.particleController,
    this.boardSize = 225,
    this.columns = 15,
    this.currentTurn,
    this.isThreeDice = false,
  });

  @override
  State<EnhancedLudoBoardWidget> createState() => _EnhancedLudoBoardWidgetState();
}

class _EnhancedLudoBoardWidgetState extends State<EnhancedLudoBoardWidget>
    with SingleTickerProviderStateMixin {
  late Map<int, List<int>> _currentPositions;
  Future<void> _animationFuture = Future.value();
  static const List<IconData> _colorBlindIcons = [
    Icons.circle,
    Icons.square,
    Icons.change_history,
    Icons.star,
  ];
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  bool _captureSoundEnabled = true;
  bool _moveSoundEnabled = true;
  final Map<int, Map<int, GlobalKey<EnhancedTokenWidgetState>>> _tokenKeys = {};
  double? _cellWidth;
  double? _cellHeight;
  double? _tokenSize;

  @override
  void initState() {
    super.initState();
    _currentPositions = widget.positions.map(
      (k, v) => MapEntry(k, List<int>.from(v)),
    );
    BoardPainter.loadStarSvgs(context);
    BoardPainter.loadWoodImage();
    unawaited(
      _capturePlayer
          .setSourceAsset('audio/capture.wav')
          .catchError((e) {
        _captureSoundEnabled = false;
        debugPrint('Failed to load capture sound: $e');
      }),
    );
    unawaited(
      _movePlayer
          .setSourceAsset('audio/move.wav')
          .catchError((e) {
        _moveSoundEnabled = false;
        debugPrint('Failed to load move sound: $e');
      }),
    );
  }

  @override
  void didUpdateWidget(covariant EnhancedLudoBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPos = Map<int, List<int>>.from(_currentPositions);
    final newPos = widget.positions;
    _animationFuture = _animationFuture.then(
      (_) => _animateChanges(oldPos, newPos),
    );
  }

  Future<void> _animateChanges(
      Map<int, List<int>> oldPos, Map<int, List<int>> newPos) async {
    for (final pid in newPos.keys) {
      final newTokens = newPos[pid]!;
      final oldTokens = oldPos[pid] ?? List<int>.from(newTokens);
      for (var i = 0; i < newTokens.length; i++) {
        final newIndex = newTokens[i];
        final oldIndex = i < oldTokens.length ? oldTokens[i] : newIndex;
        if (newIndex != oldIndex) {
          await _animateToken(pid, i, oldIndex, newIndex);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _currentPositions = newPos.map(
        (k, v) => MapEntry(k, List<int>.from(v)),
      );
    });
  }

  Offset _indexToCell(int index) {
    final col = index % widget.columns;
    final row = index ~/ widget.columns;
    return Offset(col.toDouble(), row.toDouble());
  }

  Offset _indexToOffset(int index, int playerId) {
    final cw = _cellWidth ?? 0;
    final ch = _cellHeight ?? 0;
    final token = _tokenSize ?? 0;
    final rows = (widget.boardSize / widget.columns).ceil();

    if (index < 0) {
      final homeIdx = -index - 1;
      final gridRow = homeIdx ~/ 2;
      final gridCol = homeIdx % 2;
      final corner = widget.playerCorners[playerId] ?? 0;

      Rect zone;
      switch (corner) {
        case 0:
          zone = Rect.fromLTWH(0, 0, cw * 6, ch * 6);
          break;
        case 1:
          zone = Rect.fromLTWH(cw * (widget.columns - 6), 0, cw * 6, ch * 6);
          break;
        case 2:
          zone = Rect.fromLTWH(0, ch * (rows - 6), cw * 6, ch * 6);
          break;
        default:
          zone = Rect.fromLTWH(
              cw * (widget.columns - 6), ch * (rows - 6), cw * 6, ch * 6);
          break;
      }

      final zoneCellWidth = zone.width / 2;
      final zoneCellHeight = zone.height / 2;

      return Offset(
        zone.left + gridCol * zoneCellWidth + (zoneCellWidth - token) / 2,
        zone.top + gridRow * zoneCellHeight + (zoneCellHeight - token) / 2,
      );
    }

    final col = index % widget.columns;
    final row = index ~/ widget.columns;
    return Offset(
      col * cw + (cw - token) / 2,
      row * ch + (ch - token) / 2,
    );
  }

  Future<void> _animateToken(int pid, int idx, int from, int to) async {
    final key = _tokenKeys[pid]?[idx];
    if (key == null) return;

    final path = <Offset>[];

    if (from < 0 || to < 0) {
      path.add(_indexToOffset(from, pid));
      path.add(_indexToOffset(to, pid));
    } else {
      final step = from < to ? 1 : -1;
      for (var pos = from; pos != to; pos += step) {
        path.add(_indexToOffset(pos, pid));
      }
      path.add(_indexToOffset(to, pid));
    }

    await key.currentState?.moveAlongPath(path);

    if (!mounted) return;
    setState(() {
      final tokens = _currentPositions.putIfAbsent(pid, () => []);
      if (idx >= tokens.length) {
        tokens.add(to);
      } else {
        tokens[idx] = to;
      }
    });

    // check capture
    bool captured = false;
    final capturedPlayers = <int>[];
    _currentPositions.forEach((opid, toks) {
      if (opid != pid && toks.contains(to)) {
        captured = true;
        capturedPlayers.add(opid);
      }
    });

    if (captured) {
      HapticFeedback.lightImpact();
      if (_captureSoundEnabled) {
        await _capturePlayer.seek(Duration.zero);
        await _capturePlayer.resume();
      }
      key.currentState?.triggerCapture();
      for (final op in capturedPlayers) {
        widget.onCapture?.call(pid, op);
      }
    } else {
      HapticFeedback.lightImpact();
      if (_moveSoundEnabled) {
        await _movePlayer.seek(Duration.zero);
        await _movePlayer.resume();
      }
    }
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  void dispose() {
    _capturePlayer.dispose();
    _movePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int rows = (widget.boardSize / widget.columns).ceil();
    final double tokenSize = context.watch<SettingsProvider>().tokenSize;
    final bool highContrast = context.watch<SettingsProvider>().highContrast;
    final BoardOrientation orientation =
        context.watch<SettingsProvider>().orientation;
    final double angle = orientation.index * (math.pi / 2);
    Widget board = AspectRatio(
      aspectRatio: widget.columns / rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / widget.columns;
          final cellHeight = constraints.maxHeight / rows;

          _cellWidth = cellWidth;
          _cellHeight = cellHeight;
          _tokenSize = tokenSize;

          final highlightWidgets = _buildHighlights(
            cellWidth,
            cellHeight,
          );

          final tokenWidgets = _buildTokens(
            context,
            cellWidth,
            cellHeight,
            tokenSize,
            widget.confettiController,
            // widget.particleController,
          );
          final semanticsWidgets = _buildCellSemantics(
            cellWidth,
            cellHeight,
          );

          final zones = <Widget>[];
          final colors = List<Color>.generate(4, (index) => Colors.grey);

          widget.playerCorners.forEach((pid, corner) {
            if (corner >= 0 && corner < 4) {
              colors[corner] = _lighten(
                widget.playerColors[pid] ?? Colors.red,
                0.1,
              );
            }
          });

          Rect zoneRect(int index) {
            switch (index) {
              case 0:
                return Rect.fromLTWH(
                    0, 0, cellWidth * 6, cellHeight * 6);
              case 1:
                return Rect.fromLTWH(
                    constraints.maxWidth - cellWidth * 6,
                    0,
                    cellWidth * 6,
                    cellHeight * 6);
              case 2:
                return Rect.fromLTWH(
                    0,
                    constraints.maxHeight - cellHeight * 6,
                    cellWidth * 6,
                    cellHeight * 6);
              default:
                return Rect.fromLTWH(
                    constraints.maxWidth - cellWidth * 6,
                    constraints.maxHeight - cellHeight * 6,
                    cellWidth * 6,
                    cellHeight * 6);
            }
          }

          final activeCorner = widget.currentTurn == null
              ? null
              : widget.playerCorners[widget.currentTurn!];
          for (var i = 0; i < 4; i++) {
            final rect = zoneRect(i);
            Widget zone = AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(color: colors[i].withOpacity(0.2)),
            );
            if (activeCorner == i) {
              zone = _Pulse(child: zone);
            }
            zones.add(Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: zone,
            ));
          }

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.white, Color(0xFFE0E0E0)],
                      center: Alignment.center,
                      radius: 0.8,
                    ),
                  ),
                ),
              ),
              ...zones,
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardPainter(
                      columns: widget.columns,
                      boardSize: widget.boardSize,
                      highlightPlayer: activeCorner,
                      highContrast: highContrast,
                      theme: context.watch<SettingsProvider>().boardTheme,
                      palette: context.watch<SettingsProvider>().boardPalette,
                      saturation:
                          context.watch<SettingsProvider>().boardSaturation,
                      shadows:
                          context.watch<SettingsProvider>().boardShadows,
                      colors: widget.playerColors,
                      corners: widget.playerCorners,
                      playerOrder: widget.playerOrder,
                      playerPoint: widget.playerPoint,
                      safeCells: widget.safeCells,
                      isThreeDice: widget.isThreeDice
                    ),
                  ),
                ),
              ),
              // Cell borders are now drawn directly in BoardPainter
              ...semanticsWidgets,
              ...highlightWidgets,
              ...tokenWidgets,
              Positioned.fill(
                child:
                    _AnimatedTriangles(colors: widget.playerColors, active: activeCorner, corners: widget.playerCorners,),
              ),
            ],
          );
        },
      ),
    );
    board = Transform.rotate(angle: angle, child: board);
    board = InteractiveViewer(
      constrained: true,
      minScale: 0.5,
      maxScale: 3.0,
      child: board,
    );
    board = Material(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: board,
    );
    return board;
  }

  final Map<int, int> pathToBoardIndex = {
    0: 7 * 15 + 1,
    1: 6 * 15 + 1,
    2: 5 * 15 + 1,
    3: 4 * 15 + 1,
    4: 3 * 15 + 1,
    5: 2 * 15 + 1,
    6: 1 * 15 + 1,
    7: 1 * 15 + 2,
    8: 1 * 15 + 3,
    9: 1 * 15 + 4,
    10: 1 * 15 + 5,
    11: 1 * 15 + 6,
    12: 1 * 15 + 7,
    13: 1 * 15 + 8,
    14: 2 * 15 + 8,
    15: 3 * 15 + 8,
    16: 4 * 15 + 8,
    17: 5 * 15 + 8,
    18: 6 * 15 + 8,
    19: 7 * 15 + 8,
    20: 7 * 15 + 9,
    21: 7 * 15 + 10,
    22: 6 * 15 + 10,
    23: 5 * 15 + 10,
    24: 4 * 15 + 10,
    25: 3 * 15 + 10,
    26: 2 * 15 + 10,
    27: 1 * 15 + 10,
    28: 1 * 15 + 11,
    29: 1 * 15 + 12,
    30: 2 * 15 + 12,
    31: 3 * 15 + 12,
    32: 4 * 15 + 12,
    33: 5 * 15 + 12,
    34: 6 * 15 + 12,
    35: 7 * 15 + 12,
    36: 8 * 15 + 12,
    37: 8 * 15 + 13,
    38: 8 * 15 + 14,
    39: 9 * 15 + 14,
    40: 10 * 15 + 14,
    41: 11 * 15 + 14,
    42: 12 * 15 + 14,
    43: 13 * 15 + 14,
    44: 14 * 15 + 14,
    45: 14 * 15 + 13,
    46: 14 * 15 + 12,
    47: 14 * 15 + 11,
    48: 14 * 15 + 10,
    49: 14 * 15 + 9,
    50: 14 * 15 + 8,
    51: 13 * 15 + 8,

    // GREEN home path
    52: 12 * 15 + 8,
    53: 11 * 15 + 8,
    54: 10 * 15 + 8,
    55: 9 * 15 + 8,
    56: 8 * 15 + 8,
    57: 7 * 15 + 8,

    // YELLOW home path
    58: 7 * 15 + 9,
    59: 7 * 15 + 10,
    60: 7 * 15 + 11,
    61: 7 * 15 + 12,
    62: 7 * 15 + 13,
    63: 7 * 15 + 14,

    // BLUE home path
    64: 8 * 15 + 14,
    65: 8 * 15 + 13,
    66: 8 * 15 + 12,
    67: 8 * 15 + 11,
    68: 8 * 15 + 10,
    69: 8 * 15 + 9,

    // RED home path
    70: 8 * 15 + 1,
    71: 8 * 15 + 2,
    72: 8 * 15 + 3,
    73: 8 * 15 + 4,
    74: 8 * 15 + 5,
    75: 8 * 15 + 6,
  };

  // List<Widget> _buildTokens(
  //     BuildContext context,
  //     double cellWidth,
  //     double cellHeight,
  //     double tokenSize,
  //     ConfettiController? controller,
  //     // ParticleController? controller,
  //     ) {
  //   final int columns = widget.columns;
  //   final settings = Provider.of<SettingsProvider>(context, listen: false);
  //   final bool colorBlind = settings.colorBlindMode;
  //   final Map<int, int> placedCount = {};
  //   final Map<int, int> totalCount = {};
  //
  //   /// Just For Testing
  //   // if (_currentPositions.values.every((tokens) => tokens.isEmpty)) {
  //   //   _currentPositions = {
  //   //     0: [0, 1],
  //   //     1: [196, 197],
  //   //     2: [105, 106],
  //   //     3: [90, 91],
  //   //   };
  //   // }
  //   //
  //   final playerColors = widget.playerColors.isEmpty
  //       ? {
  //     1: Colors.green,
  //     2: Colors.yellow,
  //     3: Colors.blue,
  //     0: Colors.red,
  //   }
  //       : widget.playerColors;
  //
  //   // First pass: count tokens per board cell
  //   _currentPositions.forEach((_, toks) {
  //     for (final pos in toks) {
  //       totalCount[pos] = (totalCount[pos] ?? 0) + 1;
  //     }
  //   });
  //
  //   final tokens = <Widget>[];
  //
  //   _currentPositions.forEach((pid, toks) {
  //     for (var i = 0; i < toks.length; i++) {
  //       final index = toks[i];
  //       double dx;
  //       double dy;
  //
  //       if (index < 0) {
  //         // Token is in its home area. Map the negative index to a 2x2 grid
  //         // inside the player's 6x6 corner zone.
  //         final homeIdx = -index - 1;
  //         final gridRow = homeIdx ~/ 2;
  //         final gridCol = homeIdx % 2;
  //
  //         final rows = (widget.boardSize / widget.columns).ceil();
  //         Rect zone;
  //         switch (widget.playerCorners[pid] ?? 0) {
  //           case 0:
  //             zone = Rect.fromLTWH(0, 0, cellWidth * 6, cellHeight * 6);
  //             break;
  //           case 1:
  //             zone = Rect.fromLTWH(
  //                 cellWidth * (columns - 6), 0, cellWidth * 6, cellHeight * 6);
  //             break;
  //           case 2:
  //             zone = Rect.fromLTWH(
  //                 0, cellHeight * (rows - 6), cellWidth * 6, cellHeight * 6);
  //             break;
  //           default:
  //             zone = Rect.fromLTWH(
  //                 cellWidth * (columns - 6),
  //                 cellHeight * (rows - 6),
  //                 cellWidth * 6,
  //                 cellHeight * 6);
  //             break;
  //         }
  //
  //         final zoneCellWidth = zone.width / 2;
  //         final zoneCellHeight = zone.height / 2;
  //         dx = zone.left +
  //             gridCol * zoneCellWidth +
  //             (zoneCellWidth - tokenSize) / 2;
  //         dy = zone.top +
  //             gridRow * zoneCellHeight +
  //             (zoneCellHeight - tokenSize) / 2;
  //       } else {
  //         final col = index % columns;
  //         final row = index ~/ columns;
  //
  //         final placed = placedCount[index] ?? 0;
  //         placedCount[index] = placed + 1;
  //
  //         final total = totalCount[index] ?? 1;
  //         final grid =
  //         (total <= 1) ? 1 : (total <= 4 ? 2 : (math.sqrt(total)).ceil());
  //
  //         const gap = 2.0;
  //         final gridWidth = grid * tokenSize + (grid - 1) * gap;
  //         final startX = col * cellWidth + (cellWidth - gridWidth) / 2;
  //         final startY = row * cellHeight + (cellHeight - gridWidth) / 2;
  //
  //         dx = startX + (placed % grid) * (tokenSize + gap);
  //         dy = startY + (placed ~/ grid) * (tokenSize + gap);
  //       }
  //
  //       String asset;
  //       final color = playerColors[pid] ?? Colors.red;
  //       if (color == Colors.blue) {
  //         asset = 'assets/tokens/token_blue.svg';
  //       } else if (color == Colors.green) {
  //         asset = 'assets/tokens/token_green.svg';
  //       } else if (color == Colors.yellow) {
  //         asset = 'assets/tokens/token_yellow.svg';
  //       } else {
  //         asset = 'assets/tokens/token_red.svg';
  //       }
  //
  //       final canMove = widget.allowedMoves?[pid]?.containsKey(i) ?? false;
  //       _tokenKeys.putIfAbsent(pid, () => {});
  //       final key =
  //       _tokenKeys[pid]![i] ??= GlobalKey<EnhancedTokenWidgetState>();
  //
  //       tokens.add(
  //         EnhancedTokenWidget(
  //           key: key,
  //           position: Offset(dx, dy),
  //           size: tokenSize,
  //           asset: asset,
  //           playerId: pid,
  //           color: color,
  //           colorBlindIcon:
  //           colorBlind ? _colorBlindIcons[pid % _colorBlindIcons.length] : null,
  //           canMove: canMove,
  //           isCurrentTurn: widget.currentTurn == pid,
  //           onTap: () {
  //             widget.onTokenTap?.call(pid, i);
  //           },
  //           confettiController: controller,
  //           // particleController: controller,
  //         ),
  //       );
  //     }
  //   });
  //   return tokens;
  // }


  List<Widget> _buildTokens(
      BuildContext context,
      double cellWidth,
      double cellHeight,
      double tokenSize,
      ConfettiController? controller,
      ) {
    final int columns = widget.columns;
    final int rows = (widget.boardSize / widget.columns).ceil();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool colorBlind = settings.colorBlindMode;
    final Map<int, int> placedCount = {};
    final Map<int, int> totalCount = {};

    // Detect home token positions
    const Set<int> homeIndexes = {0, 13, 26, 39};

    // Count overlapping tokens per board position (except homes)
    _currentPositions.forEach((_, toks) {
      for (final pos in toks) {
        if (pos != -1 && !homeIndexes.contains(pos)) {
          totalCount[pos] = (totalCount[pos] ?? 0) + 1;
        }
      }
    });

    final tokens = <Widget>[];

    // Layout for 4 home positions inside each corner
    const homeOffsets = [
      Offset(1.5, 1.5),
      Offset(3.5, 1.5),
      Offset(1.5, 3.5),
      Offset(3.5, 3.5),
    ];

    // Determine corner index based on home tile value
    int _cornerForOffset(int offset) {
      switch (offset) {
        case 0:
          return 0; // Top-left
        case 39:
          return 1; // Top-right
        case 13:
          return 2; // Bottom-left
        case 26:
          return 3; // Bottom-right
        default:
          return 0;
      }
    }

    // Generate playerCorners dynamically
    Map<int, int> _generatePlayerCorners(Map<int, List<int>> positions) {
      return positions.map((pid, toks) {
        final home = toks.firstWhere(
              (e) => e == -1 || homeIndexes.contains(e),
          orElse: () => -1,
        );
        final corner = _cornerForOffset(home);
        return MapEntry(pid, corner);
      });
    }

    // Get corners based on current tokens
    final playerCorners = _generatePlayerCorners(_currentPositions);

    // Dynamic zone origin based on corner
    Offset zoneOrigin(int corner) {
      switch (corner) {
        case 0:
          return const Offset(0, 0); // Top-left
        case 1:
          return Offset(columns - 6, 0); // Top-right
        case 2:
          return Offset(0, rows - 6); // Bottom-left
        case 3:
          return Offset(columns - 6, rows - 6); // Bottom-right
        default:
          return const Offset(0, 0);
      }
    }

    // Player colors
    final playerColors = widget.playerColors.isEmpty
        ? {
      0: Colors.red,
      1: Colors.green,
      2: Colors.yellow,
      3: Colors.blue,
    }
        : widget.playerColors;

    // Loop through all player tokens
    _currentPositions.forEach((pid, toks) {
      final color = playerColors[pid] ?? Colors.red;
      final asset = _getTokenAsset(color);
      final corner = playerCorners[pid] ?? 0;
      final base = zoneOrigin(corner);

      for (int i = 0; i < toks.length; i++) {
        final index = toks[i];

        final key = _tokenKeys[pid]?[i] ?? GlobalKey<EnhancedTokenWidgetState>();
        _tokenKeys.putIfAbsent(pid, () => {})[i] = key;

        final isHomeToken = widget.isThreeDice && (index == -1 || homeIndexes.contains(index));

        if (isHomeToken) {
          // Home zone layout
          final offset = homeOffsets[i % 4];
          final dx = (base.dx + offset.dx) * cellWidth;
          final dy = (base.dy + offset.dy) * cellHeight;

          tokens.add(
            EnhancedTokenWidget(
              key: key,
              position: Offset(dx, dy),
              size: tokenSize,
              asset: asset,
              playerId: pid,
              color: color,
              colorBlindIcon: colorBlind
                  ? _colorBlindIcons[pid % _colorBlindIcons.length]
                  : null,
              canMove: false,
              isCurrentTurn: widget.currentTurn == pid,
              onTap: () => widget.onTokenTap?.call(pid, i),
              confettiController: controller,
            ),
          );
        } else {
          // Board token layout
          final col = index % columns;
          final row = index ~/ columns;

          final placed = placedCount[index] ?? 0;
          placedCount[index] = placed + 1;

          final total = totalCount[index] ?? 1;
          final grid = (total <= 1)
              ? 1
              : (total <= 4 ? 2 : (math.sqrt(total)).ceil());

          const gap = 2.0;
          final gridWidth = grid * tokenSize + (grid - 1) * gap;
          final startX = col * cellWidth + (cellWidth - gridWidth) / 2;
          final startY = row * cellHeight + (cellHeight - gridWidth) / 2;

          final dx = startX + (placed % grid) * (tokenSize + gap);
          final dy = startY + (placed ~/ grid) * (tokenSize + gap);

          final canMove = widget.allowedMoves?[pid]?.containsKey(i) ?? false;

          tokens.add(
            EnhancedTokenWidget(
              key: key,
              position: Offset(dx, dy),
              size: tokenSize,
              asset: asset,
              playerId: pid,
              color: color,
              colorBlindIcon: colorBlind
                  ? _colorBlindIcons[pid % _colorBlindIcons.length]
                  : null,
              canMove: canMove,
              isCurrentTurn: widget.currentTurn == pid,
              onTap: () => widget.onTokenTap?.call(pid, i),
              confettiController: controller,
            ),
          );
        }
      }
    });

    return tokens;
  }



  String _getTokenAsset(Color color) {
    if (color == Colors.blue) return 'assets/tokens/token_blue.svg';
    if (color == Colors.green) return 'assets/tokens/token_green.svg';
    if (color == Colors.yellow) return 'assets/tokens/token_yellow.svg';
    return 'assets/tokens/token_red.svg';
  }

  List<Widget> _buildHighlights(
    double cellWidth,
    double cellHeight,
  ) {
    final highlights = <Widget>[];
    widget.allowedMoves?.forEach((pid, moves) {
      final color = (widget.playerColors[pid] ?? Colors.black).withOpacity(0.3);
      moves.forEach((_, dest) {
        final col = dest % widget.columns;
        final row = dest ~/ widget.columns;
        highlights.add(Positioned(
          left: col * cellWidth,
          top: row * cellHeight,
          width: cellWidth,
          height: cellHeight,
          child: Container(color: color),
        ));
      });
    });
    return highlights;
  }

  List<Widget> _buildCellSemantics(
    double cellWidth,
    double cellHeight,
  ) {
    final semantics = <Widget>[];
    final rows = (widget.boardSize / widget.columns).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < widget.columns; c++) {
        semantics.add(
          Positioned(
            left: c * cellWidth,
            top: r * cellHeight,
            width: cellWidth,
            height: cellHeight,
            child: IgnorePointer(
              child: Semantics(
                label: _cellLabel(r, c, rows, widget.columns),
                container: true,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );
      }
    }
    return semantics;
  }

  String _cellLabel(int r, int c, int rows, int columns) {
    if (r < 6 && c < 6) {
      return 'Red home square ${r * 6 + c + 1}';
    }
    if (r < 6 && c >= columns - 6) {
      return 'Green home square ${r * 6 + (c - (columns - 6)) + 1}';
    }
    if (r >= rows - 6 && c < 6) {
      return 'Blue home square ${(r - (rows - 6)) * 6 + c + 1}';
    }
    if (r >= rows - 6 && c >= columns - 6) {
      return 'Yellow home square ${(r - (rows - 6)) * 6 + (c - (columns - 6)) + 1}';
    }
    if (c == 7 && r >= 1 && r <= 6) {
      return 'Red path square $r';
    }
    if (r == 7 && c >= 8 && c <= 13) {
      return 'Green path square ${c - 7}';
    }
    if (c == 7 && r >= 8 && r <= 13) {
      return 'Blue path square ${r - 7}';
    }
    if (r == 7 && c >= 1 && c <= 6) {
      return 'Yellow path square $c';
    }
    if (r >= 6 && r <= 8 && c >= 6 && c <= 8) {
      return 'Center square';
    }

    return 'Board square row ${r + 1} column ${c + 1}';
  }

}

class _AnimatedTriangles extends StatelessWidget {
  final Map<int, Color> colors;
  final int? active;
  final Map<int, int> corners;

  const _AnimatedTriangles({
    required this.colors,
    required this.active,
    required this.corners,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: corners.entries.map((entry) {
        final pid = entry.key;
        final corner = entry.value; // corner index (0–3)
        final color = colors[pid] ?? Colors.grey;
        final highlight = color.withOpacity(0.7);

        return Positioned.fill(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: highlight,
              end: active == pid ? color : highlight,
            ),
            duration: const Duration(milliseconds: 500),
            builder: (context, col, _) {
              return CustomPaint(
                painter: _TrianglePainter(corner, col!),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final int index; // 0 = TL, 1 = TR, 2 = BL, 3 = BR
  final Color color;
  _TrianglePainter(this.index, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / 15;
    final ch = size.height / 15;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path();

    switch (index) {
      case 0: // top-left
        path
          ..moveTo(cw * 6, ch * 6)
          ..lineTo(cw * 6, ch * 9)
          ..lineTo(cx, cy)
          ..close();
        break;
      case 1: // top-right
        path
          ..moveTo(cw * 9, ch * 6)
          ..lineTo(cw * 6, ch * 6)
          ..lineTo(cx, cy)
          ..close();
        break;
      case 2: // bottom-left
        path
          ..moveTo(cw * 6, ch * 9)
          ..lineTo(cw * 9, ch * 9)
          ..lineTo(cx, cy)
          ..close();
        break;
      case 3: // bottom-right
        path
          ..moveTo(cw * 9, ch * 9)
          ..lineTo(cw * 9, ch * 6)
          ..lineTo(cx, cy)
          ..close();
        break;
    }

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }


  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.index != index;
  }
}


class _Pulse extends StatelessWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 800.ms,
        );
  }
}
