import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const YouTubeMusicPlayerScreen(),
    );
  }
}

class YouTubeMusicPlayerScreen extends StatefulWidget {
  const YouTubeMusicPlayerScreen({super.key});

  @override
  State<YouTubeMusicPlayerScreen> createState() => _YouTubeMusicPlayerScreenState();
}

class _YouTubeMusicPlayerScreenState extends State<YouTubeMusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController(text: '2TSvac5aER4'); // Default YT Video ID (Prem Dhillon - Get At Me)

  bool _isLoading = false;
  bool _isPlaying = false;
  String _statusMessage = 'Ready to play';

  // Base URL for your deployed Render backend
  final String _renderBackendUrl = 'https://music-backend-c3o4.onrender.com';

  @override
  void initState() {
    super.initState();

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<void> _playYouTubeAudio(String videoId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching stream from Render server...';
    });

    try {
      // Connect directly to Render proxy pipe stream endpoint
      final String proxiedStreamUrl = 
          '$_renderBackendUrl/api/youtube/stream?id=$videoId';

      await _audioPlayer.setUrl(proxiedStreamUrl);
      await _audioPlayer.play();

      setState(() {
        _isLoading = false;
        _statusMessage = 'Playing track';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Playback Error: $e';
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.duration == null) {
        await _playYouTubeAudio(_searchController.text.trim());
      } else {
        await _audioPlayer.play();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Stream Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'YouTube Video ID or URL',
                border: OutlineInputBorder(),
                hintText: 'e.g. 2TSvac5aER4',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              IconButton(
                iconSize: 64,
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                onPressed: _togglePlayPause,
              ),
          ],
        ),
      ),
    );
  }
}
