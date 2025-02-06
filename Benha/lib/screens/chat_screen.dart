import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_message.dart';
import '../widgets/record_button.dart';
import '../widgets/context_selector.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Practice'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Context: '),
                const ContextSelector(),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use'),
                  content: const Text(
                    'Tap and hold the microphone button to record your voice.\n\n'
                    'Release to send your message.\n\n'
                    'The AI will respond with text and voice.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return ListView.builder(
                  reverse: true,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ChatMessage(message: message);
                  },
                );
              },
            ),
          ),
          const RecordButton(),
        ],
      ),
    );
  }
} 