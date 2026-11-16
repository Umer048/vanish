import 'dart:convert';
import 'models.dart';

class Protocol {
  // YAHAN CHANGE KIYA HAI (ws:// ki jagah wss:// aur naya address)
  static const defaultRelayUrl = 'wss://vanish-relay-sawaira.bonto.page/ws';
  static const lifetimeMs = 30000;
  static const relayEchoesToSender = true;

  static String join(String name, String deviceId) =>
      jsonEncode({'type': 'join', 'name': name, 'device_id': deviceId});

  static String outgoing(ChatMessage m) =>
      jsonEncode({'type': 'message', 'id': m.id, 'sender': m.sender, 'text': m.text});

  static String delivered(String id) =>
      jsonEncode({'type': 'delivered', 'id': id});

  static Incoming? parse(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      final type = j['type'];
      if (type == 'expired' && j['id'] is String) {
        return IncomingExpired(j['id'] as String);
      }
      if ((type == 'message' || type == null) &&
          j['id'] is String &&
          j['text'] is String) {
        return IncomingMessage(ChatMessage(
          id: j['id'] as String,
          sender: (j['sender'] ?? 'unknown').toString(),
          text: j['text'] as String,
          sentAt: _ms(j['sent_at']),
          expiresAt: _ms(j['expires_at']),
        ));
      }
    } catch (_) {}
    return null;
  }

  static int? _ms(dynamic v) {
    if (v == null) return null;
    if (v is num) return v < 100000000000 ? (v * 1000).round() : v.round();
    if (v is String) {
      final n = num.tryParse(v);
      if (n != null) return _ms(n);
      return DateTime.tryParse(v)?.millisecondsSinceEpoch;
    }
    return null;
  }
}

sealed class Incoming {}
class IncomingMessage extends Incoming {
  IncomingMessage(this.message);
  final ChatMessage message;
}
class IncomingExpired extends Incoming {
  IncomingExpired(this.id);
  final String id;
}