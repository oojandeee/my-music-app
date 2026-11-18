import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'url': url,
        'artworkUrl': artworkUrl,
        'playedAt': playedAt.toIso8601String(),
        'isDownloaded': isDownloaded,
      };

  factory TrackItem.fromJson(Map<String, dynamic> json) => TrackItem(
        id: json['id'],
        title: json['title'],
        artist: json['artist'],
        url: json['url'],
        artworkUrl: json['artworkUrl'],
        playedAt: json['playedAt'] != null ? DateTime.parse(json['playedAt']) : DateTime.now(),
        isDownloaded: json['isDownloaded'] ?? false,
      );
}

class BoxModel {
  String name;
  final List<TrackItem> tracks;

  BoxModel({required this.name, List<TrackItem>? tracks})
      : tracks = tracks ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'tracks': tracks.map((t) => t.toJson()).toList(),
      };

  factory BoxModel.fromJson(Map<String, dynamic> json) => BoxModel(
        name: json['name'],
        tracks: (json['tracks'] as List?)?.map((t) => TrackItem.fromJson(t)).toList() ?? [],
      );
}

class CircleItem {
  String name;
  String imageUrl;

  CircleItem({required this.name, required this.imageUrl});

  Map<String, dynamic> toJson() => {'name': name, 'imageUrl': imageUrl};

