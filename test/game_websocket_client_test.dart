import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:frontend/services/game_websocket_client.dart';

class FakeWebSocketChannel with StreamChannelMixin implements WebSocketChannel {
  final StreamController<dynamic> _serverController = StreamController();
  final StreamController<dynamic> _clientController = StreamController();
  final List<dynamic> sent = [];

  FakeWebSocketChannel() {
    _clientController.stream.listen(sent.add);
  }

  void closeFromServer() {
    _serverController.close();
  }

  void addServerMessage(dynamic message) {
    _serverController.add(message);
  }

  @override
  Stream get stream => _serverController.stream;

  @override
  WebSocketSink get sink => _fakeSink ??= _FakeWebSocketSink(_clientController.sink);

  _FakeWebSocketSink? _fakeSink;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();
}

class _FakeWebSocketSink implements WebSocketSink {
  final StreamSink _inner;

  _FakeWebSocketSink(this._inner);

  @override
  void add(data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<dynamic> stream) => _inner.addStream(stream);

  @override
  Future close([int? closeCode, String? closeReason]) => _inner.close();

  @override
  Future get done => _inner.done;

  void addUtf8Text(List<int> bytes) => _inner.add(utf8.decode(bytes));
}

void main() {
  test('reconnects with exponential backoff and stops after max attempts', () {
    fakeAsync((async) {
      final channels = <FakeWebSocketChannel>[];
      final client = GameWebSocketClient(
        Uri.parse('ws://localhost'),
        maxReconnectAttempts: 2,
        channelFactory: (uri) {
          final ch = FakeWebSocketChannel();
          channels.add(ch);
          return ch;
        },
      );

      client.connect();
      expect(channels.length, 1);

      channels.last.closeFromServer();
      async.elapse(const Duration(seconds: 1));
      expect(channels.length, 2);

      channels.last.closeFromServer();
      async.elapse(const Duration(seconds: 2));
      // No new connection because max attempts reached
      expect(channels.length, 2);
    });
  });

  test('parses incoming messages', () async {
    final channel = FakeWebSocketChannel();
    final joined = <int>[];
    final left = <int>[];
    Map<String, dynamic>? state;

    final client = GameWebSocketClient(
      Uri.parse('ws://localhost'),
      channelFactory: (_) => channel,
      handlePlayerJoined: joined.add,
      handlePlayerLeft: left.add,
      updateGameState: (s) => state = s,
    );

    client.connect();
    channel.addServerMessage(jsonEncode({'type': 'player_joined', 'player_id': 1}));
    await Future.delayed(Duration.zero);
    expect(joined, [1]);

    channel.addServerMessage(jsonEncode({'type': 'player_left', 'player_id': 2}));
    await Future.delayed(Duration.zero);
    expect(left, [2]);

    channel.addServerMessage(jsonEncode({'type': 'state', 'state': {'a': 1}}));
    await Future.delayed(Duration.zero);
    expect(state?['a'], 1);
  });
}
