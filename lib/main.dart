import 'package:flutter/material.dart';
import 'chat_controller.dart';
import 'models.dart';
import 'protocol.dart';
import 'store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VanishApp());
}

// ---------- theme ----------

const _bg1 = Color(0xFF0E0B1F);
const _bg2 = Color(0xFF191033);
const _accent = Color(0xFFB388FF);

ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C4DFF),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _bg1,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class VanishApp extends StatefulWidget {
  const VanishApp({super.key});
  @override
  State<VanishApp> createState() => _VanishAppState();
}

class _VanishAppState extends State<VanishApp> {
  final ChatController c = ChatController(LocalStore());

  @override
  void initState() {
    super.initState();
    c.init();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanish',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          if (!c.ready) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return c.name.isEmpty ? JoinScreen(c: c) : ChatScreen(c: c);
        },
      ),
    );
  }
}

// ---------- join screen ----------

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, required this.c});
  final ChatController c;
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final name = TextEditingController();
  late final url = TextEditingController(text: widget.c.relayUrl);
  bool showRelay = false;

  @override
  void dispose() {
    name.dispose();
    url.dispose();
    super.dispose();
  }

  void _join() {
    if (name.text.trim().isEmpty) return;
    widget.c.join(name.text, url.text.isEmpty ? Protocol.defaultRelayUrl : url.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg1, _bg2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _GlowIcon(icon: Icons.timer_outlined)),
                    const SizedBox(height: 20),
                    const Text(
                      'Vanish',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Messages disappear 30 seconds after delivery',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 36),
                    TextField(
                      controller: name,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _join(),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        hintText: 'e.g. Ali',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => setState(() => showRelay = !showRelay),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              showRelay
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              size: 18,
                              color: _accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              showRelay
                                  ? 'Hide relay settings'
                                  : 'Advanced (relay address)',
                              style: const TextStyle(
                                  color: _accent, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showRelay) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: url,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Relay WebSocket URL',
                          hintText: 'ws://192.168.1.20:8080/ws',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Default is ${Protocol.defaultRelayUrl}. Change anytime from the chat screen too.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _join,
                      child: const Text('Enter Vanish'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Messages are relayed through your class server, then\n'
                          'deleted from your device 30 seconds after delivery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C6DFF), Color(0xFF673AB7)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C6DFF).withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 46, color: Colors.white),
    );
  }
}

// ---------- chat screen ----------

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.c});
  final ChatController c;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.c.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    widget.c.removeListener(_onChange);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    if (scroll.hasClients &&
        scroll.position.maxScrollExtent - scroll.position.pixels < 300) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd() {
    if (!scroll.hasClients) return;
    scroll.animateTo(
      scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final t = input.text;
    if (t.trim().isEmpty) return;
    widget.c.sendText(t);
    input.clear();
  }

  Future<void> _openSettings() async {
    final urlCtrl = TextEditingController(text: widget.c.relayUrl);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Relay settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The WebSocket relay the whole class talks through.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Relay URL',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current status: ${_statusLabel(widget.c.status)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(urlCtrl.text.trim()),
            child: const Text('Save & reconnect'),
          ),
        ],
      ),
    );
    if (newUrl != null && newUrl.isNotEmpty) {
      await widget.c.setRelay(newUrl);
    }
  }

  String _statusLabel(ConnStatus s) => switch (s) {
    ConnStatus.connected => 'online',
    ConnStatus.connecting => 'connecting…',
    ConnStatus.disconnected => 'offline',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg1,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const Text(
              'Vanish',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(width: 10),
            _StatusPill(status: widget.c.status),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Relay settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildList()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = [...widget.c.messages, ...widget.c.queue];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Say something — it will vanish in 30s.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      itemCount: items.length,
      itemBuilder: (_, i) => _MessageBubble(m: items[i], c: widget.c),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Message (vanishes in 30s)',
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9C6DFF), Color(0xFF673AB7)],
                ),
              ),
              child: IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ConnStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ConnStatus.connected => (const Color(0xFF00E676), 'online'),
      ConnStatus.connecting => (const Color(0xFFFFC400), 'connecting'),
      ConnStatus.disconnected => (const Color(0xFFFF5252), 'offline'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.m, required this.c});
  final ChatMessage m;
  final ChatController c;

  @override
  Widget build(BuildContext context) {
    final queued = m.expiresAt == null;
    final left = queued ? 0 : c.remainingMs(m).clamp(0, 1 << 30);
    final total = (m.expiresAt != null && m.sentAt != null)
        ? (m.expiresAt! - m.sentAt!).clamp(1, 1 << 30)
        : Protocol.lifetimeMs;
    final progress = queued ? 0.0 : (left / total).clamp(0.0, 1.0);

    final mine = m.mine;
    final bubbleColor = mine
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF232038), Color(0xFF1B1A2C)],
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  m.sender,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            Text(m.text, style: const TextStyle(fontSize: 15, height: 1.35)),
            const SizedBox(height: 8),
            if (queued)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'waiting to send…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(left / 1000).ceil()}s',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}