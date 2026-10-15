import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class TrackItem {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? artworkUrl;
  final DateTime playedAt;
  bool isDownloaded;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
    DateTime? playedAt,
    this.isDownloaded = false,
  }) : playedAt = playedAt ?? DateTime.now();
}

class BoxModel {
  String name;
  final List<TrackItem> tracks;

  BoxModel({required this.name, List<TrackItem>? tracks})
      : tracks = tracks ?? [];
}

class CircleItem {
  String name;
  String imageUrl;

  CircleItem({required this.name, required this.imageUrl});
}

// Unified Home Section item to maintain mixed order of box lines and circle lines
enum HomeSectionType { circleLine, boxLine }

class HomeSection {
  String id;
  HomeSectionType type;
  String name;
  List<BoxModel>? boxes;
  List<CircleItem>? circles;

  HomeSection({
    required this.id,
    required this.type,
    required this.name,
    this.boxes,
    this.circles,
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
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Unified list of home sections allowing mixed order (Circle lines and Box lines)
  final List<HomeSection> _homeSections = [
    HomeSection(
      id: 'circle_line_1',
      type: HomeSectionType.circleLine,
      name: 'Favorite artists',
      circles: [
        CircleItem(name: 'Gill Madhipuriya', imageUrl: ''),
        CircleItem(name: 'Baaghi', imageUrl: ''),
      ],
    ),
    HomeSection(
      id: 'box_line_1',
      type: HomeSectionType.boxLine,
      name: 'Line 1',
      boxes: [
        BoxModel(
          name: 'Top 5 Songs',
          tracks: [
            TrackItem(
              id: 'top_1',
              title: '1. KAROL G, Judeline, rusowsky - BbY WOW',
              artist: 'KAROL G, Judeline, rusowsky',
              url: 'https://archive.org/download/karol-g-judeline-rusowsky-bb-y-wow-visualizer-mp-3_202610/KAROL%20G%2C%20Judeline%2C%20rusowsky%20-%20BbY%20WOW%20%28Visualizer%29_MP3.mp3',
            ),
            TrackItem(
              id: 'top_2',
              title: '2. Shakira, Burna Boy - Dai Dai',
              artist: 'Shakira, Burna Boy',
              url: 'https://archive.org/download/shakira-burna-boy-dai-dai-official-video-mp-3/Shakira%2C%20Burna%20Boy%20-%20Dai%20Dai%20%28Official%20Video%29_MP3.mp3',
            ),
            TrackItem(
              id: 'top_3',
              title: '3. Taylor Swift - Patient Zero',
              artist: 'Taylor Swift',
              url: 'https://archive.org/download/taylor-swift-patient-zero-official-music-video-mp-3/Taylor%20Swift%20-%20Patient%20Zero%20%28Official%20Music%20Video%29_MP3.mp3',
            ),
            TrackItem(
              id: 'top_4',
              title: '4. ADÉLA - Nicole Kidman',
              artist: 'ADÉLA',
              url: 'https://archive.org/download/ade-la-nicole-kidman-mp-3/AD%C3%89LA%20-%20Nicole%20Kidman_MP3.mp3',
            ),
            TrackItem(
              id: 'top_5',
              title: '5. Drake, Don Toliver - Solar Eclipse',
              artist: 'Drake, Don Toliver',
              url: 'https://archive.org/download/drake-don-toliver-solar-eclipse-mp-3/Drake%2C%20Don%20Toliver%20-%20Solar%20Eclipse_MP3.mp3',
            ),
          ],
        ),
      ],
    ),
    HomeSection(
      id: 'box_line_2',
      type: HomeSectionType.boxLine,
      name: 'Line 2',
      boxes: [
        BoxModel(
          name: 'ASTARR Hits',
          tracks: [
            TrackItem(
              id: 'astarr_1',
              title: 'ASTARR (OFFICIAL VIDEO) PREM DHILLON',
              artist: 'Prem Dhillon',
              url: 'https://archive.org/download/astarr-official-video-prem-dhillon-cheetah-4-da-gang-latest-punjabi-songs-2024-mp-3.mp-3-1-1/ASTARR%20%28OFFICIAL%20VIDEO%29%20PREM%20DHILLON%20%20CHEETAH%20%204%20Da%20Gang%20%20LATEST%20PUNJABI%20SONGS%202024_MP3.mp3%20%281%29%20%281%29.m4a',
            ),
          ],
        ),
        BoxModel(name: 'golden hour', tracks: []),
      ],
    ),
  ];

  final List<TrackItem> _playlist = [];
  final List<TrackItem> _likedSongs = [];
  final List<TrackItem> _downloads = [];
  final List<TrackItem> _recents = [];

  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;
  bool _isRemoveMode = false;
  bool _isCircleRemoveMode = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
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
    super.dispose();
  }

  Future<void> _playTrack(TrackItem track) async {
    if (track.url.trim().isEmpty || !track.url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error playing track: (0) Source error')),
      );
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingTrack = track;
        _recents.insert(0, track);
      });

