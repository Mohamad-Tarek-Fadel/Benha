import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'audio_player_widget.dart';
import 'loading_indicator.dart';

class ChatMessage extends StatelessWidget {
  final ChatMessage message;

  const ChatMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) 
            CircleAvatar(
              child: Icon(
                message.isError ? Icons.error_outline : Icons.android,
                color: message.isError ? Colors.white : null,
              ),
              backgroundColor: message.isError 
                  ? Colors.red 
                  : (message.language == 'ar' 
                      ? Colors.green 
                      : Colors.blue),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(message),
                borderRadius: BorderRadius.circular(12),
                border: message.isError 
                    ? Border.all(color: Colors.red, width: 1) 
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.language != null && !message.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.language == 'ar' ? 'العربية' : 'English',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  if (message.context != null && !message.isLoading)
                    _buildContextIndicator(context),
                  if (message.isLoading)
                    const LoadingIndicator(
                      message: 'Processing... / جاري المعالجة...',
                    )
                  else
                    Text(
                      message.text,
                      style: TextStyle(
                        fontFamily: message.language == 'ar' ? 'Arial' : null,
                        color: message.isError ? Colors.red : null,
                      ),
                    ),
                  if (message.audioUrl != null && !message.isLoading)
                    AudioPlayerWidget(
                      audioUrl: message.audioUrl!,
                      language: message.language,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser) const CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }

  Color _getBackgroundColor(ChatMessage message) {
    if (message.isError) return Colors.red[50]!;
    if (message.isLoading) return Colors.grey[100]!;
    return message.isUser 
        ? Colors.blue[100]! 
        : (message.language == 'ar' 
            ? Colors.green[50]! 
            : Colors.grey[200]!);
  }

  Widget _buildContextIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            _getContextIcon(message.context!.id),
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            message.context!.getDescription(
              Localizations.localeOf(context).languageCode,
            ),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContextIcon(String contextId) {
    switch (contextId) {
      case 'casual':
        return Icons.chat_bubble_outline;
      case 'business':
        return Icons.business_center;
      case 'travel':
        return Icons.flight_takeoff;
      case 'academic':
        return Icons.school;
      default:
        return Icons.chat_bubble_outline;
    }
  }
} 