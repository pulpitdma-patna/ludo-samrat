import 'dart:convert';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../services/socket_service.dart';
import '../widgets/enhanced_ludo_board_widget.dart';
import '../widgets/dice_widget.dart';
import '../widgets/player_status_panel.dart';
import '../widgets/particle_overlay.dart';
// Updated imports for newton_particles 0.2.2
import 'package:newton_particles/newton_particles.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/common_widget/common_appbar.dart';
import 'package:frontend/theme.dart';
import '../widgets/app_drawer.dart';
import '../common_widget/app_scaffold.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_state_provider.dart';
import '../models/game_result.dart';
import '../providers/game_provider.dart';
import '../services/quickplay_api.dart';
import '../services/app_preferences.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int gameId;
  const GameScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  Map<int, Color> _playerColors = {};
  Map<int, int> _captureCounts = {};
  Map<int, int> _playerCorner = {};
  bool _rolling = false;
  Timer? _rollTimeout;
  Timer? _countdownTimer;
  StreamSubscription? _winnerSub;
  ProviderSubscription<GameState>? _gameStateSub;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final ConfettiController _confettiController = ConfettiController();
  bool _wasConfettiPlaying = false;
  List<int>? _lastDice;
  // Particle controller for celebratory bursts.
  // final ParticleController _particleController = ParticleController();
  final List<Color> _colorCycle = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_audioPlayer.setSourceAsset('audio/dice_roll.mp3'));
    unawaited(_winPlayer.setSourceAsset('win.wav'));
    unawaited(AnalyticsService.logGameStart(widget.gameId));
    final notifier = ref.read(gameStateProvider(widget.gameId).notifier);
    _winnerSub = notifier.socket.stream.listen((data) {
      final parsed = data is String ? jsonDecode(data) : data;
      if (parsed is Map && parsed['type'] == 'winner') {
        final rawResults = parsed['results'] as List?;
        final results = rawResults != null
            ? rawResults
                  .map(
                    (e) =>
                        GameResult.fromMap(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList()
            : [GameResult.fromMap(Map<String, dynamic>.from(parsed))];
        //  Play confetti at center
        _confettiController.play();
        final size = MediaQuery.of(context).size;
        // _particleController.burst(Offset(size.width / 2, size.height / 2));
        unawaited(_winPlayer.seek(Duration.zero));
        unawaited(_winPlayer.resume());
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            unawaited(AnalyticsService.logGameEnd(widget.gameId));
            context.go('/results', extra: results);
          }
        });
      } else if (parsed is Map && parsed['type'] == 'error') {
        final msg = parsed['detail']?.toString() ?? 'Error';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    });
    _gameStateSub = ref.listenManual<GameState>(
      gameStateProvider(widget.gameId),
      (prev, next) {
        if (prev?.dice != next.dice) {
          setState(() {
            _rolling = false;
          });
        }
        if (next.dice != null && !listEquals(next.dice, _lastDice)) {
          _lastDice = List<int>.from(next.dice!);
          HapticFeedback.mediumImpact();
          unawaited(_audioPlayer.seek(Duration.zero));
          unawaited(_audioPlayer.resume());
        }
        if (prev?.startOffsets != next.startOffsets &&
            next.startOffsets.isNotEmpty) {
          _ensureCorners(next.startOffsets);
          _ensureColors(next.positions.keys, next.startOffsets);
        } else if (prev?.playerOrder != next.playerOrder &&
            next.playerOrder != null) {
          _ensureCorners(next.startOffsets.isNotEmpty
              ? next.startOffsets
              : {
                  for (var i = 0; i < next.playerOrder!.length; i++)
                    next.playerOrder![i]: _offsetForIndex(i)
                });
        }
      },
    );
  }

  Color _colorForOffset(int offset) {
    switch (offset) {
      case 0:
        return Colors.red;
      case 39:
        return Colors.green;
      case 13:
        return Colors.blue;
      case 26:
        return Colors.yellow;
      default:
        return _colorCycle[_playerColors.length % _colorCycle.length];
    }
  }

  int _cornerForOffset(int offset) {
    switch (offset) {
      case 0:
        return 0; // red
      case 39:
        return 1; // green
      case 13:
        return 2; // blue
      case 26:
        return 3; // yellow
      default:
        return 0;
    }
  }

  int _offsetForIndex(int index) {
    switch (index) {
      case 0:
        return 0;
      case 1:
        return 39;
      case 2:
        return 13;
      case 3:
        return 26;
      default:
        return 0;
    }
  }

  void _ensureColors(Iterable<int> ids, Map<int, int>? offsets) {
    for (final id in ids) {
      if (_playerColors.containsKey(id)) continue;
      final off = offsets?[id];
      _playerColors[id] = off != null
          ? _colorForOffset(off)
          : _colorCycle[_playerColors.length % _colorCycle.length];
    }
  }

  void _ensureCorners(Map<int, int>? offsets) {
    if (offsets == null || offsets.isEmpty) return;
    if (offsets.length == _playerCorner.length &&
        offsets.keys.every((p) => _playerCorner.containsKey(p))) return;
    setState(() {
      _playerCorner = {
        for (final entry in offsets.entries) entry.key: _cornerForOffset(entry.value)
      };
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasConfettiPlaying =
          _confettiController.state == ConfettiControllerState.playing;
      _confettiController.stop();
      _audioPlayer.pause();
      _winPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasConfettiPlaying) {
        _confettiController.play();
      }
      _wasConfettiPlaying = false;
    }
  }

  @override
  void dispose() {
    _winnerSub?.cancel();
    _rollTimeout?.cancel();
    _countdownTimer?.cancel();
    _gameStateSub?.close();
    _audioPlayer.dispose();
    _winPlayer.dispose();
    _confettiController.dispose();
    // _particleController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sendRoll(int playerId) {
    setState(() {
      _rolling = true;
    });
    _lastDice = null;
    SystemSound.play(SystemSoundType.click);
    ref.read(gameStateProvider(widget.gameId).notifier).roll(playerId);
    _rollTimeout?.cancel();
    _rollTimeout = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_rolling) {
        setState(() {
          _rolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No response from server')),
        );
      }
    });
  }

  void _sendMove(int playerId, int token) {
    final state = ref.read(gameStateProvider(widget.gameId));
    final dest = state.allowedMoves[playerId]?[token];
    final current = state.positions[playerId]?[token];
    if (dest == null || current == null) return;
    final die = state.selectedDie ?? dest - current;
    ref.read(gameStateProvider(widget.gameId).notifier).move(playerId, token, die);
    ref.read(gameStateProvider(widget.gameId).notifier).selectDie(null);
  }

  void _handleCapture(int capturing, int captured) {
    setState(() {
      _captureCounts[capturing] = (_captureCounts[capturing] ?? 0) + 1;
    });
  }

  void _onTokenTap(int playerId, int tokenIndex) {
    final state = ref.read(gameStateProvider(widget.gameId));
    if (_rolling || state.turn != playerId) return;
    if (!(state.allowedMoves[playerId]?.containsKey(tokenIndex) ?? false))
      return;
    _sendMove(playerId, tokenIndex);
  }

  Widget _buildControls() {
    final state = ref.watch(gameStateProvider(widget.gameId));
    _ensureColors(state.positions.keys, state.startOffsets);
    _ensureCorners(state.startOffsets);
    final rows = <Widget>[];
    state.positions.forEach((pid, toks) {
      rows.add(
        Row(
          children: [
            Text('Player $pid'),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_rolling || state.turn != pid)
                  ? null
                  : () => _sendRoll(pid),
              child: const Text('Roll'),
            ),
          ],
        ),
      );
    });
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(children: rows);
  }

  List<Widget> _buildAvatars(Map<int, int> corners) {
    final alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];
    final widgets = <Widget>[];
    corners.forEach((pid, corner) {
      if (corner < alignments.length) {
        widgets.add(
          Align(
            alignment: alignments[corner],
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: _playerColors[pid] ?? Colors.grey,
              child: Text(
                'P$pid',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ),
      );
      }
    });
    return widgets;
  }

  Future<bool> _onWillPop() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Match?'),
        content: const Text('Are you sure you want to quit the match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (shouldQuit == true) {
      final roomId = context.read<GameProvider>().roomIdForGame(widget.gameId);
      final matchId = context.read<GameProvider>().matchIdForGame(
        widget.gameId,
      );
      if (roomId != null && matchId != null) {
        final partsRes = await QuickPlayApi().participants(roomId);
        if (partsRes.isSuccess && partsRes.data != null) {
          final myId = await AppPreferences().getUserId();
          int? winner;
          for (final p in partsRes.data!) {
            final uid = int.tryParse(p['user_id']?.toString() ?? '');
            if (uid != null && uid != myId) {
              winner = uid;
              break;
            }
          }
          if (winner != null) {
            await context.read<GameProvider>().endQuickPlay(
              roomId,
              matchId,
              winner,
              context,
            );
          }
        }
      }
      unawaited(AnalyticsService.logGameEnd(widget.gameId));
      ref.invalidate(gameStateProvider(widget.gameId));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AppScaffold(
        drawer: const AppDrawer(),
        appBar: GradientAppBar(
          leading: InkWell(
            onTap: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted && context.canPop()) {
                context.pop();
              }
            },
            child: Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back,
                  size: 22.h,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                'Game ${widget.gameId}',
                style: AppTextStyles.poppinsSemiBold.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Builder(
                    builder: (context) {
                      final state = ref.watch(gameStateProvider(widget.gameId));
                      _ensureColors(state.positions.keys, state.startOffsets);
                      _ensureCorners(state.startOffsets);
                      return EnhancedLudoBoardWidget(
                        positions: state.positions,
                        playerColors: _playerColors,
                        playerCorners: _playerCorner,
                        allowedMoves: state.allowedMoves,
                        onTokenTap: _onTokenTap,
                        onCapture: _handleCapture,
                        currentTurn: state.turn,
                        confettiController: _confettiController,
                        // particleController: _particleController,
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    child: Builder(
                      builder: (context) {
                        final state =
                            ref.watch(gameStateProvider(widget.gameId));
                        final turn = state.turn;
                        int? timeLeft;
                        if (state.moveDeadline != null) {
                          timeLeft = state.moveDeadline! -
                              DateTime.now().millisecondsSinceEpoch ~/ 1000;
                          if (timeLeft < 0) timeLeft = 0;
                        }
                        return Column(
                          children: [
                            if (turn != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Player $turn\'s Turn',
                                  style: TextStyle(
                                    color: _playerColors[turn] ?? Colors.white,
                                  ),
                                ),
                              ),
                            if (timeLeft != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '$timeLeft s',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PlayerStatusPanel(
                      positions: ref
                          .watch(gameStateProvider(widget.gameId))
                          .positions,
                      playerColors: _playerColors,
                      captures: _captureCounts,
                    ),
                  ),
                  ..._buildAvatars(_playerCorner),
                  ConfettiOverlay(controller: _confettiController),
                  // ParticleOverlay(controller: _particleController),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DiceWidget(
                rolling: _rolling,
                values: ref.watch(gameStateProvider(widget.gameId)).dice,
                selected: ref.watch(gameStateProvider(widget.gameId)).selectedDie,
                onSelected: (d) {
                  ref.read(gameStateProvider(widget.gameId).notifier).selectDie(d);
                },
              ),
            ),
            SingleChildScrollView(child: _buildControls()),
          ],
        ),
        ),
      ),
    );
  }
}
