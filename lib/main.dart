import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MusicPlayerScreen(),
  ));
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = false;
  String? _statusMessage;
  String? _songTitle;

  // List of public Piped API instances for fallback redundancy
  final List<String> _pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.privacydev.net',
    'https://pipedapi.mha.fi',
  ];

  /// Extract video ID from full YouTube link or raw ID
  String? _parseVideoId(String input) {
    final text = input.trim();
    if (text.length == 11 && !text.contains('/')) return text;
    
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(text);
    return match?.group(1);
  }

  /// Fetches audio stream from Piped API instances
  Future<void> _playSong() async {
    final videoId = _parseVideoId(_controller.text);
    if (videoId == null) {
      setState(() => _statusMessage = "Error: Invalid YouTube link or ID");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _statusMessage = "Extracting full audio stream...";
      _songTitle = null;
    });

    bool success = false;

    for (final instance in _pipedInstances) {
      try {
        final response = await http
            .get(Uri.parse('$instance/streams/$videoId'))
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final audioStreams = data['audioStreams'] as List<dynamic>?;
          final title = data['title'] as String? ?? 'Audio Track';

          if (audioStreams != null && audioStreams.isNotEmpty) {
            // Select high quality M4A/AAC stream for reliable audio playback
            final audioTrack = audioStreams.firstWhere(
              (s) => s['mimeType']?.toString().contains('audio/mp4') ?? false,
              orElse: () => audioStreams.first,
            );

            final streamUrl = audioTrack['url'] as String;

            // Load and play full song
            await _audioPlayer.setUrl(streamUrl);
            _audioPlayer.play();

            setState(() {
              _songTitle = title;
              _statusMessage = null;
            });

            success = true;
            break;
          }
        }
      } catch (e) {
        // Fallback to next instance on failure
        continue;
      }
    }

    if (!success) {
      setState(() {
        _statusMessage = "Playback Error: Could not fetch stream from servers.";
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text('YouTube Music Player'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_songTitle != null) ...[
              const Icon(Icons.music_note, size: 64, color: Colors.deepPurpleAccent),
              const SizedBox(height: 12),
              Text(
                _songTitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
            ],

            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL or ID',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E1E2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.link, color: Colors.deepPurpleAccent),
              ),
            ),
            const SizedBox(height: 16),

            if (_statusMessage != null) ...[
              Text(_statusMessage!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _playSong,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Play Full Song', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
