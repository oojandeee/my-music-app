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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF121212),
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.grey,
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
  final String? directStreamUrl; // Pre-fetched JioSaavn direct CDN link if available
  final bool isYoutube;

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.directStreamUrl,
    this.isYoutube = false,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _recentSearches = [];
  List<OnlineSong> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Multi-source primary and secondary fallback mirrors
  final List<String> _saavnApis = [
    'https://saavn.dev/api',
    'https://saavn.me',
  ];

  final List<String> _pipedApis = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.private.coffee',
    'https://pipedapi.ducks.party',
  ];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults.clear();
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      _searchController.text = query;
    });

    List<OnlineSong> fetchedSongs = [];

    // STEP 1: Try JioSaavn APIs first (Provides direct MP3 streams instantly)
    for (String baseUrl in _saavnApis) {
      try {
        final url = Uri.parse('$baseUrl/search/songs?query=${Uri.encodeComponent(query)}&limit=30');
        final response = await http.get(url).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          List items = [];

          if (data['data'] != null && data['data']['results'] != null) {
            items = data['data']['results'];
          } else if (data['results'] != null) {
            items = data['results'];
          }

          for (var item in items) {
            String? streamUrl;
            if (item['downloadUrl'] != null && (item['downloadUrl'] as List).isNotEmpty) {
              List downloads = item['downloadUrl'];
              // Select highest available quality MP3 stream URL
              streamUrl = downloads.last['link'] ?? downloads.last['url'];
            }

            fetchedSongs.add(
              OnlineSong(
                id: item['id']?.toString() ?? UniqueKey().toString(),
                title: item['name'] ?? item['title'] ?? 'Unknown Track',
                artist: item['primaryArtists'] ?? item['artist'] ?? 'Unknown Artist',
                thumbnailUrl: (item['image'] != null && (item['image'] as List).isNotEmpty)
                    ? item['image'].last['link'] ?? item['image'].last['url'] ?? ''
                    : '',
                directStreamUrl: streamUrl,
                isYoutube: false,
              ),
            );
          }

          if (fetchedSongs.isNotEmpty) break;
        }
      } catch (_) {
        continue;
      }
    }

    // STEP 2: Fallback to Piped YouTube if JioSaavn returned zero results
    if (fetchedSongs.isEmpty) {
      for (String baseUrl in _pipedApis) {
        try {
          final url = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}&filter=music_songs');
          final response = await http.get(url).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List items = data['items'] ?? [];

            for (var item in items) {
              if (item['url'] != null) {
                String vId = item['url'].toString().replaceAll('/watch?v=', '');
                fetchedSongs.add(
                  OnlineSong(
                    id: vId,
                    title: item['title'] ?? 'Unknown Track',
                    artist: item['uploaderName'] ?? 'Unknown Artist',
                    thumbnailUrl: item['thumbnail'] ?? '',
                    isYoutube: true,
                  ),
                );
              }
            }

            if (fetchedSongs.isNotEmpty) break;
          }
        } catch (_) {
          continue;
        }
      }
    }

    setState(() {
      _isLoading = false;
      if (fetchedSongs.isNotEmpty) {
        _searchResults = fetchedSongs;
      } else {
        _errorMessage = 'No audio stream available right now. Please check your network connection.';
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  hintText: 'Search songs...',
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
                              leading: Image.network(
                                song.thumbnailUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.music_note, color: Colors.purpleAccent),
                              ),
                              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      song: song,
                                      pipedApis: _pipedApis,
                                    ),
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
  final List<String> pipedApis;

  const PlayerScreen({
    super.key,
    required this.song,
    required this.pipedApis,
  });

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
    _startInstantPlayback();
  }

  Future<void> _startInstantPlayback() async {
    String? finalStreamUrl = widget.song.directStreamUrl;

    // If stream URL is not present (Piped track), fetch the stream link dynamically
    if (finalStreamUrl == null || finalStreamUrl.isEmpty) {
      for (String baseUrl in widget.pipedApis) {
        try {
          final res = await http
              .get(Uri.parse('$baseUrl/streams/${widget.song.id}'))
              .timeout(const Duration(seconds: 3));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final List streams = data['audioStreams'] ?? [];
            if (streams.isNotEmpty) {
              finalStreamUrl = streams.last['url'];
              break;
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    if (finalStreamUrl != null && finalStreamUrl.isNotEmpty) {
      try {
        // Stream directly from remote URL chunk-by-chunk without full download
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(finalStreamUrl)),
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
            _rawError = 'Failed to start playback stream: $e';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
          _rawError = 'Stream link could not be fetched. Check connection.';
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
            Image.network(
              widget.song.thumbnailUrl,
              height: 200,
              width: 200,
              errorBuilder: (c, e, s) => const Icon(Icons.music_note, size: 100),
            ),
            const SizedBox(height: 20),
            Text(widget.song.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.song.artist, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
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
                    icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.purpleAccent),
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
