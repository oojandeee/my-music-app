import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyMusicApp());
}

class MyMusicApp extends StatelessWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class OnlineSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String mediaUrl;

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.mediaUrl,
  });
}

class DirectSaavnService {
  // Uses JioSaavn song detail API endpoint to get resolved direct CDN stream links safely
  static Future<List<OnlineSong>> searchSongs(String query) async {
    final searchUrl = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=autocomplete.get&_format=json&_marker=0&cc=in&includeMetaTags=1&query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(searchUrl, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['songs']?['data'] ?? [];

        List<OnlineSong> songs = [];
        for (var item in songsJson) {
          String songId = item['id']?.toString() ?? '';
          if (songId.isNotEmpty) {
            String thumb = item['image'] ?? '';
            thumb = thumb.replaceAll('150x150', '500x500');

            songs.add(
              OnlineSong(
                id: songId,
                title: _cleanText(item['title'] ?? 'Unknown Track'),
                artist: _cleanText(item['more_info']?['singers'] ?? item['subtitle'] ?? 'Unknown Artist'),
                thumbnailUrl: thumb,
                mediaUrl: '', // Fetched directly on playback
              ),
            );
          }
        }
        return songs;
      }
    } catch (_) {}
    return [];
  }

  // Fetch resolved audio stream link for selected track ID
  static Future<String?> getStreamUrl(String songId) async {
    final detailsUrl = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=song.getDetails&cc=in&_marker=0%3F_marker%3D0&_format=json&pids=$songId',
    );

    try {
      final response = await http.get(detailsUrl, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data[songId] != null) {
          final songData = data[songId];
          String? mediaUrl = songData['media_preview_url']?.toString();

          if (mediaUrl != null && mediaUrl.isNotEmpty) {
            // Convert 96kbps preview URL to full 320kbps AAC/MP3 stream URL
            String cleanUrl = mediaUrl.replaceAll('_preview.mp4', '.mp4');
            cleanUrl = cleanUrl.replaceAll('http:', 'https:');
            cleanUrl = cleanUrl.replaceAll('_96.mp4', '_320.mp4');
            cleanUrl = cleanUrl.replaceAll('v0.cdn.jiosaavn.com', 'aac.saavncdn.com');
            return cleanUrl;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String _cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'");
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<OnlineSong> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults.clear();
    });

    final results = await DirectSaavnService.searchSongs(query);

    setState(() {
      _isLoading = false;
      if (results.isNotEmpty) {
        _searchResults = results;
      } else {
        _errorMessage = 'No tracks found. Check your internet connection.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search full songs...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _performSearch,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final song = _searchResults[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  song.thumbnailUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.music_note, color: Colors.purpleAccent),
                                ),
                              ),
                              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(song: song),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final OnlineSong song;

  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayer _audioPlayer;
  bool _isLoadingAudio = true;
  String _rawError = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final streamUrl = await DirectSaavnService.getStreamUrl(widget.song.id);

    if (streamUrl != null && streamUrl.isNotEmpty) {
      try {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(streamUrl)),
          preload: true,
        );
        _audioPlayer.play();

        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
            _rawError = 'Failed to load audio stream.';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _rawError = 'Stream URL unavailable.';
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.song.thumbnailUrl,
                height: 240,
                width: 240,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.music_note, size: 100),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.song.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.song.artist, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (_isLoadingAudio)
              const CircularProgressIndicator(color: Colors.purpleAccent)
            else if (_rawError.isNotEmpty)
              Text(_rawError, style: const TextStyle(color: Colors.redAccent))
            else
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data?.playing ?? false;
                  return IconButton(
                    iconSize: 64,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.purpleAccent,
                    ),
                    onPressed: () {
                      isPlaying ? _audioPlayer.pause() : _audioPlayer.play();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
