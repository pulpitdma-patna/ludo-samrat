import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'board_painter.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'board_orientation.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BoardWidget extends StatefulWidget {
  final Map<int, List<int>> positions;
  final Map<int, Color> playerColors;
  final Map<int, Map<int, int>>? allowedMoves;
  final void Function(int playerId, int tokenIndex)? onTokenTap;
  final void Function(int capturingPlayerId, int capturedPlayerId)? onCapture;
  final int boardSize;
  final int columns;
  final int? currentTurn;

  const BoardWidget({
    super.key,
    required this.positions,
    required this.playerColors,
    this.allowedMoves,
    this.onTokenTap,
    this.onCapture,
    this.boardSize = 225,
    this.columns = 15,
    this.currentTurn,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late Map<int, List<int>> _currentPositions;
  Future<void> _animationFuture = Future.value();
  static const List<IconData> _colorBlindIcons = [
    Icons.circle,
    Icons.square,
    Icons.change_history,
    Icons.star,
  ];
  MapEntry<int, int>? _selectedToken;
  Timer? _selectedTimer;
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  bool _captureSoundEnabled = true;
  bool _moveSoundEnabled = true;
  final Map<int, Map<int, Offset>> _animOffsets = {};
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
  void didUpdateWidget(covariant BoardWidget oldWidget) {
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

    int cornerFromColor(Color? color) {
      if (color == Colors.green) return 1;
      if (color == Colors.blue) return 2;
      if (color == Colors.yellow) return 3;
      return 0;
    }

    if (index < 0) {
      final homeIdx = -index - 1;
      final gridRow = homeIdx ~/ 2;
      final gridCol = homeIdx % 2;
      final corner = cornerFromColor(widget.playerColors[playerId]);
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
    final segments = <TweenSequenceItem<Offset>>[];

    if (from < 0 || to < 0) {
      final start = _indexToOffset(from, pid);
      final end = _indexToOffset(to, pid);
      segments.add(TweenSequenceItem(tween: Tween(begin: start, end: end), weight: 1));
    } else {
      final step = from < to ? 1 : -1;
      for (var pos = from; pos != to; pos += step) {
        final start = _indexToOffset(pos, pid);
        final end = _indexToOffset(pos + step, pid);
        segments.add(TweenSequenceItem(tween: Tween(begin: start, end: end), weight: 1));
      }
    }

    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200 * (segments.length)),
    );

    final animation = TweenSequence(segments).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _animOffsets.putIfAbsent(pid, () => {})[idx] = animation.value;
      });
    }

    animation.addListener(listener);
    await controller.forward();
    animation.removeListener(listener);
    controller.dispose();

    if (!mounted) return;

    setState(() {
      _animOffsets[pid]?.remove(idx);
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

  @override
  void dispose() {
    _selectedTimer?.cancel();
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
          );
          final semanticsWidgets = _buildCellSemantics(
            cellWidth,
            cellHeight,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: BoardPainter(
                    columns: widget.columns,
                    boardSize: widget.boardSize,
                    highlightPlayer: widget.currentTurn,
                    highContrast: highContrast,
                    theme: context.watch<SettingsProvider>().boardTheme,
                    palette: context.watch<SettingsProvider>().boardPalette,
                    saturation:
                        context.watch<SettingsProvider>().boardSaturation,
                    shadows:
                        context.watch<SettingsProvider>().boardShadows,
                  ),

                ),
              ),
              // Cell borders are now drawn directly in BoardPainter
              ...semanticsWidgets,
              ...highlightWidgets,
              ...tokenWidgets,
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
    return board;
  }

  List<Widget> _buildTokens(
    BuildContext context,
    double cellWidth,
    double cellHeight,
    double tokenSize,
  ) {
    final int columns = widget.columns;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool colorBlind = settings.colorBlindMode;
    final Map<int, int> placedCount = {};
    final Map<int, int> totalCount = {};

    // First pass: count tokens per board cell
    _currentPositions.forEach((_, toks) {
      for (final pos in toks) {
        totalCount[pos] = (totalCount[pos] ?? 0) + 1;
      }
    });

    final tokens = <Widget>[];

    _currentPositions.forEach((pid, toks) {
      for (var i = 0; i < toks.length; i++) {
        final index = toks[i];
        final col = index % columns;
        final row = index ~/ columns;

        final anim = _animOffsets[pid]?[i];

        final placed = placedCount[index] ?? 0;
        placedCount[index] = placed + 1;

        final total = totalCount[index] ?? 1;
        final grid = (total <= 1) ? 1 : (total <= 4 ? 2 : (math.sqrt(total)).ceil());

        const gap = 2.0;
        final gridWidth = grid * tokenSize + (grid - 1) * gap;
        final startX = col * cellWidth + (cellWidth - gridWidth) / 2;
        final startY = row * cellHeight + (cellHeight - gridWidth) / 2;

        double dx = startX + (placed % grid) * (tokenSize + gap);
        double dy = startY + (placed ~/ grid) * (tokenSize + gap);

        if (anim != null) {
          dx = anim.dx;
          dy = anim.dy;
        }

        String asset;
        final color = widget.playerColors[pid] ?? Colors.red;
        if (color == Colors.blue) {
          asset = 'assets/tokens/token_blue.svg';
        } else if (color == Colors.green) {
          asset = 'assets/tokens/token_green.svg';
        } else if (color == Colors.yellow) {
          asset = 'assets/tokens/token_yellow.svg';
        } else {
          asset = 'assets/tokens/token_red.svg';
        }

        final isSelected = _selectedToken?.key == pid && _selectedToken?.value == i;

        Widget token = AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: widget.currentTurn == pid
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Semantics(
                  label: 'Player $pid token ${i + 1}',
                  child: SvgPicture.asset(
                    asset,
                    width: tokenSize,
                    height: tokenSize,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Text(
                      '$pid',
                      style: TextStyle(
                        fontSize: tokenSize * 0.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final canMove = widget.allowedMoves?[pid]?.containsKey(i) ?? false;
        if (colorBlind) {
          token = Stack(
            alignment: Alignment.center,
            children: [
              token,
              Icon(
                _colorBlindIcons[pid % _colorBlindIcons.length],
                color: Colors.white,
                size: tokenSize * 0.6,
              ),
            ],
          );
        }
        if (canMove) {
          token = _Pulse(child: token);
        }

        tokens.add(
          Positioned(
            top: dy,
            left: dx,
            width: tokenSize,
            height: tokenSize,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedToken = MapEntry(pid, i);
                });
                _selectedTimer?.cancel();
                _selectedTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted && _selectedToken?.key == pid && _selectedToken?.value == i) {
                    setState(() {
                      _selectedToken = null;
                    });
                  }
                });
                widget.onTokenTap?.call(pid, i);
              },
              child: Semantics(
                button: true,
                child: token,
              ),
            ),
          ),
        );
      }
    });
    return tokens;
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

class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.2)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
