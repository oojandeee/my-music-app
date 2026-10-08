import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class TrackItem {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? artworkUrl;
  final bool isLocal;
  final bool isVideo;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
    this.isLocal = false,
    this.isVideo = false,
  });
}

class BoxModel {
  String name;
  final List<TrackItem> tracks;

  BoxModel({required this.name, List<TrackItem>? tracks})
      : tracks = tracks ?? [];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          surface: Color(0xFF181818),
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
  VideoPlayerController? _videoController;

  final List<BoxModel> _boxes = [
    BoxModel(name: 'Discover Weekly'),
    BoxModel(name: 'golden hour'),
    BoxModel(name: 'big on the internet'),
    BoxModel(name: 'Classic Road Trip'),
  ];

  final List<TrackItem> _playlist = [];
  final List<TrackItem> _likedSongs = [];

  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;
  bool _isRemoveMode = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _playTrack(TrackItem track) async {
    await _audioPlayer.stop();
    await _videoController?.dispose();
    _videoController = null;

    setState(() {
      _currentPlayingTrack = track;
    });

    try {
      if (track.isVideo && track.isLocal) {
        _videoController = VideoPlayerController.file(File(track.url));
        await _videoController!.initialize();
        _videoController!.play();
      }

      if (track.isLocal) {
        await _audioPlayer.setFilePath(track.url);
      } else {
        await _audioPlayer.setUrl(track.url);
      }
      _audioPlayer.play();
      _openFullPlayerModal(track);
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
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'mp4'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      bool unsupportedFound = false;

      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            final ext = file.extension?.toLowerCase() ?? '';
            final valid = ['mp3', 'wav', 'm4a', 'aac', 'mp4'].contains(ext);

            if (valid) {
              final isVideo = ext == 'mp4';
              _boxes[boxIndex].tracks.add(
                    TrackItem(
                      id: file.path!,
                      title: file.name,
                      artist: isVideo ? 'Local Video' : 'Local Audio',
                      url: file.path!,
                      isLocal: true,
                      isVideo: isVideo,
                    ),
                  );
            } else {
              unsupportedFound = true;
            }
          }
        }
      });

      if (unsupportedFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not supported')),
        );
      }
    }
  }

  void _renameBox(int index) {
    final controller = TextEditingController(text: _boxes[index].name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Rename Box'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter box name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _boxes[index].name = controller.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBox(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Remove Box'),
        content: Text('Do you really want to remove "${_boxes[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _boxes.removeAt(index);
                _isRemoveMode = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _openFullPlayerModal(TrackItem track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      Column(
                        children: [
                          const Text(
                            'PLAYING FROM PODCAST / MEDIA',
                            style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.white54),
                          ),
                          Text(
                            track.artist,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.more_vert),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: const Color(0xFF1E1E1E),
                        child: track.isVideo && _videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : track.artworkUrl != null
                                ? Image.network(track.artworkUrl!, fit: BoxFit.cover, width: double.infinity)
                                : const Center(
                                    child: Icon(Icons.music_note, size: 100, color: Colors.white24),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track.artist,
                              style: const TextStyle(fontSize: 14, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isLiked(track) ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked(track) ? Colors.redAccent : Colors.white54,
                          size: 28,
                        ),
                        onPressed: () {
                          _toggleLike(track);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    min: 0.0,
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                    value: _position.inSeconds.toDouble().clamp(
                          0.0,
                          _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                        ),
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position), style: const TextStyle(fontSize: 12, color: Colors.white54)),
                        Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, size: 30),
                        onPressed: () => _audioPlayer.seek(_position - const Duration(seconds: 10)),
                      ),
                      IconButton(
                        iconSize: 64,
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                        color: Colors.white,
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                            _videoController?.pause();
                          } else {
                            _audioPlayer.play();
                            _videoController?.play();
                          }
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, size: 30),
                        onPressed: () => _audioPlayer.seek(_position + const Duration(seconds: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white38,
        backgroundColor: const Color(0xFF121212),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu, size: 28),
                color: const Color(0xFF242424),
                onSelected: (val) {
                  if (val == 'new') {
                    setState(() {
                      _boxes.add(BoxModel(name: 'New Box ${_boxes.length + 1}'));
                    });
                  } else if (val == 'remove') {
                    setState(() {
                      _isRemoveMode = !_isRemoveMode;
                    });
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'new', child: Text('New box')),
                  const PopupMenuItem(value: 'remove', child: Text('Remove box')),
                ],
              ),
            ],
          ),
        ),
        if (_isRemoveMode)
          Container(
            color: Colors.redAccent.withOpacity(0.2),
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Tap a box to remove',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemCount: _boxes.length,
            itemBuilder: (context, index) {
              final box = _boxes[index];
              final isEmpty = box.tracks.isEmpty;

              return InkWell(
                onTap: () {
                  if (_isRemoveMode) {
                    _confirmDeleteBox(index);
                  } else {
                    _openBoxDetailDialog(box, index);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF383838),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              isEmpty ? Icons.add : Icons.music_note,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () => _pickFileForBox(index),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          box.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: Colors.white38),
                        onPressed: () => _renameBox(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openBoxDetailDialog(BoxModel box, int boxIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(box.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.greenAccent),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickFileForBox(boxIndex);
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: box.tracks.isEmpty
                    ? const Center(child: Text('No tracks in this box.'))
                    : ListView.builder(
                        itemCount: box.tracks.length,
                        itemBuilder: (context, index) {
                          final track = box.tracks[index];
                          return ListTile(
                            title: Text(track.title),
                            subtitle: Text(track.artist),
                            trailing: IconButton(
                              icon: Icon(
                                _isLiked(track) ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked(track) ? Colors.redAccent : Colors.white38,
                              ),
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

  // ================= SEARCH TAB =================
  Widget _buildSearchScreen() {
    return ITunesSearchWidget(
      onPlayTrack: _playTrack,
      onToggleLike: _toggleLike,
      isLiked: _isLiked,
      onAddToPlaylist: (track) {
        setState(() {
          _playlist.add(track);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${track.title}" to PLAYLIST')),
        );
      },
    );
  }

  // ================= PLAYLIST TAB =================
  Widget _buildPlaylistScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _openLikedSongsDialog,
            child: Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Liked Songs (${_likedSongs.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Your Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: _playlist.isEmpty
                ? const Center(child: Text('Playlist is empty.'))
                : ListView.builder(
                    itemCount: _playlist.length,
                    itemBuilder: (context, index) {
                      final track = _playlist[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.greenAccent),
                        title: Text(track.title),
                        subtitle: Text(track.artist),
                        trailing: IconButton(
                          icon: Icon(
                            _isLiked(track) ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked(track) ? Colors.redAccent : Colors.white38,
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
    );
  }

  void _openLikedSongsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Liked Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _likedSongs.isEmpty
                        ? const Center(child: Text('No liked songs.'))
                        : ListView.builder(
                            itemCount: _likedSongs.length,
                            itemBuilder: (context, index) {
                              final track = _likedSongs[index];
                              final liked = _isLiked(track);

                              return ListTile(
                                title: Text(track.title),
                                subtitle: Text(track.artist),
                                trailing: IconButton(
                                  icon: Icon(
                                    liked ? Icons.favorite : Icons.favorite_border,
                                    color: liked ? Colors.redAccent : Colors.white38,
                                  ),
                                  onPressed: () {
                                    _toggleLike(track);
                                    setModalState(() {});
                                  },
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
      },
    );
  }
}

class ITunesSearchWidget extends StatefulWidget {
  final Function(TrackItem) onPlayTrack;
  final Function(TrackItem) onToggleLike;
  final bool Function(TrackItem) isLiked;
  final Function(TrackItem) onAddToPlaylist;

  const ITunesSearchWidget({
    super.key,
    required this.onPlayTrack,
    required this.onToggleLike,
    required this.isLiked,
    required this.onAddToPlaylist,
  });

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
              fillColor: const Color(0xFF282828),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.greenAccent),
                onPressed: () => _searchITunes(_searchController.text),
              ),
            ),
            onSubmitted: _searchITunes,
          ),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(color: Colors.greenAccent),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                final track = TrackItem(
                  id: item['trackId']?.toString() ?? index.toString(),
                  title: item['trackName'] ?? 'Unknown Track',
                  artist: item['artistName'] ?? 'Unknown Artist',
                  url: item['previewUrl'] ?? '',
                  artworkUrl: item['artworkUrl100'],
                );

                final liked = widget.isLiked(track);

                return ListTile(
                  leading: item['artworkUrl100'] != null
                      ? Image.network(item['artworkUrl100'], width: 48, height: 48, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? Colors.redAccent : Colors.white38,
                        ),
                        onPressed: () {
                          widget.onToggleLike(track);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.greenAccent),
                        onPressed: () => widget.onAddToPlaylist(track),
                      ),
                    ],
                  ),
                  onTap: () => widget.onPlayTrack(track),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
