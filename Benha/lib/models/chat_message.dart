class ChatMessage {
  final bool isUser;
  String text;
  final DateTime timestamp;
  final String? audioUrl;
  final String? language;
  final ConversationContext? context;
  bool isLoading;
  final bool isError;

  ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.audioUrl,
    this.language,
    this.context,
    this.isLoading = false,
    this.isError = false,
  });
} 