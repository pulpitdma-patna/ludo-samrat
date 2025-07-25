import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/screens/tournament_list_screen.dart';
import 'package:frontend/providers/tournament_provider.dart';
import 'package:frontend/services/tournament_api.dart';

class FakeTournamentProvider extends TournamentProvider {
  final List<dynamic> _tournaments;
  FakeTournamentProvider(this._tournaments) : super(api: TournamentApi());

  @override
  Future<void> load() async {}

  @override
  Future<void> getTournaments() async {}

  @override
  Future<void> getMyStats() async {}

  @override
  List<dynamic> get allTournaments => _tournaments;

  @override
  bool get isLoading => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows View when tournament already joined', (tester) async {
    final provider = FakeTournamentProvider([
      {
        'id': 1,
        'name': 'Cup',
        'start_time': '2024-01-01T10:00:00Z',
        'join_fee': 0,
        'prize_slab': [],
        'seat_limit': 2,
        'joined': 1,
        'is_active': true,
        'has_joined': true,
      }
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<TournamentProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: TournamentListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('View'), findsOneWidget);
    expect(find.textContaining('Jan'), findsOneWidget);
  });
}
