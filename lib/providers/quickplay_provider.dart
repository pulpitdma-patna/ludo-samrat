import 'package:flutter/material.dart';
import '../services/quickplay_api.dart';
import '../services/api_result.dart';
import '../utils/api_helpers.dart';

class QuickPlayProvider extends ChangeNotifier {
  final QuickPlayApi api;
  QuickPlayProvider({QuickPlayApi? api}) : api = api ?? QuickPlayApi();

  bool _loading = false;
  bool get isLoading => _loading;

  List<dynamic> _allRooms = [];
  List<dynamic> get allRooms => _allRooms;

  Future<void> getRooms({String? q, double? minStake, double? maxStake}) async {
    _loading = true;
    notifyListeners();
    final res = await api.listRooms(q: q, minStake: minStake, maxStake: maxStake);
    if (res.isSuccess) {
      _allRooms = res.data ?? [];
    } else {
      // reset to avoid showing stale rooms when the request fails
      _allRooms = [];
    }
    _loading = false;
    notifyListeners();
  }

  /// Join the quick play room and return the raw API response. The response
  /// may contain a `game_id` when a match is ready to start.
  Future<ApiResult<Map<String, dynamic>>> joinRoom(
      int id, BuildContext ctx, {bool ai = false}) async {
    final res = await api.joinRoom(id, ai: ai);
    await handleAuthError(res, ctx);
    if (res.isSuccess) {
      // refresh room list but don't alter the API result
      await getRooms();
    }
    return res;
  }


  void clearData() {
    _allRooms.clear();
  }
}
