import 'package:flutter/material.dart';
import '../services/tournament_api.dart';
import '../services/analytics_service.dart';
import '../services/api_result.dart';
import '../utils/api_helpers.dart';
import '../services/app_preferences.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentApi api;
  TournamentProvider({TournamentApi? api}) : api = api ?? TournamentApi() {
    load();
  }

  List<dynamic> _activeTournaments = [];
  bool _loading = false;

  List<dynamic> get activeTournaments => _activeTournaments;
  bool get isLoading => _loading;


  List<dynamic> _allTournaments = [];
  List<dynamic> get allTournaments => _allTournaments;

  double? _minFee;
  double? get minFee => _minFee;

  double? _maxFee;
  double? get maxFee => _maxFee;

  Map<String,dynamic> _myStatesData = {};
  Map<String,dynamic> get myStatesData => _myStatesData;

  Map<String, dynamic>? _tournament;
  Map<String, dynamic>? get tournament => _tournament;

  Map<String, dynamic>? _bracket;
  Map<String, dynamic>? get bracket => _bracket;

  bool _hasJoined = false;
  bool get hasJoined => _hasJoined;

  List<dynamic> _participants = [];
  List<dynamic> get participants => _participants;

  List<dynamic> _leaderboard = [];
  List<dynamic> get leaderboard => _leaderboard;

  void setMinFee(double? value) {
    _minFee = value;
    notifyListeners();
  }

  void setMaxFee(double? value) {
    _maxFee = value;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _activeTournaments = await api.activeTournament();
    _loading = false;
    notifyListeners();
  }

  Future<ApiResult<Map<String, dynamic>>> join(int id, BuildContext ctx) async {
    final res = await api.join(id);
    await handleAuthError(res, ctx);
    if (res.isSuccess) {
      await AnalyticsService.logTournamentJoin(id);
      // refresh tournaments and stats so UI reflects the joined state
      getTournaments();
      getMyStats();
    }
    return res;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.create(data);
    await load();
  }

  Future<void> getTournaments() async {
    _loading = true;
    notifyListeners();
    clearData();
    _allTournaments = await api.allTournament(
      minFee: _minFee,
      maxFee: _maxFee,
    );
    _loading = false;
    notifyListeners();
  }

  Future<void> getMyStats() async {
    _loading = true;
    notifyListeners();
    final res = await api.getMyStats();
    if(res != null){
      _myStatesData = res;
    }else{
      _myStatesData = {};
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchTournament(int id) async {
    _loading = true;
    notifyListeners();
    _tournament = await api.tournament(id);
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchParticipants(int id) async {
    _loading = true;
    notifyListeners();
    _participants = await api.participants(id);
    final uid = await AppPreferences().getUserId();
    _hasJoined = _participants.any((p) => p['user_id'] == uid);
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchLeaderboard(int id) async {
    _loading = true;
    notifyListeners();
    _leaderboard = await api.leaderboard(id);
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchBracket(int id) async {
    _loading = true;
    notifyListeners();
    _bracket = await api.getBracket(id);
    _loading = false;
    notifyListeners();
  }

  Future<void> loadOverview(int id) async {
    _loading = true;
    notifyListeners();
    final t = await api.getTournament(id);
    final p = await api.getParticipants(id);
    final b = await api.getBracket(id);
    final uid = await AppPreferences().getUserId();
    _tournament = t;
    _participants = p;
    _bracket = b;
    _hasJoined = _participants.any((e) => e['user_id'] == uid);
    _loading = false;
    notifyListeners();
  }

  clearData() {
    _tournament = null;
    _participants = [];
    _leaderboard = [];
    _bracket = null;
    _hasJoined = false;
  }

}
