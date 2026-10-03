import 'dart0:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
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
  final String streamUrl;

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.streamUrl,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreenThe reason your app shows an empty screen immediately after searching is due to two critical issues in the code:

1. **Missing Exception & Status Check Handlers:** When the API fails or returns unexpected JSON keys, the `catch` block executes and immediately sets `_isLoading = false` without populating `_searchResults`. Because `_searchResults` stays empty, Flutter falls back to showing the "Browse Categories" screen instead of showing the error message or song list.
2. **API Endpoint JSON Structure Mismatch:** The endpoint (`saavn.dev`) returns nested structures (`data['results']` or `data['data']['results']`) depending on server routing. If key extraction fails, `loadedSongs` remains empty.

The updated `lib/main.dart` implementation below fixes both issues:
* **Multi-endpoint Fallback System:** Tries `saavn.dev` first; if it returns no results, it automatically queries a backup API (`saavn.me`).
* **Visual Error Banner & Debugging Output:** If an API fails or no songs are found, it displays a red warning banner explaining what happened rather than reverting to an empty screen.
* **Flexible JSON Parsing:** Handles string/list variations for song titles, images, and audio URLs.

Replace the contents of your `lib/main.dart` file on GitHub with this code:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
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
  final String streamUrl;

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.streamUrl,
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

    List<OnlineSong> loadedSongs = [];

    // Try Primary API
    try {
      final primaryUrl = Uri.parse('[https://saavn.dev/api/search/songs?query=$](https://saavn.dev/api/search/songs?query=$){Uri.encodeComponent(query)}&limit=20');
      final response = await http.get(primaryUrl).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['data'] != null && data['data']['results'] != null)
            ? data['data']['results']
            : (data['results'] ?? data['data']);

        if (results is List) {
          loadedSongs = _parseResults(results);
        }
      }
    } catch (e) {
      debugPrint('Primary API Error: $e');
    }

    // Try Secondary API if primary produced no results
    if (loadedSongs.isEmpty) {
      try {
        final backupUrl = Uri.parse('[https://saavn.me/search/songs?query=$](https://saavn.me/search/songs?query=$){Uri.encodeComponent(query)}&limit=20');
        final response = await http.get(backupUrl).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = (data['data'] != null && data['data']['results'] != null)
              ? data['data']['results']
              : (data['results'] ?? data['data']);

          if (results is List) {
            loadedSongs = _parseResults(results);
          }
        }
      } catch (e) {
        debugPrint('Backup API Error: $e');
      }
    }

    setState(() {
      _isLoading = false;
      if (loadedSongs.isNotEmpty) {
        _searchResults = loadedSongs;
      } else {
        _errorMessage = 'No playable tracks found for "$query". Please check your connection or try another search.';
      }
    });
  }

  List<OnlineSong> _parseResults(List results) {
    final List<OnlineSong> parsed = [];

    for (var item in results) {
      if (item is! Map) continue;

      // Extract Title
      String title = (item['name'] ?? item['title'] ?? item['song'] ?? 'Unknown Track')
          .toString()
          .replaceAll('&quot;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&amp;', '&');

      // Extract Thumbnail
      String imgUrl = '';
      if (item['image'] is List && (item['image'] as List).isNotEmpty) {
        imgUrl = (item['image'] as List).last['url'] ?? (item['image'] as List).last['link'] ?? '';
      } else if (item['image'] is String) {
        imgUrl = item['image'];
      }

      // Extract Download/Stream URL
      String downloadUrl = '';
      if (item['downloadUrl'] is List && (item['downloadUrl'] as List).isNotEmpty) {
        downloadUrl = (item['downloadUrl'] as List).last['url'] ?? (item['downloadUrl'] as List).last['link'] ?? '';
      } else if (item['media_url'] is String) {
        downloadUrl = item['media_url'];
      } else if (item['url'] is String && item['url'].toString().endsWith('.mp3')) {
        downloadUrl = item['url'];
      }

      // Extract Artist
      String artistName = 'Unknown Artist';
      if (item['artists'] != null && item['artists']['primary'] is List) {
        final primaryList = item['artists']['primary'] as List;
        if (primaryList.isNotEmpty) {
          artistName = primaryList.map((e) => e['name'] ?? '').where((n) => n.toString().isNotEmpty).join(', ');
        }
      } else if (item['primary_artists'] is String) {
        artistName = item['primary_artists'];
      } else if (item['singers'] is String) {
        artistName = item['singers'];
      }

      if (downloadUrl.isNotEmpty) {
        parsed.add(
          OnlineSong(
            id: item['id']?.toString() ?? UniqueKey().toString(),
            title: title,
            artist: artistName.isEmpty ? 'Unknown Artist' : artistName,
            thumbnailUrl: imgUrl,
            streamUrl: downloadUrl,
          ),
        );
      }
    }

    return parsed;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildSearchTab(),
      _buildEmptyTab('CREATE'),
      _buildEmptyTab('PREMIUM'),
    ];

    return PopScope(
      canPop: _currentIndex == 1 && _searchResults.isEmpty && _errorMessage.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex == 1 && (_searchResults.isNotEmpty || _errorMessage.isNotEmpty)) {
          setState(() {
            _searchResults.clear();
            _errorMessage = '';
            _searchController.clear();
          });
        } else if (_currentIndex != 1) {
          setState(() {
            _currentIndex = 1;
          });
        }
      },
      child: Scaffold(
        body: SafeArea(child: pages[_currentIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'CREATE'),
            BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'PREMIUM'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Jump Back In',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 29,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, color: Colors.grey, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      'Box ${index + 1}',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search any song...',
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults.clear();
                          _errorMessage = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF282828),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _performSearch,
          ),
          const SizedBox(height: 16),

          if (_recentSearches.isNotEmpty && _searchResults.isEmpty && _errorMessage.isEmpty) ...[
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  backgroundColor: const Color(0xFF282828),
                  onPressed: () => _performSearch(search),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF282828),
                                ),
                                onPressed: () => _performSearch(_searchController.text),
                                child: const Text('Retry Search', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _searchResults.isNotEmpty
                        ? ListView.builder(
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
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.music_note, color: Colors.purpleAccent),
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
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Browse Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              Expanded(
                                child: GridView.builder(
                                  itemCount: 4,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF282828),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Category ${index + 1}',
                                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String title) {
    return Center(
      child: Text(
        '$title Screen',
        style: const TextStyle(fontSize: 20, color: Colors.grey),
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
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.song.streamUrl);
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
          _rawError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.song.thumbnailUrl,
                height: 240,
                width: 240,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 240,
                  width: 240,
                  color: Colors.purpleAccent,
                  child: const Icon(Icons.music_note, size: 100, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
            Text(
              widget.song.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.song.artist,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),

            if (_isLoadingAudio)
              const Column(
                children: [
                  CircularProgressIndicator(color: Colors.purpleAccent),
                  SizedBox(height: 12),
                  Text('Loading stream...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            else if (_rawError.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF221515),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  _rawError,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              )
            else ...[
              StreamBuilder<Duration>(
                stream: _audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = _audioPlayer.duration ?? Duration.zero;

                  final maxMilliseconds = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;
                  final currentMilliseconds = position.inMilliseconds
                      .toDouble()
                      .clamp(0.0, maxMilliseconds);

                  return Column(
                    children: [
                      Slider(
                        activeColor: Colors.purpleAccent,
                        inactiveColor: Colors.grey[800],
                        min: 0.0,
                        max: maxMilliseconds,
                        value: currentMilliseconds,
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position), style: const TextStyle(color: Colors.grey)),
                            Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final isPlaying = playerState?.playing ?? false;

                  if (processingState == ProcessingState.buffering) {
                    return const CircularProgressIndicator(color: Colors.purpleAccent);
                  }

                  return IconButton(
                    iconSize: 64,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.purpleAccent,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                  );
                },
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
