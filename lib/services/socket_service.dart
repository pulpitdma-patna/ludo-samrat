import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config.dart';

enum ConnectionState { connecting, connected, disconnected }

class SocketService {
  WebSocketChannel? _channel;
  final _dataController = StreamController.broadcast();
  final _connectionController = StreamController<ConnectionState>.broadcast();

  bool _manualClose = false;
  Uri? _uri;
  String? _token;

  int _reconnectAttempts = 0;

  final WebSocketChannel Function(Uri uri)? _channelFactory;

  SocketService({WebSocketChannel Function(Uri uri)? channelFactory})
      : _channelFactory = channelFactory;

  /*void connect(String gameId, {String? token}) {
    final base = Uri.parse(apiUrl);
    final secure = base.scheme == 'https' || base.scheme == 'wss';
    final scheme = secure ? 'wss' : 'ws';
    final host = base.host;
    final port = base.hasPort ? base.port : (secure ? 443 : 80);

    _token = token;

    final params = <String, String>{};
    if (token != null) {
      params['token'] = token;
    }

    final path = (base.path.endsWith('/'))
        ? '${base.path}game/ws/$gameId'
        : '${base.path}/game/ws/$gameId';

    _uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      queryParameters: params.isEmpty ? null : params,
    );

    log('🟢 Connecting to WebSocket at $_uri');

    try {
      _open();
    } on WebSocketException catch (e) {
      log('❌ WebSocketException: $e');
      throw Exception('Invalid token or endpoint');
    } on WebSocketChannelException catch (e) {
      log('❌ WebSocketChannelException: $e');
      _handleDisconnect(e);
    }
  }*/


  void connect(String gameId, {String? token}) {
    final base = Uri.parse(apiUrl);
    final secure = base.scheme == 'https' || base.scheme == 'wss';
    final scheme = secure ? 'wss' : 'ws';
    final host = base.host;
    final port = base.hasPort ? base.port : (secure ? 443 : 80);

    _token = token;

    final params = <String, String>{};
    if (token != null) {
      params['token'] = token;
    }

    // Always use static WebSocket path
    final path = '/game/ws/$gameId';

    _uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      queryParameters: params.isEmpty ? null : params,
    );

    log('🟢 Connecting to WebSocket at $_uri');

