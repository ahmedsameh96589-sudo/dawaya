class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.text,
    required this.attachmentUrl,
    required this.createdAt,
  });

  final String id;
  final String senderType;
  final String text;
  final String attachmentUrl;
  final DateTime createdAt;

  bool get hasImage => attachmentUrl.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] as String? ?? '',
      senderType: json['senderType'] as String? ?? 'user',
      text: json['text'] as String? ?? '',
      attachmentUrl: json['attachment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
