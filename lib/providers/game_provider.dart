import 'package:flutter/material.dart';
import '../services/game_api.dart';
import '../services/api_result.dart';
import '../utils/api_helpers.dart';

class GameProvider extends ChangeNotifier {
  final GameApi api;
  GameProvider({GameApi? api}) : api = api ?? GameApi();

  final Map<int, int> _roomByGame = {}; // gameId -> roomId
  final Map<int, int> _matchByGame = {}; // gameId -> matchId

  void registerQuickPlay(int gameId, int roomId, int matchId) {
    _roomByGame[gameId] = roomId;
    _matchByGame[gameId] = matchId;
  }

  int? roomIdForGame(int gameId) => _roomByGame[gameId];
  int? matchIdForGame(int gameId) => _matchByGame[gameId];

  bool _loading = false;
  bool get isLoading => _loading;

  List<dynamic> _recentGames = [];
  List<dynamic> get recentGames => _recentGames;

  Future<void> loadRecentGames() async {
    _loading = true;
    notifyListeners();
    // _recentGames = await api.recentGames();
    final res = await api.recentGames();
    // final res = await ProfileApi().matchHistory();
    if (res.isSuccess) {
      _recentGames = res.data ?? [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<ApiResult<int?>> queueGame({
    int maxPlayers = 2,
    double joinFee = 0.0,
    bool ai = false,
    required BuildContext ctx,
  }) async {
    _loading = true;
    notifyListeners();
    final res =
        await api.queueGame(maxPlayers: maxPlayers, joinFee: joinFee, ai: ai);
    await handleAuthError(res, ctx);
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<ApiResult<void>> leaveQueue(BuildContext ctx) async {
    _loading = true;
    notifyListeners();
    final res = await api.leaveQueue();
    await handleAuthError(res, ctx);
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<ApiResult<void>> joinGame(int gameId,
      {String? color, required BuildContext ctx}) async {
    _loading = true;
    notifyListeners();
    final res = await api.joinGame(gameId, color: color);
    await handleAuthError(res, ctx);
    _loading = false;
    notifyListeners();
    return res;
  }

  Future<ApiResult<Map<String, dynamic>>> quickMatch({
    required int playerCount,
    required int stake,
    required BuildContext ctx,
  }) async {
    final res = await api.createRoom(playerCount: playerCount, stake: stake);
    await handleAuthError(res, ctx);
    if (!res.isSuccess || res.data == null) {
      return res;
    }

    final data = res.data!;
    final roomId = data['room_id'] ?? data['id'] ?? data['roomId'];
    if (roomId is! int) {
      return ApiResult.failure('Invalid room id');
    }

    final joinRes = await api.joinRoom(roomId);
    await handleAuthError(joinRes, ctx);
    if (joinRes.isSuccess && joinRes.data != null) {
      return joinRes;
    }
    return joinRes;
  }

  Future<ApiResult<Map<String, dynamic>>> endQuickPlay(
      int roomId, int matchId, int winnerId, BuildContext ctx) async {
    _loading = true;
    notifyListeners();
    final res = await api.endRoom(roomId, matchId, winnerId);
    await handleAuthError(res, ctx);
    _loading = false;
    notifyListeners();
    return res;
  }


}