    try {
      _open();
    } on WebSocketException catch (e) {
      log('❌ WebSocketException: $e');
      throw Exception('Invalid token or endpoint');
    } on WebSocketChannelException catch (e) {
      log('❌ WebSocketChannelException: $e');
      _handleDisconnect(e);
    }
  }


  void _open() {
    if (_uri == null) return;

    if (kDebugMode) {
      log('🟢 Connecting to WebSocket at $_uri');
    }

    _connectionController.add(ConnectionState.connecting);

    try {
      _channel = (_channelFactory != null)
          ? _channelFactory!(_uri!)
          : IOWebSocketChannel.connect(
        _uri!,
        headers: {
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
    } on WebSocketException {
      rethrow;
    } on WebSocketChannelException catch (e) {
      log('❌ WebSocketChannelException: $e');
      _handleDisconnect(e);
      return;
    } catch (e) {
      log('❌ Failed to connect WebSocket: $e');
      _handleDisconnect(e);
      return;
    }

    _connectionController.add(ConnectionState.connected);
    _reconnectAttempts = 0;

    _channel!.stream.listen(
          (event) {
        if (kDebugMode) {
          log('📩 Incoming message: $event');
        }
        _dataController.add(event);
      },
      onError: (err) {
        log('❌ WebSocket stream error: $err');
        _handleDisconnect(err);
      },
      onDone: () {
        log('🔌 WebSocket closed by server');
        _handleDisconnect();
      },
      cancelOnError: true,
    );
  }


/*  void _open() {
    if (_uri == null) return;

    if (kDebugMode) {
      log('🟢 Connecting to WebSocket at $_uri');
    }


    _connectionController.add(ConnectionState.connecting);

    try {
      _channel = (_channelFactory != null
          ? _channelFactory!(_uri!)
          : WebSocketChannel.connect(_uri!));
    } on WebSocketException {
      // Propagate to allow UI handling.
      rethrow;
    } on WebSocketChannelException catch (e) {
      log('❌ WebSocketChannelException: $e');
      _handleDisconnect(e);
      return;
    } catch (e) {
      log('❌ Failed to connect WebSocket: $e');
      _handleDisconnect(e);
      return;
    }

    _connectionController.add(ConnectionState.connected);
    _reconnectAttempts = 0;

    _channel!.stream.listen(
            (event) {
          if (kDebugMode) {
            log('📩 Incoming message: $event');
          }
          _dataController.add(event);
        },
        onError: (err) {
          log('❌ WebSocket stream error: $err');
          _handleDisconnect(err);
        },
        onDone: () {
          log('🔌 WebSocket closed by server');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
  }*/

  void _handleDisconnect([dynamic error]) {
    log('🔴 Disconnected. Reason: $error');
    _channel = null;
    _connectionController.add(ConnectionState.disconnected);

    if (!_manualClose) {
      final delaySeconds = 1 << (_reconnectAttempts < 5 ? _reconnectAttempts : 5);
      _reconnectAttempts++;
      if (kDebugMode) {
        log('🔁 Reconnecting in $delaySeconds seconds...');
      }
      Future.delayed(Duration(seconds: delaySeconds), _open);
    }
  }

  Stream get stream => _dataController.stream;
  Stream<ConnectionState> get connectionStatus => _connectionController.stream;

  void send(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    if (kDebugMode) {
      log('📤 Sending message: $json');
    }
    _channel?.sink.add(json);
  }

  void close() {
    if (kDebugMode) {
      log('🛑 Closing WebSocket connection manually.');
    }
    _manualClose = true;
    _channel?.sink.close();
    _channel = null;
    _connectionController.add(ConnectionState.disconnected);
  }
}


















// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
//
// import '../config.dart';
//
// enum ConnectionState { connecting, connected, disconnected }
//
// class SocketService {
//   WebSocketChannel? _channel;
//   final _dataController = StreamController.broadcast();
//   final _connectionController = StreamController<ConnectionState>.broadcast();
//
//   bool _manualClose = false;
//   Uri? _uri;
//   String? _token;
//
//   int _reconnectAttempts = 0;
//
//   final WebSocketChannel Function(Uri uri)? _channelFactory;
//
//   SocketService({WebSocketChannel Function(Uri uri)? channelFactory})
//       : _channelFactory = channelFactory;
//
//   void connect(String gameId, {String? token}) {
//     final base = Uri.parse(apiUrl);
//     final secure = base.scheme == 'https' || base.scheme == 'wss';
//     final scheme = secure ? 'wss' : 'ws';
//     final host = base.host;
//     final port = base.hasPort ? base.port : (secure ? 443 : 80);
//
//     _token = token;
//
//     final params = <String, String>{};
//     if (token != null) {
//       params['token'] = token;
//     }
//
//     final path = (base.path.endsWith('/'))
//         ? '${base.path}game/ws/$gameId'
//         : '${base.path}/game/ws/$gameId';
//
//     _uri = Uri(
//       scheme: scheme,
//       host: host,
//       port: port,
//       path: path,
//       queryParameters: params.isEmpty ? null : params,
//     );
//
//     log('🟢 Connecting to WebSocket at $_uri');
//
//     try {
//       _open();
//     } on WebSocketException catch (e) {
//       log('❌ WebSocketException: $e');
//       throw Exception('Invalid token or endpoint');
//     } on WebSocketChannelException catch (e) {
//       log('❌ WebSocketChannelException: $e');
//       _handleDisconnect(e);
//     }
//   }
//
//
//   void _open() {
//     if (_uri == null) return;
//
//     if (kDebugMode) {
//       log('🟢 Connecting to WebSocket at $_uri');
//     }
//
//
//     _connectionController.add(ConnectionState.connecting);
//
//     try {
//       _channel = (_channelFactory != null
//           ? _channelFactory!(_uri!)
//           : WebSocketChannel.connect(_uri!));
//     } on WebSocketException {
//       // Propagate to allow UI handling.
//       rethrow;
//     } on WebSocketChannelException catch (e) {
//       log('❌ WebSocketChannelException: $e');
//       _handleDisconnect(e);
//       return;
//     } catch (e) {
//       log('❌ Failed to connect WebSocket: $e');
//       _handleDisconnect(e);
//       return;
//     }
//
//     _connectionController.add(ConnectionState.connected);
//     _reconnectAttempts = 0;
//
//     _channel!.stream.listen(
//             (event) {
//           if (kDebugMode) {
//             log('📩 Incoming message: $event');
//           }
//           _dataController.add(event);
//         },
//         onError: (err) {
//           log('❌ WebSocket stream error: $err');
//           _handleDisconnect(err);
//         },
//         onDone: () {
//           log('🔌 WebSocket closed by server');
//           _handleDisconnect();
//         },
//         cancelOnError: true,
//       );
//   }
//
//   void _handleDisconnect([dynamic error]) {
//     log('🔴 Disconnected. Reason: $error');
//     _channel = null;
//     _connectionController.add(ConnectionState.disconnected);
//
//     if (!_manualClose) {
//       final delaySeconds = 1 << (_reconnectAttempts < 5 ? _reconnectAttempts : 5);
//       _reconnectAttempts++;
//       if (kDebugMode) {
//         log('🔁 Reconnecting in $delaySeconds seconds...');
//       }
//       Future.delayed(Duration(seconds: delaySeconds), _open);
//     }
//   }
//
//   Stream get stream => _dataController.stream;
//   Stream<ConnectionState> get connectionStatus => _connectionController.stream;
//
//   void send(Map<String, dynamic> data) {
//     final json = jsonEncode(data);
//     if (kDebugMode) {
//       log('📤 Sending message: $json');
//     }
//     _channel?.sink.add(json);
//   }
//
//   void close() {
//     if (kDebugMode) {
//       log('🛑 Closing WebSocket connection manually.');
//     }
//     _manualClose = true;
//     _channel?.sink.close();
//     _channel = null;
//     _connectionController.add(ConnectionState.disconnected);
//   }
// }
