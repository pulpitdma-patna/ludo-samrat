import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Connection status values reported by [GameWebSocketClient].
enum GameConnectionStatus { connecting, connected, disconnected, failed }

/// Simple WebSocket manager for game updates.
///
/// Automatically reconnects with exponential backoff and exposes callbacks for
/// common server messages. Reconnection stops after [maxReconnectAttempts] to
/// avoid endless retries when the server or DNS is unreachable.
class GameWebSocketClient {
  GameWebSocketClient(
    this._uri, {
    this.handlePlayerJoined,
    this.handlePlayerLeft,
    this.updateGameState,
    this.onConnectionStatus,
    this.maxReconnectAttempts = 5,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final Uri _uri;
  final WebSocketChannel Function(Uri uri) _channelFactory;

  final void Function(int playerId)? handlePlayerJoined;
  final void Function(int playerId)? handlePlayerLeft;
  final void Function(Map<String, dynamic> state)? updateGameState;
  final void Function(GameConnectionStatus status)? onConnectionStatus;

  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int _reconnectAttempts = 0;
  bool _manualClose = false;

  /// Start (or restart) the connection.
  void connect() {
    _manualClose = false;
    _reconnectAttempts = 0;
    _open();
  }

  void _open() {
    onConnectionStatus?.call(GameConnectionStatus.connecting);
    try {
      _channel = _channelFactory(_uri);
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: () => _handleError('WebSocket closed by server'),
        cancelOnError: true,
      );
      onConnectionStatus?.call(GameConnectionStatus.connected);
      log('🟢 Connected to $_uri');
    } on SocketException catch (e) {
      log('❌ SocketException: $e');
      _scheduleReconnect(e);
    } on WebSocketChannelException catch (e) {
      log('❌ WebSocketChannelException: $e');
      _scheduleReconnect(e);
    } catch (e) {
      log('❌ Failed to connect: $e');
      _scheduleReconnect(e);
    }
  }

  void _handleMessage(dynamic data) {
    log('📩 $data');
    try {
      final Map msg = data is String ? jsonDecode(data) : data as Map;
      final type = msg['type'];
      switch (type) {
        case 'connection':
          final status = msg['status'] as String?;
          log('Connection status: $status');
          break;
        case 'player_joined':
          final id = msg['player_id'];
          if (id is int) handlePlayerJoined?.call(id);
          break;
        case 'player_left':
          final id = msg['player_id'];
          if (id is int) handlePlayerLeft?.call(id);
          break;
        case 'state':
          final state = msg['state'];
          if (state is Map) {
            updateGameState?.call(Map<String, dynamic>.from(state));
          }
          break;
        default:
          log('⚠️ Unknown message type: $msg');
      }
    } catch (e) {
      log('❌ Failed to process message: $e');
    }
  }

  void _handleError(dynamic error) {
    log('🔴 Disconnected: $error');
    onConnectionStatus?.call(GameConnectionStatus.disconnected);
    _channel = null;
    _subscription?.cancel();
    _scheduleReconnect(error);
  }

  void _scheduleReconnect(dynamic error) {
    if (_manualClose) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      log('🛑 Max reconnect attempts reached.');
      onConnectionStatus?.call(GameConnectionStatus.failed);
      return;
    }

    // Exponential backoff up to 32 seconds.
    final delay = Duration(seconds: 1 << (_reconnectAttempts <= 5 ? _reconnectAttempts : 5));
    _reconnectAttempts++;
    log('🔁 Reconnecting in ${delay.inSeconds}s...');
    Future.delayed(delay, _open);
  }

  /// Send a JSON-encodable map through the socket.
  void send(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    _channel?.sink.add(json);
  }

  /// Close the connection and stop reconnect attempts.
  void close() {
    _manualClose = true;
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    onConnectionStatus?.call(GameConnectionStatus.disconnected);
  }
}
