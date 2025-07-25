import 'dart:async';
import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';
import 'dart:io';
import 'package:frontend/services/socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:frontend/config.dart';
import 'dart:convert';

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
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<dynamic> stream) => _inner.addStream(stream);

  @override
  Future close([int? closeCode, String? closeReason]) => _inner.close();

  @override
  Future get done => _inner.done;

  void addUtf8Text(List<int> bytes) => _inner.add(utf8.decode(bytes));
}

void main() {
  test('reconnects with exponential backoff', () {
    fakeAsync((async) {
      final channels = <FakeWebSocketChannel>[];
      final service = SocketService(channelFactory: (uri) {
        final ch = FakeWebSocketChannel();
        channels.add(ch);
        return ch;
      });

      service.connect('1');
      expect(channels.length, 1);

      channels.last.closeFromServer();
      async.elapse(const Duration(seconds: 1));
      expect(channels.length, 2);

      channels.last.closeFromServer();
      async.elapse(const Duration(seconds: 2));
      expect(channels.length, 3);
    });
  });

  test('sends encoded messages through the channel', () {
    final channel = FakeWebSocketChannel();
    final service = SocketService(channelFactory: (_) => channel);

    service.connect('1');
    service.send({'a': 1});

    expect(channel.sent.first, '{"a":1}');
  });

  test('connect incorporates base path from apiUrl', () {
    Uri? uri;
    final service = SocketService(channelFactory: (u) {
      uri = u;
      return FakeWebSocketChannel();
    });

    service.connect('42');

    expect(uri?.path, '/api/game/ws/42');
  });

  test('connect works when apiUrl has no path', () {
    // Run this test with --dart-define=API_URL=https://example.com
    if (!apiUrl.startsWith('https://example.com')) return;

    Uri? uri;
    final service = SocketService(channelFactory: (u) {
      uri = u;
      return FakeWebSocketChannel();
    });

    service.connect('42');

    expect(uri?.path, '/game/ws/42');
  });

  test('connect adds token query parameter', () {
    Uri? uri;
    final service = SocketService(channelFactory: (u) {
      uri = u;
      return FakeWebSocketChannel();
    });

    service.connect('99', token: 'abc');

    expect(uri?.queryParameters['token'], 'abc');
  });

  test('throws descriptive error when WebSocket fails', () {
    final service = SocketService(channelFactory: (_) {
      throw WebSocketException('Bad');
    });

    expect(
      () => service.connect('1'),
      throwsA(predicate((e) =>
          e is Exception && e.toString().contains('Invalid token or endpoint'))),
    );
  });
}
