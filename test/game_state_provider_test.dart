import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/providers/game_state_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/app_preferences.dart';

class FakeSocketService implements SocketService {
  final StreamController<dynamic> _controller = StreamController.broadcast();
  final StreamController<ConnectionState> _status = StreamController.broadcast();
  @override
  Stream get stream => _controller.stream;
  @override
  Stream<ConnectionState> get connectionStatus => _status.stream;

  void addData(dynamic data) => _controller.add(data);

  @override
  void connect(String gameId, {String? token}) {
    _status.add(ConnectionState.connected);
  }

  @override
  void send(Map<String, dynamic> data) {}

  @override
  void close() {
    _controller.close();
    _status.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('updates state from incoming socket messages', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();

    final socket = FakeSocketService();
    final notifier = GameStateNotifier(socketService: socket);

    await notifier.connect('1');

    socket.addData({
      'type': 'state',
      'state': {
        'positions': {'0': [5]},
        'turn': 0,
        'dice': 4,
      }
    });
    await Future.delayed(Duration.zero);

    expect(notifier.state.positions[0]![0], 5);
    expect(notifier.state.turn, 0);
    expect(notifier.state.dice, [4]);

    socket.addData({'type': 'roll', 'dice': 2});
    await Future.delayed(Duration.zero);

    expect(notifier.state.dice, [2]);
  });

  test('ignores unrelated socket messages', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();

    final socket = FakeSocketService();
    final notifier = GameStateNotifier(socketService: socket);

    await notifier.connect('1');

    socket.addData({'type': 'connection', 'status': 'ok'});
    socket.addData({'type': 'player_joined', 'player_id': 1});
    socket.addData({'type': 'player_left', 'player_id': 1});
    await Future.delayed(Duration.zero);

    expect(notifier.state.positions.isEmpty, true);
    expect(notifier.state.dice, isNull);
    expect(notifier.state.turn, isNull);
  });

  test('calculates moves using selected die', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();

    final socket = FakeSocketService();
    final notifier = GameStateNotifier(socketService: socket);

    await notifier.connect('1');

    socket.addData({
      'type': 'state',
      'state': {
        'positions': {'0': [0]},
        'turn': 0,
        'dice': [1, 6]
      }
    });
    await Future.delayed(Duration.zero);

    notifier.selectDie(6);

    expect(notifier.state.selectedDie, 6);
    expect(notifier.state.allowedMoves[0]![0], 6);
  });
}
