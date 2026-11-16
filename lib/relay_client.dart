import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'models.dart';

class RelayClient {
  RelayClient({
    required this.url,
    required this.onStatus,
    required this.onOpen,
    required this.onData,
  });

  final String url;
  final void Function(ConnStatus) onStatus;
  final void Function() onOpen;
  final void Function(String) onData;

  WebSocket? _ws;
  bool _closed = false;
  int _attempt = 0;
  Completer<void>? _wake;

  Future<void> run() async {
    while (!_closed) {
      try {
        onStatus(ConnStatus.connecting);
        final ws = await WebSocket.connect(url).timeout(const Duration(seconds: 8));
        ws.pingInterval = const Duration(seconds: 15);
        _ws = ws;
        _attempt = 0;
        onStatus(ConnStatus.connected);
        onOpen();
        await for (final d in ws) {
          if (d is String) onData(d);
        }
      } catch (_) {}
      _ws = null;
      if (_closed) break;
      onStatus(ConnStatus.disconnected);
      final secs = min(30, 1 << min(_attempt, 5));
      _attempt++;
      _wake = Completer<void>();
      await Future.any([Future.delayed(Duration(seconds: secs)), _wake!.future]);
    }
  }

  bool send(String frame) {
    final ws = _ws;
    if (ws == null) return false;
    try {
      ws.add(frame);
      return true;
    } catch (_) {
      return false;
    }
  }

  void reconnectNow() {
    if (_ws != null) {
      _ws!.close();
    } else if (_wake != null && !_wake!.isCompleted) {
      _wake!.complete();
    }
  }

  void close() {
    _closed = true;
    _ws?.close();
    if (_wake != null && !_wake!.isCompleted) _wake!.complete();
  }
}