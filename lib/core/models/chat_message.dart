class Citation {
  const Citation({
    required this.reference,
    required this.originalText,
    required this.translation,
    this.isRtl = false,
  });

  final String reference;
  final String originalText;
  final String translation;
  final bool isRtl;

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'originalText': originalText,
    'translation': translation,
    'isRtl': isRtl,
  };

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
    reference: json['reference'] as String,
    originalText: (json['originalText'] as String?) ?? '',
    translation: (json['translation'] as String?) ?? '',
    isRtl: (json['isRtl'] as bool?) ?? false,
  );

  factory Citation.referenceOnly(String reference) =>
      Citation(reference: reference, originalText: '', translation: reference);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Citation> citations;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'citations': citations.map((c) => c.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    citations: (json['citations'] as List)
        .map((c) => c is String
            ? Citation.referenceOnly(c)
            : Citation.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.religionId,
    required this.textId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String religionId;
  final String textId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession copyWith({
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) => ChatSession(
    id: id,
    title: title ?? this.title,
    religionId: religionId,
    textId: textId,
    messages: messages ?? this.messages,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'religionId': religionId,
    'textId': textId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    title: json['title'] as String,
    religionId: json['religionId'] as String,
    textId: json['textId'] as String,
    messages: (json['messages'] as List)
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );

  static DateTime _parseDate(dynamic v) {
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }
}
