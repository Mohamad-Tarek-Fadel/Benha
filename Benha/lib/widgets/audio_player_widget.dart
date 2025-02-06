import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setUrl(widget.audioUrl);
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: () {
        if (_isPlaying) {
          _audioPlayer.pause();
        } else {
          _audioPlayer.play();
        }
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
} 