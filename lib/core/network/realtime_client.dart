import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/chat/models/chat_message.dart';
import '../config/app_config.dart';
import '../services/auth_session.dart';

/// A chat event for one consultation: a new message, or a status change
/// (for example the doctor closed it).
class ConsultationEvent {
  const ConsultationEvent({
    required this.consultationId,
    this.message,
    this.status,
  });

  final String consultationId;
  final ChatMessage? message;
  final String? status;
}

/// Live connection to the backend's Socket.IO server.
///
/// The server sends `consultation:message` and `consultation:updated` to the
/// two people in a consultation. Screens listen with [eventsFor]; nothing is
/// sent over the socket from the app, messages still go through the REST API.
/// Event decoding lives in [handleEvent] so it can be tested without a socket.
class RealtimeClient {
  RealtimeClient({String? url}) : _url = url;

  final String? _url;
  io.Socket? _socket;
  String? _tokenInUse;
  final _events = StreamController<ConsultationEvent>.broadcast();
  final _connected = ValueNotifier<bool>(false);

  /// Whether the socket is currently connected. Screens use this to decide
  /// whether to fall back to polling.
  ValueListenable<bool> get connected => _connected;

  Stream<ConsultationEvent> eventsFor(String consultationId) =>
      _events.stream.where((e) => e.consultationId == consultationId);

  /// Connects with the signed-in user's token. Safe to call repeatedly.
  void connect() {
    if (!AuthSession.isLoggedIn) return;
    if (_socket != null && _tokenInUse != AuthSession.token) disconnect();
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }
    _tokenInUse = AuthSession.token;
    final socket = io.io(
      _url ?? AppConfig.apiHost,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': AuthSession.token})
          .enableReconnection()
          .build(),
    );
    socket
      ..onConnect((_) => _connected.value = true)
      ..onDisconnect((_) => _connected.value = false)
      ..onConnectError((e) => debugPrint('🔌 Realtime connect error: $e'))
      ..on(
        'consultation:message',
        (data) => handleEvent('consultation:message', data),
      )
      ..on(
        'consultation:updated',
        (data) => handleEvent('consultation:updated', data),
      );
    _socket = socket;
  }

  /// Drops the connection, e.g. on sign-out. The next [connect] uses the
  /// new token.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected.value = false;
  }

  @visibleForTesting
  void handleEvent(String event, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final id = map['consultationId'] as String? ?? '';
    if (id.isEmpty) return;

    final rawMessage = map['message'];
    _events.add(
      ConsultationEvent(
        consultationId: id,
        message: event == 'consultation:message' && rawMessage is Map
            ? ChatMessage.fromJson(Map<String, dynamic>.from(rawMessage))
            : null,
        status: map['status'] as String?,
      ),
    );
  }

  void dispose() {
    if (_events.isClosed) return;
    disconnect();
    _events.close();
    _connected.dispose();
  }
}

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient();
  ref.onDispose(client.dispose);
  return client;
});
