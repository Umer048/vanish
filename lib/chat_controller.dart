import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'models.dart';
import 'protocol.dart';
import 'relay_client.dart';
import 'store.dart';

class ChatController extends ChangeNotifier with WidgetsBindingObserver {
  ChatController(this._store);

  final LocalStore _store;
  final Random _rng = Random.secure();

  bool ready = false;
  String name = '';
  String deviceId = '';
  String relayUrl = Protocol.defaultRelayUrl;
  ConnStatus status = ConnStatus.disconnected;

  final List<ChatMessage> messages = [];
  final List<ChatMessage> queue = [];
  final Map<String, int> _seen = {};

  int offsetMs = 0;
  final List<int> _samples = [];

  RelayClient? _client;
  Timer? _ticker;
  Timer? _pingTimer; // Naya: Heartbeat ke liye
  bool _started = false;
  final Set<String> _sentThisConn = {};

  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + offsetMs;
  int remainingMs(ChatMessage m) => (m.expiresAt ?? 0) - serverNowMs;

  Future<void> init() async {
    await _store.init();
    final s = await _store.load();
    name = s['name'] as String? ?? '';
    deviceId = s['deviceId'] as String? ?? _randomId();
    relayUrl = s['relayUrl'] as String? ?? Protocol.defaultRelayUrl;
    offsetMs = (s['offsetMs'] as num?)?.toInt() ?? 0;
    for (final j in (s['messages'] as List? ?? const [])) {
      messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(j as Map)));
    }
    for (final j in (s['queue'] as List? ?? const [])) {
      queue.add(ChatMessage.fromJson(Map<String, dynamic>.from(j as Map)));
    }
    ((s['seen'] as Map?) ?? const {})
        .forEach((k, v) => _seen[k as String] = (v as num).toInt());

    _purge();
    await _persist();
    ready = true;
    notifyListeners();
    if (name.isNotEmpty) _start();
  }

  Future<void> join(String displayName, String url) async {
    name = displayName.trim();
    relayUrl = url.trim();
    await _persist();
    notifyListeners();
    _start();
  }

  Future<void> setRelay(String url) async {
    final u = url.trim();
    if (u.isEmpty || u == relayUrl) return;
    relayUrl = u;
    await _persist();
    _stop();
    _start();
    notifyListeners();
  }

  void _start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());

    // Naya: Har 15 second baad ping bhejna
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _client?.send(Protocol.ping());
    });

    _client = RelayClient(
      url: relayUrl,
      onStatus: (s) {
        status = s;
        notifyListeners();
      },
      onOpen: _onOpen,
      onData: _onData,
    );
    unawaited(_client!.run());
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _client?.close();
    _client = null;
    _started = false;
    status = ConnStatus.disconnected;
  }

  void sendText(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final m = ChatMessage(
      id: '$deviceId-${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(1 << 20)}',
      sender: name,
      text: t,
      mine: true,
    );
    queue.add(m);
    _persist();
    notifyListeners();
    _flush();
  }

  void _flush() {
    if (status != ConnStatus.connected) return;
    for (final m in List<ChatMessage>.from(queue)) {
      if (_sentThisConn.contains(m.id)) continue;
      if (!(_client?.send(Protocol.outgoing(m)) ?? false)) break;
      _sentThisConn.add(m.id);
    }
  }

  void _onOpen() {
    _sentThisConn.clear();
    _client?.send(Protocol.join(name, deviceId));
    _flush();
  }

  void _onData(String raw) {
    final ev = Protocol.parse(raw);

    if (ev is IncomingWelcome) {
      // Protocol ke mutabiq: offset = server_time - phone_time
      offsetMs = ev.serverTime - DateTime.now().millisecondsSinceEpoch;
      _persist();
      notifyListeners();
    } else if (ev is IncomingPong) {
      // Ping ka jawab mil gaya, kuch karne ki zaroorat nahi
    } else if (ev is IncomingDelivered) {
      // Message deliver ho gaya (is par tick lagana ho toh laga sakte hain)
    } else if (ev is IncomingExpired) {
      messages.removeWhere((m) => m.id == ev.id);
      _seen[ev.id] = serverNowMs;
      _persist();
      notifyListeners();
    } else if (ev is IncomingMessage) {
      final m = ev.message;
      if (m.expiresAt == null || m.sentAt == null) return;
      if (_seen.containsKey(m.id)) return; // Duplicate ignore

      // Ab offset Welcome message se set ho raha hai

      final qi = queue.indexWhere((q) => q.id == m.id);
      final isMine = qi >= 0 || m.sender == name;
      if (qi >= 0) queue.removeAt(qi);

      if (m.expiresAt! <= serverNowMs) {
        _seen[m.id] = m.expiresAt!;
        _persist();
        notifyListeners();
        return;
      }
      _accept(m.copyWith(mine: isMine));
      // Protocol ke mutabiq app "delivered" nahi bhejti, relay bhejta hai.
    }
  }

  void _accept(ChatMessage m) {
    _seen[m.id] = m.expiresAt!;
    messages.add(m);
    messages.sort((a, b) => (a.sentAt ?? 0).compareTo(b.sentAt ?? 0));
    _persist();
    notifyListeners();
  }

  void _tick() {
    if (_purge()) _persist();
    notifyListeners();
  }

  bool _purge() {
    final now = serverNowMs;
    final before = messages.length;
    messages.removeWhere((m) => (m.expiresAt ?? 0) <= now);
    _seen.removeWhere((_, exp) => exp + 120000 < now);
    return messages.length != before;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_purge()) _persist();
      _client?.reconnectNow();
      notifyListeners();
    }
  }

  String _randomId() =>
      List.generate(16, (_) => _rng.nextInt(16).toRadixString(16)).join();

  Future<void> _persist() => _store.save({
    'name': name,
    'deviceId': deviceId,
    'relayUrl': relayUrl,
    'offsetMs': offsetMs,
    'messages': messages.map((m) => m.toJson()).toList(),
    'queue': queue.map((m) => m.toJson()).toList(),
    'seen': _seen,
  });

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}