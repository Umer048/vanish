import 'dart:convert';
import 'models.dart';

class Protocol {
  static const defaultRelayUrl = 'wss://vanish-relay-sawaira.bonto.page/ws';
  static const lifetimeMs = 30000;

  // Protocol ke mutabiq server sender ko bhi message wapas bhejta hai
  static const relayEchoesToSender = true;

  static String join(String name, String deviceId) =>
      jsonEncode({'type': 'join', 'protocol': 1, 'device_id': deviceId, 'name': name});

  static String outgoing(ChatMessage m) =>
      jsonEncode({'type': 'message', 'id': m.id, 'sender': m.sender, 'text': m.text});

  static String ping() => jsonEncode({'type': 'ping'});

  static Incoming? parse(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      final type = j['type'];

      // Welcome message (Clock set karne ke liye)
      if (type == 'welcome' && j['server_time'] is num) {
        return IncomingWelcome((j['server_time'] as num).toInt());
      }

      // Presence (Online users ka count)
      if (type == 'presence' && j['count'] is num) {
        return IncomingPresence(
          (j['count'] as num).toInt(),
          (j['members'] as List? ?? const []).map((e) => e.toString()).toList(),
        );
      }

      // Pong response
      if (type == 'pong') return IncomingPong();

      // Delivered response
      if (type == 'delivered' && j['id'] is String) {
        return IncomingDelivered(j['id'] as String);
      }

      // Expired message
      if (type == 'expired' && j['id'] is String) {
        return IncomingExpired(j['id'] as String);
      }

      // Naya Chat Message
      if (type == 'message' && j['id'] is String && j['text'] is String) {
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
class IncomingWelcome extends Incoming {
  IncomingWelcome(this.serverTime);
  final int serverTime;
}
class IncomingPong extends Incoming {}
class IncomingDelivered extends Incoming {
  IncomingDelivered(this.id);
  final String id;
}
class IncomingPresence extends Incoming {
  IncomingPresence(this.count, this.members);
  final int count;
  final List<String> members;
}