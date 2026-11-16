class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.sentAt,
    this.expiresAt,
    this.mine = false,
  });

  final String id;
  final String sender;
  final String text;
  final int? sentAt;
  final int? expiresAt;
  final bool mine;

  ChatMessage copyWith({int? sentAt, int? expiresAt, bool? mine}) => ChatMessage(
    id: id,
    sender: sender,
    text: text,
    sentAt: sentAt ?? this.sentAt,
    expiresAt: expiresAt ?? this.expiresAt,
    mine: mine ?? this.mine,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'text': text,
    'sentAt': sentAt,
    'expiresAt': expiresAt,
    'mine': mine,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    sender: j['sender'] as String,
    text: j['text'] as String,
    sentAt: (j['sentAt'] as num?)?.toInt(),
    expiresAt: (j['expiresAt'] as num?)?.toInt(),
    mine: j['mine'] as bool? ?? false,
  );
}

enum ConnStatus { connecting, connected, disconnected }