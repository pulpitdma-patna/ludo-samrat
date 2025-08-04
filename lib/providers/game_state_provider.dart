import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/app_preferences.dart';

class GameState {
  final Map<int, List<int>> positions;
  final Map<int, Map<int, int>> allowedMoves;
  final List<int>? dice;
  final int? selectedDie;
  final int? turn;
  final int? moveDeadline;
  final int? elapsedTime;
  final int? timeLimit;
  final List<int>? playerOrder;
  final Map<int, int> startOffsets;
  final Map<int, List<int>> homePaths;
  final Map<int, int> points;
  final List<int> safeCells;

  const GameState({
    required this.positions,
    required this.allowedMoves,
    this.dice,
    this.selectedDie,
    this.turn,
    this.moveDeadline,
    this.elapsedTime,
    this.timeLimit,
    this.playerOrder,
    this.startOffsets = const {},
    this.homePaths = const {},
    this.points = const {},
    this.safeCells = const [],
  });

  GameState copyWith({
    Map<int, List<int>>? positions,
    List<int>? dice,
    int? selectedDie,
    int? turn,
    int? moveDeadline,
    int? elapsedTime,
    int? timeLimit,
    List<int>? playerOrder,
    Map<int, int>? startOffsets,
    Map<int, List<int>>? homePaths,
    Map<int, int>? points,
    List<int>? safeCells,
  }) {
    final newPositions = positions ?? this.positions;
    final newDice = dice ?? this.dice;
    final newSelected = selectedDie ?? this.selectedDie;
    final newTurn = turn ?? this.turn;
    final newDeadline = moveDeadline ?? this.moveDeadline;
    final newElapsed = elapsedTime ?? this.elapsedTime;
    final newLimit = timeLimit ?? this.timeLimit;
    return GameState(
      positions: newPositions,
      dice: newDice,
      selectedDie: newSelected,
      turn: newTurn,
      moveDeadline: newDeadline,
      elapsedTime: newElapsed,
      timeLimit: newLimit,
      playerOrder: playerOrder ?? this.playerOrder,
      startOffsets: startOffsets ?? this.startOffsets,
      homePaths: homePaths ?? this.homePaths,
      points: points ?? this.points,
      safeCells: safeCells ?? this.safeCells,
      allowedMoves:
          _calcAllowedMoves(newPositions, newDice, newTurn, newSelected, points ?? this.points),
    );
  }

  factory GameState.initial() => const GameState(
      positions: {},
      allowedMoves: {},
      dice: null,
      selectedDie: null,
      turn: null,
      moveDeadline: null,
      elapsedTime: null,
      timeLimit: null,
      playerOrder: null,
      startOffsets: {},
      homePaths: {},
      points: {},
     safeCells: []);

