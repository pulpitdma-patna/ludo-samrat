import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/ludo_image_board/ludo_player.dart';
import 'package:frontend/services/app_preferences.dart';
import '../services/socket_service.dart';
import 'constants.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio.dart';


class LudoState {
  final bool isMoving;
  final bool stopMoving;
  final LudoGameState gameState;
  final LudoPlayerType currentTurn;
  final int diceResult;
  final bool diceStarted;
  final List<LudoPlayer> players;
  final List<LudoPlayerType> winners;

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

  LudoState({
    required this.isMoving,
    required this.stopMoving,
    required this.gameState,
    required this.currentTurn,
    required this.diceResult,
    required this.diceStarted,
    required this.players,
    required this.winners,

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

  factory LudoState.initial() => LudoState(
    isMoving: false,
    stopMoving: false,
    gameState: LudoGameState.throwDice,
    currentTurn: LudoPlayerType.green,
    diceResult: 0,
    diceStarted: false,
    players: [],
    winners: [],

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
      safeCells: []

  );

  LudoState copyWith({
    bool? isMoving,
    bool? stopMoving,
    LudoGameState? gameState,
    LudoPlayerType? currentTurn,
    int? diceResult,
    bool? diceStarted,
    List<LudoPlayer>? players,
    List<LudoPlayerType>? winners,

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

    return LudoState(
      isMoving: isMoving ?? this.isMoving,
      stopMoving: stopMoving ?? this.stopMoving,
      gameState: gameState ?? this.gameState,
      currentTurn: currentTurn ?? this.currentTurn,
      diceResult: diceResult ?? this.diceResult,
      diceStarted: diceStarted ?? this.diceStarted,
      players: players ?? this.players,
      winners: winners ?? this.winners,

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

class LudoStateNotifier extends StateNotifier<LudoState> {
  final SocketService socket;
  StreamSubscription? _sub;

  LudoStateNotifier({SocketService? socketService})
      : socket = socketService ?? SocketService(),
        super(LudoState.initial());


  Future<void> connect(String gameId) async {
    final token = await AppPreferences().getToken();
    if (!mounted) return;
    debugPrint('🟢 Connecting to game $gameId with token: $token');
    socket.connect(gameId,token);
    if (!mounted) return;

    _sub = socket.stream.listen(
      _handleMessage,
      onError: (err) => debugPrint('❌ WebSocket stream error: $err'),
      onDone: () => debugPrint('🔴 WebSocket connection closed.'),
    );
  }

  void _handleMessage(dynamic data) {
    if (!mounted) return;
    debugPrint('📩 Received socket data: $data');
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

      // Call startGame only once when players are not yet created
      if (state.players.isEmpty && order != null && startOffsets.isNotEmpty) {
        startGame();
      }

    } else if (parsed['type'] == 'roll') {
      final diceRaw = parsed['dice'];
      List<int>? dice;
      if (diceRaw is int) {
        dice = [diceRaw];
      } else if (diceRaw is List) {
        dice = List<int>.from(diceRaw.map((e) => e as int));
      }
      debugPrint('🎲 Dice roll result: $dice');
      state = state.copyWith(dice: dice, selectedDie: null);
    } else if (parsed['type'] == 'error') {
      final msg = parsed['message'] ?? 'Unknown error';
      debugPrint('❌ Server error: $msg');
    } else if (parsed['type'] == 'game_over') {
      final winner = parsed['winner'];
      debugPrint('🏆 Game Over! Winner is player $winner');
    } else if (parsed['type'] == 'connection') {
      final status = parsed['status'];
      debugPrint('🔌 Connection status: $status');
    } else if (parsed['type'] == 'player_joined') {
      final id = parsed['player_id'];
      debugPrint('👤 Player joined: $id');
    } else if (parsed['type'] == 'player_left') {
      final id = parsed['player_id'];
      debugPrint('👤 Player left: $id');
    } else {
      debugPrint('⚠️ Unknown message type: $parsed');
    }
  }

  void selectDie(int? die) {
    if (!mounted) return;
    state = state.copyWith(selectedDie: die);
  }

  void socketMover(int playerId, int token, int die) {
    if (!mounted) return;
    debugPrint('🟦 Sending move for player $playerId, token $token using die $die');
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

  void roll(int playerId) {
    if (!mounted) return;
    debugPrint('🎲 Sending roll for player $playerId');
    socket.send({'type': 'roll', 'player_id': playerId});
  }




  ///Flags to check if pawn is moving
  bool get _isMoving => state.isMoving;

  ///Flags to stop pawn once disposed
  bool get _stopMoving => state.stopMoving;

  ///Game state to check if the game is in throw dice state or pick pawn state
  LudoGameState get gameState => state.gameState;

  LudoPlayerType get _currentTurn => state.currentTurn;

  int get _diceResult => state.diceResult;

  ///Dice result to check the dice result of the current turn
  int get diceResult {
    if (_diceResult < 1) {
      return 1;
    } else {
      if (_diceResult > 6) {
        return 6;
      } else {
        return _diceResult;
      }
    }
  }

  bool get _diceStarted => state.diceStarted;

  LudoPlayer get currentPlayer =>
      state.players.firstWhere((player) => player.playerId == state.turn);

  ///Fill all players
  List<LudoPlayer> get players => state.players;

  List<int>? get playerOrder => state.playerOrder;

  Map<int, int> get points => state.points;

  Map<int, List<int>> get playerPosition => state.positions;


  ///Player win, we use `LudoPlayerType` to make it easier to check
  List<LudoPlayerType> get winners => state.winners;

  LudoPlayer player(LudoPlayerType type) =>
      players.firstWhere((element) => element.type == type);


  ///This method will check if the pawn can kill another pawn or not by checking the step of the pawn
  bool checkToKill(
      LudoPlayerType type, int index, int step, List<List<double>> path) {
    bool killSomeone = false;
    for (int i = 0; i < 4; i++) {
      var greenElement = player(LudoPlayerType.green).pawns[i];
      var blueElement = player(LudoPlayerType.blue).pawns[i];
      var redElement = player(LudoPlayerType.red).pawns[i];
      var yellowElement = player(LudoPlayerType.yellow).pawns[i];

      if ((greenElement.step > -1 &&
          !LudoPath.safeArea
              .map((e) => e.toString())
              .contains(player(LudoPlayerType.green)
              .path[greenElement.step]
              .toString())) &&
          type != LudoPlayerType.green) {
        if (player(LudoPlayerType.green)
            .path[greenElement.step]
            .toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.green).movePawn(i, -1);
        }
      }
      if ((yellowElement.step > -1 &&
          !LudoPath.safeArea
              .map((e) => e.toString())
              .contains(player(LudoPlayerType.yellow)
              .path[yellowElement.step]
              .toString())) &&
          type != LudoPlayerType.yellow) {
        if (player(LudoPlayerType.yellow)
            .path[yellowElement.step]
            .toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.yellow).movePawn(i, -1);
        }
      }
      if ((blueElement.step > -1 &&
          !LudoPath.safeArea
              .map((e) => e.toString())
              .contains(player(LudoPlayerType.blue)
              .path[blueElement.step]
              .toString())) &&
          type != LudoPlayerType.blue) {
        if (player(LudoPlayerType.blue)
            .path[blueElement.step]
            .toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.blue).movePawn(i, -1);
        }
      }
      if ((redElement.step > -1 &&
          !LudoPath.safeArea
              .map((e) => e.toString())
              .contains(player(LudoPlayerType.red)
              .path[redElement.step]
              .toString())) &&
          type != LudoPlayerType.red) {
        if (player(LudoPlayerType.red)
            .path[redElement.step]
            .toString() ==
            path[step - 1].toString()) {
          killSomeone = true;
          player(LudoPlayerType.red).movePawn(i, -1);
        }
      }
    }

    if (killSomeone) {
      state = state.copyWith();
    }

    return killSomeone;
  }

  ///This is the function that will be called to throw the dice
  void throwDice() async {
    if (gameState != LudoGameState.throwDice) return;
    state = state.copyWith(diceStarted: true);
    Audio.rollDice();

    if (winners.contains(currentPlayer.type)) {
      nextTurn();
      return;
    }

    currentPlayer.highlightAllPawns(false);

    Future.delayed(const Duration(seconds: 1)).then((value) {
      var random = Random();
      int result = random.nextBool() ? 6 : random.nextInt(6) + 1;
      state = state.copyWith(
        diceStarted: false,
        diceResult: result,
      );

      if (diceResult == 6) {
        currentPlayer.highlightAllPawns();
        state = state.copyWith(gameState: LudoGameState.pickPawn);
      } else {
        if (currentPlayer.pawnInsideCount == 4) {
          nextTurn();
          return;
        } else {
          currentPlayer.highlightOutside();
          state = state.copyWith(gameState: LudoGameState.pickPawn);
        }
      }

      for (var i = 0; i < currentPlayer.pawns.length; i++) {
        var pawn = currentPlayer.pawns[i];
        if ((pawn.step + diceResult) > currentPlayer.path.length - 1) {
          currentPlayer.highlightPawn(i, false);
        }
      }

      var moveablePawn =
      currentPlayer.pawns.where((e) => e.highlight).toList();
      if (moveablePawn.length > 1) {
        var biggestStep = moveablePawn.map((e) => e.step).reduce(max);
        if (moveablePawn.every((element) => element.step == biggestStep)) {
          var random = 1 + Random().nextInt(moveablePawn.length - 1);
          var thePawn = moveablePawn[random];
          if (thePawn.step == -1) {
            move(thePawn.type, thePawn.index, (thePawn.step + 1) + 1);
            return;
          } else {
            move(thePawn.type, thePawn.index,
                (thePawn.step + 1) + diceResult);
            return;
          }
        }
      }

      if (currentPlayer.pawns.every((element) => !element.highlight)) {
        if (diceResult == 6) {
          state = state.copyWith(gameState: LudoGameState.throwDice);
        } else {
          nextTurn();
          return;
        }
      }

      if (currentPlayer.pawns.where((element) => element.highlight).length ==
          1) {
        var index = currentPlayer.pawns
            .indexWhere((element) => element.highlight);
        move(currentPlayer.type, index,
            (currentPlayer.pawns[index].step + 1) + diceResult);
      }
    });
  }

  ///Move pawn to next step and check if it can kill other pawn
  void move(LudoPlayerType type, int index, int step) async {
    if (_isMoving) return;
    state = state.copyWith(
        isMoving: true, gameState: LudoGameState.moving);
    currentPlayer.highlightAllPawns(false);

    var selectedPlayer = player(type);
    for (int i = selectedPlayer.pawns[index].step; i < step; i++) {
      if (_stopMoving) break;
      if (selectedPlayer.pawns[index].step == i) continue;
      selectedPlayer.movePawn(index, i);
      await Audio.playMove();
      state = state.copyWith();
      if (_stopMoving) break;
    }

    if (checkToKill(type, index, step, selectedPlayer.path)) {
      Audio.playKill();
      state = state.copyWith(
        gameState: LudoGameState.throwDice,
        isMoving: false,
      );
      return;
    }

    validateWin(type);

    if (diceResult == 6) {
      state = state.copyWith(gameState: LudoGameState.throwDice);
    } else {
      nextTurn();
    }

    state = state.copyWith(isMoving: false);
  }

  ///Next turn will be called when the player finish the turn
  void nextTurn() {
    LudoPlayerType nextTurn;
    switch (_currentTurn) {
      case LudoPlayerType.green:
        nextTurn = LudoPlayerType.yellow;
        break;
      case LudoPlayerType.yellow:
        nextTurn = LudoPlayerType.blue;
        break;
      case LudoPlayerType.blue:
        nextTurn = LudoPlayerType.red;
        break;
      case LudoPlayerType.red:
        nextTurn = LudoPlayerType.green;
        break;
    }

    if (winners.contains(nextTurn)) {
      state = state.copyWith(currentTurn: nextTurn);
      nextTurn;
      return;
    }

    state = state.copyWith(
      currentTurn: nextTurn,
      gameState: LudoGameState.throwDice,
    );
  }

  ///This function will check if the pawn finish the game or not
  void validateWin(LudoPlayerType color) {
    if (winners.map((e) => e.name).contains(color.name)) return;
    if (player(color)
        .pawns
        .map((e) => e.step)
        .every((element) => element == player(color).path.length - 1)) {
      state = state.copyWith(winners: [...winners, color]);
    }

    if (state.winners.length == 3) {
      state = state.copyWith(gameState: LudoGameState.finish);
    }
  }


  void startGame() {
    final order = state.playerOrder ?? [];
    final startOffsets = state.startOffsets;
    final dices = state.dice ??[];

    // Define player types for each corner (assumed order: 0 - green, 1 - yellow, etc.)
    final corners = [
      LudoPlayerType.green,
      LudoPlayerType.yellow,
      LudoPlayerType.blue,
      LudoPlayerType.red,
    ];

    final List<LudoPlayer> playerList = [];

    for (int i = 0; i < order.length && i < 4; i++) {
      final playerId = order[i];
      // final type = corners[i];
      final offset = startOffsets[playerId] ?? 0;
      final corner = _cornerForOffset(offset);
      final type = _playerTypeForCorner(corner);
      final initialStep = 0;
      // final initialStep = dices.isNotEmpty && dices.length > 1 ? 0 :-1;

      playerList.add(
        LudoPlayer(
          type,playerId,corner,initialStep: initialStep
        ),
      );
    }

    state = state.copyWith(
      winners: [],
      players: playerList,
    );
  }

  int _cornerForOffset(int offset) {
    switch (offset) {
      case 0:
        return 0; // green
      case 39:
        return 1; // yellow
      case 13:
        return 2; // red
      case 26:
        return 3; // blue
      default:
        return 0;
    }
  }

  LudoPlayerType _playerTypeForCorner(int corner) {
    switch (corner) {
      case 0:
        return LudoPlayerType.green;
      case 1:
        return LudoPlayerType.yellow;
      case 2:
        return LudoPlayerType.red;
      case 3:
        return LudoPlayerType.blue;
      default:
        return LudoPlayerType.green;
    }
  }






  // void startGame() {
  //   state = state.copyWith(
  //     winners: [],
  //     players: [
  //       LudoPlayer(LudoPlayerType.green),
  //       LudoPlayer(LudoPlayerType.yellow),
  //       LudoPlayer(LudoPlayerType.blue),
  //       LudoPlayer(LudoPlayerType.red),
  //     ],
  //   );
  // }
  @override
  void dispose() {
    debugPrint('❌ Disposing GameStateNotifier');
    _sub?.cancel();
    socket.close();
    super.dispose();
  }
}

final ludoStateNotifier =
StateNotifierProvider.family<LudoStateNotifier, LudoState, int>((ref, id) {
  final notifier = LudoStateNotifier();
  unawaited(notifier.connect(id.toString()));
  return notifier;
});