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
      home: const MusicHomeScreen(),
    );
  }
}

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Track',
      artist: json['artist'] ?? 'Unknown Artist',
      thumbnailUrl: json['imageUrl'] ?? '',
    );
  }
}

class BackendMusicService {
  // Your Live Render Proxy URL
  static const String baseUrl = 'https://music-backend-c3o4.onrender.com';

  // Search songs via Proxy
  static Future<List<SongModel>> searchSongs(String query) async {
    final searchUrl = Uri.parse('$baseUrl/api/search?q=${Uri.encodeComponent(query)}');

    try {
      final response = await http.get(searchUrl).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        return results.map((item) => SongModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Fetch stream link via Proxy
  static Future<String?> fetchStreamUrl(String songId) async {
    final url = Uri.parse('$baseUrl/api/stream?id=$songId');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['streamUrl'];
      }
    } catch (_) {}
    return null;
  }
}

class MusicHomeScreen extends StatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> _searchResults = [];
  bool _isLoading = false;
  SongModel? _currentPlayingSong;
  bool _isPlaying = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayerListeners();
  }

  void _initAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isBuffering = state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    final results = await BackendMusicService.searchSongs(query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _searchResults = results;
      });
    }
  }

  Future<void> _playSong(SongModel song) async {
    setState(() {
      _currentPlayingSong = song;
      _isBuffering = true;
    });

    String? streamUrl = await BackendMusicService.fetchStreamUrl(song.id);

    if (streamUrl != null && streamUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(streamUrl);
        await _audioPlayer.play();
      } catch (e) {
        _showToast("Playback failed for this track.");
      }
    } else {
      _showToast("Unable to resolve stream from proxy server.");
    }

    if (mounted) {
      setState(() {
        _isBuffering = false;
      });
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search song or artist...',
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.purpleAccent),
                    )
                  : _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'No results found. Type a query and tap search.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final song = _searchResults[index];
                            final bool isSelected =
                                _currentPlayingSong?.id == song.id;

                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  song.thumbnailUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.music_note, size: 30),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.purpleAccent : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: isSelected && _isBuffering
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.purpleAccent,
                                      ),
                                    )
                                  : Icon(
                                      isSelected && _isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: Colors.purpleAccent,
                                      size: 32,
                                    ),
                              onTap: () => _playSong(song),
                            );
                          },
                        ),
            ),
            if (_currentPlayingSong != null) _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      color: const Color(0xFF212121),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              _currentPlayingSong!.thumbnailUrl,
              width: 45,
              height: 45,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.music_note),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentPlayingSong!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _currentPlayingSong!.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isBuffering)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                if (_isPlaying) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play();
                }
              },
            ),
        ],
      ),
    );
  }
}
