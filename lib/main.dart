import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class TrackItem {
  final String id;
  final String title;
  final String artist;
  final String url;
  final bool isLocal;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.isLocal = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: Color(0xFF181824),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 4 Boxes storing local/custom tracks
  final List<List<TrackItem>> _boxes = [[], [], [], []];
  final List<TrackItem> _likedSongs = [];

  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playTrack(TrackItem track) async {
    try {
      if (track.isLocal) {
        await _audioPlayer.setFilePath(track.url);
      } else {
        await _audioPlayer.setUrl(track.url);
      }
      setState(() {
        _currentPlayingTrack = track;
      });
      _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing track: $e')),
      );
    }
  }

  void _toggleLike(TrackItem track) {
    setState(() {
      final exists = _likedSongs.any((item) => item.id == track.id);
      if (exists) {
        _likedSongs.removeWhere((item) => item.id == track.id);
      } else {
        _likedSongs.add(track);
      }
    });
  }

  bool _isLiked(TrackItem track) {
    return _likedSongs.any((item) => item.id == track.id);
  }

  Future<void> _pickFileForBox(int boxIndex) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'mp4'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _boxes[boxIndex].add(
              TrackItem(
                id: file.path!,
                title: file.name,
                artist: 'Local Media',
                url: file.path!,
                isLocal: true,
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeScreen(),
      _buildSearchScreen(),
      _buildPlaylistScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white38,
        backgroundColor: const Color(0xFF181824),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'PLAYLIST'),
        ],
      ),
    );
  }

  // ================= HOME TAB =================
  Widget _buildHomeScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: _openLikedSongsDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.2),
                border: Border.all(color: Colors.deepPurpleAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Liked Songs (${_likedSongs.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final boxTracks = _boxes[index];
              final isEmpty = boxTracks.isEmpty;

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181824),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  children: [
                    if (isEmpty)
                      Center(
                        child: IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurpleAccent),
                          onPressed: () => _pickFileForBox(index),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Box ${index + 1} (${boxTracks.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: boxTracks.length,
                              itemBuilder: (ctx, tIndex) {
                                final track = boxTracks[tIndex];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      _isLiked(track) ? Icons.favorite : Icons.favorite_border,
                                      color: _isLiked(track) ? Colors.redAccent : Colors.white38,
                                      size: 18,
                                    ),
                                    onPressed: () => _toggleLike(track),
                                  ),
                                  onTap: () => _playTrack(track),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    if (!isEmpty)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.deepPurpleAccent, size: 22),
                          onPressed: () => _pickFileForBox(index),
                        ),
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

  void _openLikedSongsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181824),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Liked Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: _likedSongs.isEmpty
                    ? const Center(child: Text('No liked songs yet.'))
                    : ListView.builder(
                        itemCount: _likedSongs.length,
                        itemBuilder: (context, index) {
                          final track = _likedSongs[index];
                          return ListTile(
                            title: Text(track.title),
                            subtitle: Text(track.artist),
                            trailing: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.redAccent),
                              onPressed: () => _toggleLike(track),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _playTrack(track);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= SEARCH TAB (iTunes 30s Previews) =================
  Widget _buildSearchScreen() {
    return const ITunesSearchWidget();
  }

  // ================= PLAYLIST TAB =================
  Widget _buildPlaylistScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 64, color: Colors.deepPurpleAccent),
          const SizedBox(height: 16),
          Text(
            _currentPlayingTrack != null
                ? 'Now Playing: ${_currentPlayingTrack!.title}'
                : 'No Track Playing',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          IconButton(
            iconSize: 54,
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            color: Colors.deepPurpleAccent,
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

class ITunesSearchWidget extends StatefulWidget {
  const ITunesSearchWidget({super.key});

  @override
  State<ITunesSearchWidget> createState() => _ITunesSearchWidgetState();
}

class _ITunesSearchWidgetState extends State<ITunesSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchITunes(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=25'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['results'] ?? [];
        });
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search iTunes 30s Previews...',
              filled: true,
              fillColor: const Color(0xFF181824),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.deepPurpleAccent),
                onPressed: () => _searchITunes(_searchController.text),
              ),
            ),
            onSubmitted: _searchITunes,
          ),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(color: Colors.deepPurpleAccent),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return ListTile(
                  leading: item['artworkUrl100'] != null
                      ? Image.network(item['artworkUrl100'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                  title: Text(item['trackName'] ?? 'Unknown Track'),
                  subtitle: Text(item['artistName'] ?? 'Unknown Artist'),
                  trailing: const Icon(Icons.play_arrow, color: Colors.deepPurpleAccent),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
