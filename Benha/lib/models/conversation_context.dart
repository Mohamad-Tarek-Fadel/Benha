class ConversationContext {
  final String id;
  final Map<String, String> descriptions;

  ConversationContext({
    required this.id,
    required this.descriptions,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      id: json['id'],
      descriptions: Map<String, String>.from(json['descriptions']),
    );
  }

  String getDescription(String language) {
    return descriptions[language] ?? descriptions['en'] ?? id;
  }
} 