import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_lib;

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

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Default to SEARCH tab

  final TextEditingController _searchController = TextEditingController();
  final yt_lib.YoutubeExplode _yt = yt_lib.YoutubeExplode();

  final List<String> _recentSearches = [];
  List<OnlineSong> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      _searchController.text = query;
    });

    try {
      final searchList = await _yt.search.search(query);
      setState(() {
        _searchResults = searchList.map((video) {
          return OnlineSong(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            thumbnailUrl: video.thumbnails.highResUrl,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _yt.close();
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

    return Scaffold(
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
    );
  }

  // --- HOME TAB ---
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

  // --- SEARCH TAB ---
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

          if (_recentSearches.isNotEmpty) ...[
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

// --- PLAYER SCREEN (INSTANT PLAYBACK & STREAM FIX) ---
class PlayerScreen extends StatefulWidget {
  final OnlineSong song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayer _audioPlayer;
  final yt_lib.YoutubeExplode _yt = yt_lib.YoutubeExplode();

  bool _isLoadingAudio = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Fast-start buffering: Plays after 500ms buffered without downloading the full file
    _audioPlayer = AudioPlayer(
      audioLoadConfiguration: const AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferMs: 1000,
          maxBufferMs: 50000,
          bufferForPlaybackMs: 500, // Starts immediately on 0.5s of buffer
          bufferForPlaybackAfterRebufferMs: 1000,
        ),
        darwinLoadControl: DarwinLoadControl(
          preferredForwardBufferDuration: Duration(seconds: 1),
        ),
      ),
    );

    _loadAndPlayAudio();
  }

  Future<void> _loadAndPlayAudio() async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(widget.song.id);

      yt_lib.StreamInfo? streamInfo;
      if (manifest.audioOnly.isNotEmpty) {
        streamInfo = manifest.audioOnly.withHighestBitrate();
      } else if (manifest.muxed.isNotEmpty) {
        streamInfo = manifest.muxed.withHighestBitrate();
      }

      if (streamInfo != null) {
        final audioUrl = streamInfo.url.toString();

        // 1. Prepare player to stream immediately
        _audioPlayer.play();

        // 2. Set Audio Source with User-Agent header so YouTube servers don't drop the connection
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ),
          preload: true,
        );

        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
          });
        }
      } else {
        throw Exception("No streamable audio found.");
      }
    } catch (e) {
      debugPrint("Audio extraction error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Unable to play track. Try another song.";
          _isLoadingAudio = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _yt.close();
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
                height: 260,
                width: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 260,
                  width: 260,
                  color: Colors.purpleAccent,
                  child: const Icon(Icons.music_note, size: 100, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
            Text(
              widget.song.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.song.artist,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),

            if (_isLoadingAudio)
              const CircularProgressIndicator(color: Colors.purpleAccent)
            else if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))
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

              const SizedBox(height: 10),

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
                    iconSize: 72,
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