      await _audioPlayer.setUrl(Uri.encodeFull(Uri.decodeFull(track.url)));
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

  void _downloadTrack(TrackItem track) {
    if (!_downloads.any((t) => t.id == track.id)) {
      setState(() {
        track.isDownloaded = true;
        _downloads.add(track);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded "${track.title}" successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song is already downloaded')),
      );
    }
  }

  void _addNewBoxDialog() {
    final boxLines = _homeSections.where((s) => s.type == HomeSectionType.boxLine).toList();
    if (boxLines.isEmpty) return;
    int selectedLineIndex = 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF242424),
            title: const Text('Add New Box'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Box Name',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Select Line: '),
                    DropdownButton<int>(
                      value: selectedLineIndex,
                      dropdownColor: const Color(0xFF242424),
                      items: List.generate(boxLines.length, (i) {
                        return DropdownMenuItem(value: i, child: Text(boxLines[i].name));
                      }),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedLineIndex = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim().isEmpty ? 'New Box' : controller.text.trim();
                  setState(() {
                    boxLines[selectedLineIndex].boxes?.add(BoxModel(name: name));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addNewBoxLine() {
    setState(() {
      _homeSections.add(HomeSection(
        id: 'box_line_${DateTime.now().millisecondsSinceEpoch}',
        type: HomeSectionType.boxLine,
        name: 'Line ${_homeSections.where((s) => s.type == HomeSectionType.boxLine).length + 1}',
        boxes: [],
      ));
    });
  }

  void _addNewCircularLine() {
    setState(() {
      _homeSections.add(HomeSection(
        id: 'circle_line_${DateTime.now().millisecondsSinceEpoch}',
        type: HomeSectionType.circleLine,
        name: 'Favorite artists ${_homeSections.where((s) => s.type == HomeSectionType.circleLine).length + 1}',
        circles: [],
      ));
    });
  }

  void _addCircleToLineDialog() {
    final circleLines = _homeSections.where((s) => s.type == HomeSectionType.circleLine).toList();
    if (circleLines.isEmpty) return;
    int selectedLineIndex = 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF242424),
            title: const Text('Add Circle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Artist / Circle Name',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Select Line: '),
                    DropdownButton<int>(
                      value: selectedLineIndex,
                      dropdownColor: const Color(0xFF242424),
                      items: List.generate(circleLines.length, (i) {
                        return DropdownMenuItem(value: i, child: Text(circleLines[i].name));
                      }),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedLineIndex = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim().isEmpty ? 'Artist' : controller.text.trim();
                  setState(() {
                    circleLines[selectedLineIndex].circles?.add(CircleItem(name: name, imageUrl: ''));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteBox(HomeSection section, int boxIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Remove Box'),
        content: Text('Are you sure to remove "${section.boxes?[boxIndex].name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isRemoveMode = false);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
            onPressed: () {
              setState(() {
                section.boxes?.removeAt(boxIndex);
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

  void _confirmDeleteCircle(HomeSection section, int circleIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Remove Circle'),
        content: Text('Are you sure to remove "${section.circles?[circleIndex].name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isCircleRemoveMode = false);
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
            onPressed: () {
              setState(() {
                section.circles?.removeAt(circleIndex);
                _isCircleRemoveMode = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _openTrack3DotsMenu(TrackItem track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.music_note, size: 40, color: Colors.white),
                  title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(track.artist),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (track.url.isNotEmpty) {
                      Share.share('Check out this song: ${track.title}\n${track.url}');
                    }
                  },
                ),
                ListTile(
                  leading: Icon(_isLiked(track) ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                  title: Text(_isLiked(track) ? 'Remove from Liked Songs' : 'Add to Liked Songs'),
                  onTap: () {
                    _toggleLike(track);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download'),
                  onTap: () {
                    _downloadTrack(track);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: const Text('Add to playlist'),
                  onTap: () {
                    setState(() => _playlist.add(track));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Playlist')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.album),
                  title: const Text('Go to album'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF242424),
                        title: const Text('Album Info'),
                        content: Text('Track: ${track.title}\nArtist: ${track.artist}\nRelease: 2026'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullPlayerModal(TrackItem track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
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
                      Text(track.artist, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _openTrack3DotsMenu(track),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: const Color(0xFF282828),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            track.artworkUrl != null
                                ? Image.network(track.artworkUrl!, fit: BoxFit.cover, width: double.infinity)
                                : const Center(child: Icon(Icons.music_note, size: 100, color: Colors.white24)),
                            // Playing Animation Overlay
                            if (_isPlaying)
                              Positioned(
                                bottom: 20,
                                child: Row(
                                  children: List.generate(4, (i) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 4,
                                    height: 20 + (i * 8).toDouble(),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                                  )),
                                ),
                              ),
                          ],
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
                            Text(track.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1),
                            const SizedBox(height: 4),
                            Text(track.artist, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isLiked(track) ? Icons.favorite : Icons.favorite_border, color: _isLiked(track) ? Colors.white : Colors.white54, size: 28),
                        onPressed: () {
                          _toggleLike(track);
                          setModalState(() {});
                          setState(() {});
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
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
                    onChanged: (val) => _audioPlayer.seek(Duration(seconds: val.toInt())),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
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
                          } else {
                            _audioPlayer.play();
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
      key: _scaffoldKey,
      drawer: _buildLeftDrawer(),
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        backgroundColor: const Color(0xFF121212),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_music), label: 'YOUR LIBRARY'),
        ],
      ),
    );
  }

  // ================= LEFT DRAWER =================
  Widget _buildLeftDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF181818),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF282828)),
            accountName: const Text('Gurinderbir Sidhu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: const Text('View profile', style: TextStyle(color: Colors.white54)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text('G', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recents'),
            onTap: () {
              Navigator.pop(context);
              _openRecentsScreen();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Template'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: const Color(0xFF242424),
                  title: const Text('White-Label Music App'),
                  content: const Text('Commercial Flutter music player boilerplate ready for rebranding and publishing.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openRecentsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Recents'), backgroundColor: const Color(0xFF181818)),
          body: _recents.isEmpty
              ? const Center(child: Text('No recently played songs.'))
              : ListView.builder(
                  itemCount: _recents.length,
                  itemBuilder: (context, index) {
                    final track = _recents[index];
                    final dateStr = '${track.playedAt.year}-${track.playedAt.month.toString().padLeft(2, '0')}-${track.playedAt.day.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.white),
                      title: Text(track.title),
                      subtitle: Text('$dateStr • ${track.artist}'),
                      onTap: () => _playTrack(track),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ================= HOME TAB =================
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, size: 28),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const Text('Your Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 28),
                  color: const Color(0xFF242424),
                  onSelected: (val) {
                    if (val == 'new') {
                      _addNewBoxDialog();
                    } else if (val == 'remove') {
                      setState(() => _isRemoveMode = !_isRemoveMode);
                    } else if (val == 'circle_remove') {
                      setState(() => _isCircleRemoveMode = !_isCircleRemoveMode);
                    } else if (val == 'new_box_line') {
                      _addNewBoxLine();
                    } else if (val == 'new_circle_line') {
                      _addNewCircularLine();
                    } else if (val == 'add_circle') {
                      _addCircleToLineDialog();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'new', child: Text('New box')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove box')),
                    const PopupMenuItem(value: 'circle_remove', child: Text('Remove circle')),
                    const PopupMenuItem(value: 'new_box_line', child: Text('Add box line')),
                    const PopupMenuItem(value: 'new_circle_line', child: Text('Add a new circular line')),
                    const PopupMenuItem(value: 'add_circle', child: Text('Add a circle in line')),
                  ],
                ),
              ],
            ),
          ),
          if (_isRemoveMode)
            Container(
              color: Colors.white12,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tap a box to remove',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => setState(() => _isRemoveMode = false),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          if (_isCircleRemoveMode)
            Container(
              color: Colors.white12,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tap a circle to remove',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => setState(() => _isCircleRemoveMode = false),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // Render Home Sections in user-added order
          ..._homeSections.map((section) {
            if (section.type == HomeSectionType.circleLine) {
              return _buildCircleLineSection(section);
            } else {
              return _buildBoxLineSection(section);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildCircleLineSection(HomeSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(section.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.white38),
                onPressed: () {
                  final controller = TextEditingController(text: section.name);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF242424),
                      title: const Text('Rename Circle Line'),
                      content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              setState(() => section.name = controller.text.trim());
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                onPressed: () {
                  setState(() => _homeSections.remove(section));
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: (section.circles == null || section.circles!.isEmpty)
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No artists in this line. Use menu to add.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: section.circles!.length,
                  itemBuilder: (context, index) {
                    final circle = section.circles![index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          if (_isCircleRemoveMode) {
                            _confirmDeleteCircle(section, index);
                          }
                        },
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, size: 35, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              circle.name,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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

  Widget _buildBoxLineSection(HomeSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(section.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.white38),
                onPressed: () {
                  final controller = TextEditingController(text: section.name);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF242424),
                      title: Text('Rename ${section.name}'),
                      content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              setState(() => section.name = controller.text.trim());
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                onPressed: () {
                  setState(() => _homeSections.remove(section));
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: (section.boxes == null || section.boxes!.isEmpty)
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No boxes in this line. Use menu to add.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: section.boxes!.length,
                  itemBuilder: (context, index) {
                    final box = section.boxes![index];
                    return Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () {
                          if (_isRemoveMode) {
                            _confirmDeleteBox(section, index);
                          } else {
                            _openSpotifyStylePlaylist(box);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.music_note, color: Colors.white, size: 24),
                              Text(box.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openSpotifyStylePlaylist(BoxModel box) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(ctx)),
                      const Icon(Icons.more_vert),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(box.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Custom curated playlist', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Spacer(),
                      FloatingActionButton(
                        backgroundColor: Colors.white,
                        mini: true,
                        onPressed: () {
                          if (box.tracks.isNotEmpty) {
                            Navigator.pop(ctx);
                            _playTrack(box.tracks.first);
                          }
                        },
                        child: const Icon(Icons.play_arrow, color: Colors.black),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: box.tracks.isEmpty
                        ? const Center(child: Text('No tracks in this playlist.'))
                        : ListView.builder(
                            itemCount: box.tracks.length,
                            itemBuilder: (context, index) {
                              final track = box.tracks[index];
                              final liked = _isLiked(track);

                              return ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(4)),
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                                title: Text(track.title, maxLines: 1),
                                subtitle: Text(track.artist, maxLines: 1),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.white : Colors.white38),
                                      onPressed: () {
                                        _toggleLike(track);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert, color: Colors.white38),
                                      onPressed: () => _openTrack3DotsMenu(track),
                                    ),
                                  ],
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

  // ================= SEARCH TAB =================
  Widget _buildSearchScreen() {
    return ITunesSearchWidget(
      onPlayTrack: _playTrack,
      onToggleLike: _toggleLike,
      isLiked: _isLiked,
      onAddToPlaylist: (track) {
        setState(() => _playlist.add(track));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${track.title}" to YOUR LIBRARY')));
      },
      onOpenMenu: _openTrack3DotsMenu,
    );
  }

  // ================= YOUR LIBRARY TAB =================
  Widget _buildPlaylistScreen() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: const Text('Your Library'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Playlists & Liked'),
              Tab(text: 'Downloads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openLikedSongsDialog,
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text('Liked Songs (${_likedSongs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                leading: const Icon(Icons.music_note, color: Colors.white),
                                title: Text(track.title),
                                subtitle: Text(track.artist),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _openTrack3DotsMenu(track),
                                ),
                                onTap: () => _playTrack(track),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Downloaded Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _downloads.isEmpty
                        ? const Center(child: Text('No downloaded songs yet.'))
                        : ListView.builder(
                            itemCount: _downloads.length,
                            itemBuilder: (context, index) {
                              final track = _downloads[index];
                              return ListTile(
                                leading: const Icon(Icons.download_done, color: Colors.white),
                                title: Text(track.title),
                                subtitle: Text(track.artist),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _openTrack3DotsMenu(track),
                                ),
                                onTap: () => _playTrack(track),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                              return ListTile(
                                title: Text(track.title),
                                subtitle: Text(track.artist),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _openTrack3DotsMenu(track),
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
  final Function(TrackItem) onOpenMenu;

  const ITunesSearchWidget({
    super.key,
    required this.onPlayTrack,
    required this.onToggleLike,
    required this.isLiked,
    required this.onAddToPlaylist,
    required this.onOpenMenu,
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
        if (mounted) {
          setState(() {
            _searchResults = data['results'] ?? [];
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
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
              hintText: 'Search iTunes Previews...',
              filled: true,
              fillColor: const Color(0xFF282828),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => _searchITunes(_searchController.text),
              ),
            ),
            onSubmitted: _searchITunes,
          ),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(color: Colors.white),
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
                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.white : Colors.white38),
                        onPressed: () {
                          widget.onToggleLike(track);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white38),
                        onPressed: () => widget.onOpenMenu(track),
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