  static Map<int, Map<int, int>> _calcAllowedMoves(
      Map<int, List<int>> pos, List<int>? dice, int? turn, int? selectedDie,
      [Map<int, int>? points]) {
    final result = <int, Map<int, int>>{};
    if (dice != null && dice.isNotEmpty && turn != null) {
      final tokens = pos[turn];
      if (tokens != null) {
        final moves = <int, int>{};
        for (var i = 0; i < tokens.length; i++) {
          final dices = selectedDie != null ? [selectedDie] : dice;
          for (final d in dices) {
            final dest = tokens[i] + d;
            if (dest < 225) {
              moves[i] = dest;
              break;
            }
          }
        }
        result[turn] = moves;
      }
    }
    return result;
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  final SocketService socket;
  StreamSubscription? _sub;

  GameStateNotifier({SocketService? socketService})
      : socket = socketService ?? SocketService(),
        super(GameState.initial());

  Future<void> connect(String gameId) async {
    final token = await AppPreferences().getToken();
    if (!mounted) return;
    log('🟢 Connecting to game $gameId with token: $token');
    socket.connect(gameId,token);
    if (!mounted) return;

    _sub = socket.stream.listen(
      _handleMessage,
      onError: (err) => log('❌ WebSocket stream error: $err'),
      onDone: () => log('🔴 WebSocket connection closed.'),
    );
  }

  void roll(int playerId) {
    if (!mounted) return;
    log('🎲 Sending roll for player $playerId');
    socket.send({'type': 'roll', 'player_id': playerId});
  }

  void move(int playerId, int token, int die) {
    if (!mounted) return;
    log('🟦 Sending move for player $playerId, token $token using die $die');
    socket.send({
      'type': 'move',
      'player_id': playerId,
      'moves': [
        {
          'token': token,
          'dice': [die]
        }
      ]
    });
  }

  void selectDie(int? die) {
    if (!mounted) return;
    state = state.copyWith(selectedDie: die);
  }

  void _handleMessage(dynamic data) {
    if (!mounted) return;
    log('📩 Received socket data: $data');
    final parsed = data is String ? jsonDecode(data) : data;

    if (parsed['type'] == 'state') {
      final stateMap = parsed['state'] as Map;
      final pos = <int, List<int>>{};

      (stateMap['positions'] as Map).forEach((k, v) {
        final playerId = int.tryParse(k.toString());
        if (playerId != null) {
          pos[playerId] = List<int>.from((v as List).map((e) => e as int));
        }
      });

      final turn = stateMap['turn'] is int ? stateMap['turn'] as int : null;
      final diceRaw = stateMap['dice'];
      List<int>? dice;
      if (diceRaw is int) {
        dice = [diceRaw];
      } else if (diceRaw is List) {
        dice = List<int>.from(diceRaw.map((e) => e as int));
      }
      final moveDeadline = stateMap['move_deadline'] is int
          ? stateMap['move_deadline'] as int
          : null;
      final elapsed = stateMap['elapsed_time'] is int
          ? stateMap['elapsed_time'] as int
          : null;
      final timeLimit = stateMap['time_limit'] is int
          ? stateMap['time_limit'] as int
          : null;
      List<int>? order;
      final orderRaw = stateMap['player_order'];
      if (orderRaw is List) {
        order = orderRaw.map((e) => int.tryParse(e.toString()) ?? -1).toList();
      }

      final startOffsets = <int, int>{};
      final startRaw = stateMap['start_offsets'];
      if (startRaw is Map) {
        startRaw.forEach((k, v) {
          final id = int.tryParse(k.toString());
          final off = int.tryParse(v.toString());
          if (id != null && off != null) {
            startOffsets[id] = off;
          }
        });
      }

      final homePaths = <int, List<int>>{};
      final homeRaw = stateMap['home_paths'];
      if (homeRaw is Map) {
        homeRaw.forEach((k, v) {
          final id = int.tryParse(k.toString());
          if (id != null && v is List) {
            homePaths[id] =
                List<int>.from(v.map((e) => int.tryParse(e.toString()) ?? 0));
          }
        });
      }

      final points = <int, int>{};
      final pointsRaw = stateMap['points'];
      if (pointsRaw is Map) {
        pointsRaw.forEach((k, v) {
          final id = int.tryParse(k.toString());
          final value = int.tryParse(v.toString());
          if (id != null && value != null) {
            points[id] = value;
          }
        });
      }

      final safeCells = <int>[];
      final safeRaw = stateMap['safe_cells'];
      if (safeRaw is List) {
        safeCells.addAll(safeRaw.map((e) => int.tryParse(e.toString()) ?? 0));
      }

      state = state.copyWith(
          positions: pos,
          turn: turn,
          dice: dice,
          selectedDie: null,
          moveDeadline: moveDeadline,
          elapsedTime: elapsed,
          timeLimit: timeLimit,
          playerOrder: order,
          startOffsets: startOffsets.isEmpty ? state.startOffsets : startOffsets,
          homePaths: homePaths.isEmpty ? state.homePaths : homePaths,
          points: points.isEmpty ? state.points : points,
          safeCells: safeCells,);
    } else if (parsed['type'] == 'roll') {
      final diceRaw = parsed['dice'];
      List<int>? dice;
      if (diceRaw is int) {
        dice = [diceRaw];
      } else if (diceRaw is List) {
        dice = List<int>.from(diceRaw.map((e) => e as int));
      }
      log('🎲 Dice roll result: $dice');
      state = state.copyWith(dice: dice, selectedDie: null);
    } else if (parsed['type'] == 'error') {
      final msg = parsed['message'] ?? 'Unknown error';
      log('❌ Server error: $msg');
    } else if (parsed['type'] == 'game_over') {
      final winner = parsed['winner'];
      log('🏆 Game Over! Winner is player $winner');
    } else if (parsed['type'] == 'connection') {
      final status = parsed['status'];
      log('🔌 Connection status: $status');
    } else if (parsed['type'] == 'player_joined') {
      final id = parsed['player_id'];
      log('👤 Player joined: $id');
    } else if (parsed['type'] == 'player_left') {
      final id = parsed['player_id'];
      log('👤 Player left: $id');
    } else {
      log('⚠️ Unknown message type: $parsed');
    }
  }

  @override
  void dispose() {
    log('❌ Disposing GameStateNotifier');
    _sub?.cancel();
    socket.close();
    super.dispose();
  }
}

final gameStateProvider =
StateNotifierProvider.family<GameStateNotifier, GameState, int>((ref, id) {
  final notifier = GameStateNotifier();
  unawaited(notifier.connect(id.toString()));
  return notifier;
});
