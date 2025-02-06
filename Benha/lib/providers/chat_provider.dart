import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_message.dart';
import '../models/conversation_context.dart';
import 'package:path_provider/path_provider.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  List<ConversationContext> _contexts = [];
  List<ConversationContext> get contexts => List.unmodifiable(_contexts);
  
  ConversationContext? _currentContext;
  ConversationContext? get currentContext => _currentContext;
  
  final String _baseUrl = 'http://localhost:5000';
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Cache for audio files
  final Map<String, File> _audioCache = {};
  
  // Initialize contexts when app starts
  ChatProvider() {
    loadContexts();
  }

  Future<void> loadContexts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_contexts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _contexts = (data['contexts'] as List)
            .map((c) => ConversationContext.fromJson(c))
            .toList();
        _currentContext = _contexts.first;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading contexts: $e');
    }
  }

  void setContext(ConversationContext context) {
    _currentContext = context;
    notifyListeners();
  }

  Future<void> sendAudioMessage(File audioFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userMessage = ChatMessage(
        isUser: true,
        text: 'Processing... / جاري المعالجة...',
        timestamp: DateTime.now(),
        context: _currentContext,
        isLoading: true,
      );
      _messages.insert(0, userMessage);
      notifyListeners();

      // Create multipart request with context
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/process_audio'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );
      
      request.fields['context'] = _currentContext?.id ?? 'casual';

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode != 200) {
        throw Exception(jsonData['error']);
      }

      // Update user message
      userMessage
        ..text = jsonData['user_text']
        ..isLoading = false;
      
      // Add AI response
      final audioUrl = '$_baseUrl${jsonData['audio_url']}';
      
      // Pre-fetch and cache audio file
      if (!_audioCache.containsKey(audioUrl)) {
        final audioResponse = await http.get(Uri.parse(audioUrl));
        if (audioResponse.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
          await tempFile.writeAsBytes(audioResponse.bodyBytes);
          _audioCache[audioUrl] = tempFile;
        }
      }

      _messages.insert(0, ChatMessage(
        isUser: false,
        text: jsonData['ai_response'],
        audioUrl: audioUrl,
        language: jsonData['language'],
        context: _currentContext,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      _messages.insert(0, ChatMessage(
        isUser: false,
        text: 'Error: $e\nPlease try again. / حدث خطأ. يرجى المحاولة مرة أخرى.',
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clean up cached audio files
  void clearAudioCache() {
    for (final file in _audioCache.values) {
      file.delete().catchError((e) => print('Error deleting cache file: $e'));
    }
    _audioCache.clear();
  }

  @override
  void dispose() {
    clearAudioCache();
    super.dispose();
  }
} 