  factory CircleItem.fromJson(Map<String, dynamic> json) =>
      CircleItem(name: json['name'], imageUrl: json['imageUrl'] ?? '');
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'boxes': boxes?.map((b) => b.toJson()).toList(),
        'circles': circles?.map((c) => c.toJson()).toList(),
      };

  factory HomeSection.fromJson(Map<String, dynamic> json) => HomeSection(
        id: json['id'],
        type: HomeSectionType.values[json['type']],
        name: json['name'],
        boxes: (json['boxes'] as List?)?.map((b) => BoxModel.fromJson(b)).toList(),
        circles: (json['circles'] as List?)?.map((c) => CircleItem.fromJson(c)).toList(),
      );
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<HomeSection> _homeSections = [];
  List<TrackItem> _playlist = [];
  List<TrackItem> _likedSongs = [];
  List<TrackItem> _downloads = [];
  List<TrackItem> _recents = [];

  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadDataLocally().then((_) {
      if (_homeSections.isEmpty) {
        _initDefaultSections();
      }
    });
    _initAudioListeners();
  }

  void _initDefaultSections() {
    _homeSections = [
      HomeSection(
        id: 'circle_line_1',
        type: HomeSectionType.circleLine,
        name: 'Favorite artists',
        circles: List.generate(6, (i) => CircleItem(name: 'Artist ${i + 1}', imageUrl: '')),
      ),
      HomeSection(
        id: 'box_line_1',
        type: HomeSectionType.boxLine,
        name: 'Line 1',
        boxes: List.generate(10, (i) => BoxModel(name: 'Box ${i + 1}', tracks: [])),
      ),
      HomeSection(
        id: 'box_line_2',
        type: HomeSectionType.boxLine,
        name: 'Line 2',
        boxes: List.generate(10, (i) => BoxModel(name: 'Hit Box ${i + 1}', tracks: [])),
      ),
      HomeSection(
        id: 'box_line_3',
        type: HomeSectionType.boxLine,
        name: 'Line 3',
        boxes: List.generate(10, (i) => BoxModel(name: 'Vibe Box ${i + 1}', tracks: [])),
      ),
      HomeSection(
        id: 'box_line_4',
        type: HomeSectionType.boxLine,
        name: 'Line 4',
        boxes: List.generate(10, (i) => BoxModel(name: 'Top Box ${i + 1}', tracks: [])),
      ),
    ];
    _saveDataLocally();
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_state.json');
  }

  Future<void> _saveDataLocally() async {
    try {
      final file = await _getLocalFile();
      final data = {
        'homeSections': _homeSections.map((s) => s.toJson()).toList(),
        'playlist': _playlist.map((t) => t.toJson()).toList(),
        'likedSongs': _likedSongs.map((t) => t.toJson()).toList(),
        'downloads': _downloads.map((t) => t.toJson()).toList(),
        'recents': _recents.map((t) => t.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadDataLocally() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        setState(() {
          _homeSections = (data['homeSections'] as List?)?.map((s) => HomeSection.fromJson(s)).toList() ?? [];
          _playlist = (data['playlist'] as List?)?.map((t) => TrackItem.fromJson(t)).toList() ?? [];
          _likedSongs = (data['likedSongs'] as List?)?.map((t) => TrackItem.fromJson(t)).toList() ?? [];
          _downloads = (data['downloads'] as List?)?.map((t) => TrackItem.fromJson(t)).toList() ?? [];
          _recents = (data['recents'] as List?)?.map((t) => TrackItem.fromJson(t)).toList() ?? [];
        });
      }
    } catch (_) {}
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
        const SnackBar(content: Text('Error playing track: Invalid URL')),
      );
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingTrack = track;
        _recents.removeWhere((t) => t.id == track.id);
        _recents.insert(0, track);
      });
      _saveDataLocally();

      await _audioPlayer.setUrl(track.url.trim());
      _audioPlayer.play();
      _openFullPlayerModal(track);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback Error: $e'), duration: const Duration(seconds: 4)),
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
    _saveDataLocally();
  }

  bool _isLiked(TrackItem track) => _likedSongs.any((item) => item.id == track.id);

  void _downloadTrack(TrackItem track) {
    if (!_downloads.any((t) => t.id == track.id)) {
      setState(() {
        track.isDownloaded = true;
        _downloads.add(track);
      });
      _saveDataLocally();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded "${track.title}" successfully')),
      );
    }
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
                    _saveDataLocally();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Playlist')));
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
              height: MediaQuery.of(context).size.height * 0.90,
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
                            track.artworkUrl != null && track.artworkUrl!.isNotEmpty
                                ? Image.network(track.artworkUrl!, fit: BoxFit.cover, width: double.infinity)
                                : const Center(child: Icon(Icons.music_note, size: 100, color: Colors.white24)),
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
                        icon: Icon(_isLiked(track) ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked(track) ? Colors.white : Colors.white54, size: 28),
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
                    value: _position.inSeconds.toDouble().clamp(
                          0.0,
                          _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                        ),
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}'),
                      Text('${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 64,
                        icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: Colors.blue, child: Text('G', style: TextStyle(color: Colors.white))),
                  const SizedBox(width: 12),
                  const Text('All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Music', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Podcasts', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Top 8 Small Shortcut Boxes Grid (2 rows x 4 columns)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 8,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF242424),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                color: Colors.primaries[index % Colors.primaries.length],
                                child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  index == 0 ? 'Liked Songs' : 'Shortcut ${index + 1}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Home Sections (Circular Carousels & Box Lines)
                  ..._homeSections.map((section) {
                    if (section.type == HomeSectionType.circleLine) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(section.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: section.circles?.length ?? 0,
                              itemBuilder: (context, cIndex) {
                                final circle = section.circles![cIndex];
                                return Container(
                                  width: 90,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.primaries[(cIndex + 3) % Colors.primaries.length],
                                        child: const Icon(Icons.person, size: 30, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        circle.name,
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(section.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: section.boxes?.length ?? 0,
                              itemBuilder: (context, bIndex) {
                                final box = section.boxes![bIndex];
                                return GestureDetector(
                                  onTap: () {
                                    if (box.tracks.isNotEmpty) {
                                      _playTrack(box.tracks.first);
                                    } else {
                                      _playTrack(TrackItem(
                                        id: 'box_${bIndex}_track',
                                        title: '${box.name} Audio',
                                        artist: section.name,
                                        url: 'https://archive.org/download/karol-g-judeline-rusowsky-bb-y-wow-visualizer-mp-3_202610/KAROL%20G%2C%20Judeline%2C%20rusowsky%20-%20BbY%20WOW%20%28Visualizer%29_MP3.mp3',
                                      ));
                                    }
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.primaries[(bIndex + 5) % Colors.primaries.length],
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.album, size: 40, color: Colors.white70),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            box.name,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _currentPlayingTrack == null
          ? null
          : Container(
              color: const Color(0xFF281C1C),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: 36, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentPlayingTrack!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                        Text(_currentPlayingTrack!.artist, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isLiked(_currentPlayingTrack!) ? Icons.favorite : Icons.favorite_border),
                    onPressed: () => _toggleLike(_currentPlayingTrack!),
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
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
            ),
    );
  }
}
