import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'dart:io';
import '../providers/chat_provider.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({super.key});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> with SingleTickerProviderStateMixin {
  final _audioRecorder = Record();
  bool _isRecording = false;
  String? _recordingPath;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingPath = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (_recordingPath != null) {
        await Provider.of<ChatProvider>(context, listen: false)
            .sendAudioMessage(File(_recordingPath!));
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((ChatProvider p) => p.isLoading);
    
    return GestureDetector(
      onLongPressStart: isLoading ? null : (_) => _startRecording(),
      onLongPressEnd: isLoading ? null : (_) => _stopRecording(),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording 
                  ? 1.0 + (_pulseController.value * 0.2) 
                  : 1.0,
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 32,
                color: isLoading 
                    ? Colors.grey 
                    : (_isRecording ? Colors.red : Colors.blue),
              ),
            );
          },
        ),
      ),
    );
  }
} 