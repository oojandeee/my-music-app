import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Stream Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121218),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E2A),
        ),
      ),
      home: const YouTubePlayerScreen(),
    );
  }
}

class YouTubeStreamService {
  static final List<String> _instances = [
    'https://inv.tux.pizza',
    'https://invidious.nerdvpn.de',
    'https://invidious.drgns.space',
  ];

  static Future<Map<String, String>> getStreamDetails(String input) async {
    final videoId = _extractVideoId(input);
    if (videoId == null) {
      throw Exception('Invalid YouTube URL or Video ID');
    }

    for (final instance in _instances) {
      try {
        final response = await http
            .get(Uri.parse('$instance/api/v1/videos/$videoId'))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final formatStreams = data['formatStreams'] as List<dynamic>?;
          final title = data['title'] as String? ?? 'YouTube Stream';

          if (formatStreams != null && formatStreams.isNotEmpty) {
            final stream = formatStreams.firstWhere(
              (item) => item['container'] == 'mp4',
              orElse: () => formatStreams.first,
            );

            final streamUrl = stream['url'] as String?;
            if (streamUrl != null && streamUrl.isNotEmpty) {
              return {
                'url': streamUrl,
                'title': title,
              };
            }
          }
        }
      } catch (e) {
        continue;
      }
    }
    throw Exception('Failed to extract stream from API servers.');
  }

  static String? _extractVideoId(String input) {
    final cleanInput = input.trim();
    if (cleanInput.length == 11 && !cleanInput.contains('/')) {
      return cleanInput;
    }
    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(cleanInput);
    return match?.group(1);
  }
}

class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({super.key});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  final TextEditingController _urlController = TextEditingController();
  VideoPlayerController? _videoController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _videoTitle;

  Future<void> _processAndPlay() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoTitle = null;
    });

    await _videoController?.dispose();
    _videoController = null;

    try {
      final streamData = await YouTubeStreamService.getStreamDetails(input);
      final streamUrl = streamData['url']!;
      final title = streamData['title']!;

      final controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await controller.initialize();

      setState(() {
        _videoController = controller;
        _videoTitle = title;
      });

      controller.play();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Stream Player'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPlayerArea(),
              ),
            ),
            const SizedBox(height: 24),

            if (_videoTitle != null) ...[
              Text(
                _videoTitle!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'YouTube Video ID or URL',
                hintText: 'e.g., Q83WcxiX_lc or youtube.com/watch?v=...',
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E1E2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.link, color: Colors.deepPurpleAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white50),
                  onPressed: () => _urlController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Text(
                'Playback Error: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _processAndPlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.play_arrow, color: Colors.white),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Play Stream',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurpleAccent),
            SizedBox(height: 12),
            Text('Extracting stream...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_videoController!),
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.deepPurpleAccent,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.black26,
              ),
            ),
            Center(
              child: IconButton(
                iconSize: 50,
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white.withOpacity(0.8),
                ),
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 64, color: Colors.white24),
          SizedBox(height: 8),
          Text('Enter URL or Video ID to start', style: TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }
}
