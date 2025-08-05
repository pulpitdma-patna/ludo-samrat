import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // final WebSocketChannel Function(Uri uri)? _channelFactory;

  // SocketService({WebSocketChannel Function(Uri uri)? channelFactory})
  //     : _channelFactory = channelFactory;



/*  void connect(String gameId, String token) {
    final base = Uri.parse(socketBaseUrl); // e.g. wss://ludosamrat.com
    final scheme = "wss";
    final host = base.host;
    final port = base.hasPort ? base.port : 443;
    final path = '/game/ws/$gameId';

    _token = token;

    final params = <String, String>{};
    if (token.isNotEmpty) {
      params['token'] = token;
    }

    _uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      queryParameters: params,
    );

    log('🔍 Final WebSocket URI: $_uri');
    log('✅ Final URI Scheme: ${_uri!.scheme}');

    try {
      _open(); // should use _uri directly
    } on WebSocketException catch (e) {
      log('❌ WebSocketException: $e');
      throw Exception('Invalid token or endpoint');
    } on WebSocketChannelException catch (e) {
      log('❌ WebSocketChannelException: $e');
      _handleDisconnect(e);
    }
  }*/




  void connect(String gameId, String token) {

    final encodedToken = Uri.encodeQueryComponent(token.trim());

    final base = Uri.parse(socketBaseUrl);
    // final isSecure = base.scheme == 'https' || base.scheme == 'wss';
    final isSecure = base.scheme == 'https' || base.scheme == 'wss';
    final scheme = isSecure ? 'wss' : 'ws';
    final host = base.host;
    final port = base.hasPort ? base.port : (isSecure ? 443 : 80);

    _token = token;

    // Append gameId to the base path (e.g., /api/game/ws/251)
    final path = base.path.endsWith('/')
        ? '${base.path}$gameId'
        : '${base.path}/$gameId';

    _uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      queryParameters: {'token': encodedToken},
    );

    // 🛑 Remove # from URI string if exists (last resort)
    final finalUriString = _uri.toString().replaceAll('#', '');

    // Parse cleaned URI
    _uri = Uri.parse(finalUriString);

    log('🟢 Final WebSocket URI (cleaned): $_uri');

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

  Future<void> _open() async {
    if (_uri == null) return;

    // Convert to string and clean up hash + ensure wss scheme
    final cleanedUri = Uri.parse(
        _uri.toString()
            .replaceAll('#', '')               // Remove any fragment
            .replaceFirst('http://', 'ws://')  // Ensure ws
            .replaceFirst('https://', 'wss://')
    );

    // ✅ Check if the scheme is valid
    if (cleanedUri.scheme != 'ws' && cleanedUri.scheme != 'wss') {
      log('❌ Invalid WebSocket scheme: ${cleanedUri.scheme}');
      _connectionController.add(ConnectionState.disconnected);
      _dataController.addError('Invalid WebSocket URL scheme: ${cleanedUri.scheme}');
      return;
    }

    if (kDebugMode) {
      log('🟢 Connecting to WebSocket at $cleanedUri');
    }

    _connectionController.add(ConnectionState.connecting);

    try {

      _channel = WebSocketChannel.connect(
          cleanedUri
        // Uri.parse('wss://ludosamrat.com:443/api/game/ws/255?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwiZXhwIjoxNzU0Mzk0MjU3LCJpYXQiOjE3NTQzOTI0NTcsIm5iZiI6MTc1NDM5MjQ1NywiaXNzIjoibHVkby1zYW1yYXQiLCJhdWQiOiJsdWRvLXNhbXJhdC1hcGkiLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZDIzZjJjZmRhNmIwYTRkZCJ9.OMHVG1v1tlf6BAFLeZvBVYWgdHuQ0fVuXrxLOENMkvc'),
      );

      await _channel?.ready;

      log('🟢 Successfully connected to WebSocket at $cleanedUri');

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



    } on WebSocketException catch (e) {
      log('❌ WebSocketException: $e');
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

// This ensures only one instance of SocketService is created and reused.
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});


















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
