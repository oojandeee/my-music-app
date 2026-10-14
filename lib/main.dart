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

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
    DateTime? playedAt,
  }) : playedAt = playedAt ?? DateTime.now();
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
          primary: Color(0xFFB31919), // Dark Red Theme Accent
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

  String line1Name = "Line 1";
  String line2Name = "Line 2";

  final List<BoxModel> _line1Boxes = [
    BoxModel(name: 'Discover Weekly', tracks: [
      TrackItem(
        id: 'astarr_1',
        title: 'ASTARR (OFFICIAL VIDEO) PREM DHILLON',
        artist: 'Prem Dhillon',
        url: 'https://archive.org/download/astarr-official-video-prem-dhillon-cheetah-4-da-gang-latest-punjabi-songs-2024-mp-3.mp-3-1-1/ASTARR%20%28OFFICIAL%20VIDEO%29%20PREM%20DHILLON%20%20CHEETAH%20%204%20Da%20Gang%20%20LATEST%20PUNJABI%20SONGS%202024_MP3.mp3%20%281%29%20%281%29.m4a',
      ),
    ]),
    BoxModel(name: 'golden hour', tracks: []),
  ];

  final List<BoxModel> _line2Boxes = [
    BoxModel(name: 'big on the internet', tracks: []),
    BoxModel(name: 'Classic Road Trip', tracks: []),
  ];

  final List<TrackItem> _playlist = [];
  final List<TrackItem> _likedSongs = [];
  final List<TrackItem> _recents = [];

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
        const SnackBar(content: Text('Invalid or Unreachable URL')),
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

  void _addCustomUrlToBox(BoxModel box) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: Text('Add Link to ${box.name}'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Paste direct song URL (e.g. http://...)',
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
              String input = controller.text.trim();
              if (input.isEmpty || !input.startsWith('http')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid URL entered')),
                );
                Navigator.pop(ctx);
                return;
              }

              // Extract readable track title from encoded URL
              String decoded = Uri.decodeComponent(input.split('/').last);
              decoded = decoded.replaceAll(RegExp(r'_MP3.*|_m4a.*|\.[^.]+$'), '').replaceAll('_', ' ');

              setState(() {
                box.tracks.add(
                  TrackItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: decoded.isEmpty ? 'Custom Song' : decoded,
                    artist: 'Web Stream',
                    url: input,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewBoxDialog() {
    int selectedLine = 1;
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
                      value: selectedLine,
                      dropdownColor: const Color(0xFF242424),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Line 1')),
                        DropdownMenuItem(value: 2, child: Text('Line 2')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedLine = val);
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
                    if (selectedLine == 1) {
                      _line1Boxes.add(BoxModel(name: name));
                    } else {
                      _line2Boxes.add(BoxModel(name: name));
                    }
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

  void _renameLineDialog(int lineNum) {
    final controller = TextEditingController(text: lineNum == 1 ? line1Name : line2Name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: Text('Rename Line $lineNum'),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  if (lineNum == 1) {
                    line1Name = controller.text.trim();
                  } else {
                    line2Name = controller.text.trim();
                  }
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
                  leading: const Icon(Icons.music_note, size: 40, color: Color(0xFFB31919)),
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
                  leading: Icon(_isLiked(track) ? Icons.favorite : Icons.favorite_border, color: _isLiked(track) ? Colors.redAccent : Colors.white),
                  title: Text(_isLiked(track) ? 'Remove from Liked Songs' : 'Add to Liked Songs'),
                  onTap: () {
                    _toggleLike(track);
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
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('View song credits'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: const Color(0xFF242424),
                        title: Text(track.title),
                        content: Text('Artist: ${track.artist}\nSource: Web Stream'),
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
      backgroundColor: const Color(0xFF2D0B0E), // Spotify Dark Red Player Background
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
                        color: const Color(0xFF1E1E1E),
                        child: track.artworkUrl != null
                            ? Image.network(track.artworkUrl!, fit: BoxFit.cover, width: double.infinity)
                            : const Center(child: Icon(Icons.music_note, size: 100, color: Colors.white24)),
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
                        icon: Icon(_isLiked(track) ? Icons.favorite : Icons.favorite_border, color: _isLiked(track) ? Colors.redAccent : Colors.white54, size: 28),
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
        selectedItemColor: const Color(0xFFE50914),
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
              backgroundColor: Color(0xFFB31919),
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
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('Your Updates'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings and privacy'),
            onTap: () => Navigator.pop(context),
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
                    return ListTile(
                      leading: const Icon(Icons.music_note, color: Color(0xFFB31919)),
                      title: Text(track.title),
                      subtitle: Text('Today • ${track.artist}'),
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
              color: Colors.amber.withOpacity(0.2),
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Tap a box to remove',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
              ),
            ),
          _buildLineSection(line1Name, _line1Boxes, 1),
          const SizedBox(height: 16),
          _buildLineSection(line2Name, _line2Boxes, 2),
        ],
      ),
    );
  }

  Widget _buildLineSection(String title, List<BoxModel> boxes, int lineNum) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.white38),
                onPressed: () => _renameLineDialog(lineNum),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: boxes.length,
            itemBuilder: (context, index) {
              final box = boxes[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    if (_isRemoveMode) {
                      setState(() => boxes.removeAt(index));
                    } else {
                      _openSpotifyStylePlaylist(box);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.music_note, color: Color(0xFFB31919), size: 28),
                        Text(box.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2),
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
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white70),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _addCustomUrlToBox(box);
                        },
                      ),
                      const Spacer(),
                      FloatingActionButton(
                        backgroundColor: const Color(0xFFB31919),
                        mini: true,
                        onPressed: () {
                          if (box.tracks.isNotEmpty) {
                            Navigator.pop(ctx);
                            _playTrack(box.tracks.first);
                          }
                        },
                        child: const Icon(Icons.play_arrow, color: Colors.white),
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
                                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.redAccent : Colors.white38),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${track.title}" to PLAYLIST')));
      },
      onOpenMenu: _openTrack3DotsMenu,
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
                        leading: const Icon(Icons.music_note, color: Color(0xFFB31919)),
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
                icon: const Icon(Icons.search, color: Color(0xFFB31919)),
                onPressed: () => _searchITunes(_searchController.text),
              ),
            ),
            onSubmitted: _searchITunes,
          ),
          const SizedBox(height: 16),
          if (_isLoading) const CircularProgressIndicator(color: Color(0xFFB31919)),
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
                        icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.redAccent : Colors.white38),
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
