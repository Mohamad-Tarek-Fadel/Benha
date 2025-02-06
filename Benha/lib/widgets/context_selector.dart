class ContextSelector extends StatelessWidget {
  const ContextSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return DropdownButton<ConversationContext>(
          value: chatProvider.currentContext,
          items: chatProvider.contexts.map((context) {
            return DropdownMenuItem(
              value: context,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getContextIcon(context.id),
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.getDescription(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newContext) {
            if (newContext != null) {
              chatProvider.setContext(newContext);
            }
          },
        );
      },
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