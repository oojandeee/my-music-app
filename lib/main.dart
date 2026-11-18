import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ============================================================================
// DATA MODELS
// ============================================================================

class TrackItem {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? artworkUrl;
  final String playsCount;
  final DateTime playedAt;
  bool isDownloaded;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
    this.playsCount = '12,480,910',
    DateTime? playedAt,
    this.isDownloaded = false,
  }) : playedAt = playedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'url': url,
        'artworkUrl': artworkUrl,
        'playsCount': playsCount,
        'playedAt': playedAt.toIso8601String(),
        'isDownloaded': isDownloaded,
      };

  factory TrackItem.fromJson(Map<String, dynamic> json) => TrackItem(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Unknown Title',
        artist: json['artist'] ?? 'Unknown Artist',
        url: json['url'] ?? '',
        artworkUrl: json['artworkUrl'],
        playsCount: json['playsCount'] ?? '12,480,910',
        playedAt: json['playedAt'] != null
            ? DateTime.parse(json['playedAt'])
            : DateTime.now(),
        isDownloaded: json['isDownloaded'] ?? false,
      );
}

class BoxModel {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final int colorValue;
  final List<TrackItem> tracks;

  BoxModel({
    required this.id,
    required this.name,
    this.subtitle = 'Playlist',
    this.description = 'The latest & grandest tracks curated for your vibe.',
    required this.colorValue,
    List<TrackItem>? tracks,
  }) : tracks = tracks ?? [];
}

class CircleItem {
  final String id;
  final String name;
  final String monthlyListeners;
  final int colorValue;
  final List<TrackItem> popularTracks;

  CircleItem({
    required this.id,
    required this.name,
    this.monthlyListeners = '893K monthly listeners',
    required this.colorValue,
    List<TrackItem>? popularTracks,
  }) : popularTracks = popularTracks ?? [];
}

class FeaturedVideoModel {
  final String id;
  final String bannerHeadline;
  final String title;
  final String channel;
  final String meta;
  final String durationLabel;
  final int colorValue;
  final TrackItem audioTrack;

  FeaturedVideoModel({
    required this.id,
    required this.bannerHeadline,
    required this.title,
    required this.channel,
    required this.meta,
    required this.durationLabel,
    required this.colorValue,
    required this.audioTrack,
  });
}

enum HomeSectionType { boxLine, circleLine, featuredVideo }

class HomeSection {
  final String id;
  final HomeSectionType type;
  final String title;
  final List<BoxModel>? boxes;
  final List<CircleItem>? circles;
  final FeaturedVideoModel? video;

  HomeSection({
    required this.id,
    required this.type,
    required this.title,
    this.boxes,
    this.circles,
    this.video,
  });
}

class AppSettings {
  String username;
  bool privateSession;
  bool publicPlaylists;
  bool gaplessPlayback;
  bool autoplay;
  bool pushNotifications;
  bool emailNotifications;
  bool dataSaverMode;
  bool downloadOverCellular;
  String streamingQuality;
  String downloadQuality;
  bool tailoredAds;

  AppSettings({
    this.username = 'Gurinderbir',
    this.privateSession = false,
    this.publicPlaylists = true,
    this.gaplessPlayback = true,
    this.autoplay = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.dataSaverMode = false,
    this.downloadOverCellular = false,
    this.streamingQuality = 'High',
    this.downloadQuality = 'Very High',
    this.tailoredAds = true,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'privateSession': privateSession,
        'publicPlaylists': publicPlaylists,
        'gaplessPlayback': gaplessPlayback,
        'autoplay': autoplay,
        'pushNotifications': pushNotifications,
        'emailNotifications': emailNotifications,
        'dataSaverMode': dataSaverMode,
        'downloadOverCellular': downloadOverCellular,
        'streamingQuality': streamingQuality,
        'downloadQuality': downloadQuality,
        'tailoredAds': tailoredAds,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        username: json['username'] ?? 'Gurinderbir',
        privateSession: json['privateSession'] ?? false,
        publicPlaylists: json['publicPlaylists'] ?? true,
        gaplessPlayback: json['gaplessPlayback'] ?? true,
        autoplay: json['autoplay'] ?? true,
        pushNotifications: json['pushNotifications'] ?? true,
        emailNotifications: json['emailNotifications'] ?? false,
        dataSaverMode: json['dataSaverMode'] ?? false,
        downloadOverCellular: json['downloadOverCellular'] ?? false,
        streamingQuality: json['streamingQuality'] ?? 'High',
        downloadQuality: json['downloadQuality'] ?? 'Very High',
        tailoredAds: json['tailoredAds'] ?? true,
      );
}

// ============================================================================
// APP ROOT
// ============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Stream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          surface: Color(0xFF181818),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  String _selectedCategoryFilter = 'All';
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Persistent State
  List<TrackItem> _playlist = [];
  List<TrackItem> _likedSongs = [];
  List<TrackItem> _downloads = [];
  List<TrackItem> _recents = [];
  Set<String> _followedArtists = {};
  Set<String> _savedBoxIds = {};
  AppSettings _settings = AppSettings();

  // Playback State
  TrackItem? _currentPlayingTrack;
  List<TrackItem> _currentQueue = [];
  bool _isPlaying = false;
  bool _isVideoMuted = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final List<BoxModel> _top8Shortcuts;
  late final List<HomeSection> _homeSections;

  static const String _sampleStreamUrl1 =
      'https://archive.org/download/karol-g-judeline-rusowsky-bb-y-wow-visualizer-mp-3_202610/KAROL%20G%2C%20Judeline%2C%20rusowsky%20-%20BbY%20WOW%20%28Visualizer%29_MP3.mp3';

  final List<int> _palette = const [
    0xFF1E3264,
    0xFF8D67AB,
    0xFFBA5D07,
    0xFFE8115B,
    0xFF148A08,
    0xFF503750,
    0xFF0D73EC,
    0xFF777777,
    0xFF477D95,
    0xFFAF2896,
  ];

  @override
  void initState() {
    super.initState();
    _buildCatalogData();
    _loadPersistentState();
    _initAudioListeners();
  }

  List<TrackItem> _generateSampleTracks(String prefix, String artistName) {
    final titles = [
      'BbY WOW',
      'ASTARR',
      'Street Fame',
      'Sift',
      'In and Out',
      'Lakehouse',
      'Priceless',
      'Kaim',
      'Caramel',
      'Threat 2.0',
    ];
    return List.generate(6, (i) {
      return TrackItem(
        id: '${prefix}_track_$i',
        title: '${titles[i % titles.length]} ($prefix)',
        artist: artistName,
        url: _sampleStreamUrl1,
        playsCount: '${(71 - i * 9)},${297 + i * 111},233',
      );
    });
  }

  void _buildCatalogData() {
    final shortcutNames = [
      'Liked Songs',
      'Punjabi Pop',
      'ASTARR Hits',
      'Iqbal Radio',
      'Archives',
      'Kaptaan',
      'Chill Mix',
      'Scars & Bars',
    ];

    _top8Shortcuts = List.generate(8, (i) {
      return BoxModel(
        id: 'shortcut_$i',
        name: shortcutNames[i],
        subtitle: i == 0 ? 'Auto Playlist' : 'Curated Mix',
        description: 'Quick access to ${shortcutNames[i]} and top tracks.',
        colorValue: _palette[i % _palette.length],
        tracks: _generateSampleTracks(shortcutNames[i], 'Various Artists'),
      );
    });

    _homeSections = [];
    final lineTitles = [
      'Jump back in',
      'Recommended for today',
      'Your top mixes',
      'Popular radio',
      'Trending now',
      'Punjabi hits',
      'Fresh finds',
      'Late night vibes',
      'Workout energy',
      'Throwback classics',
      'Editors picks',
      'Top charts',
    ];
    final artistNames = [
      'Bhalwaan',
      'Saabi Bhinder',
      'Jass Bajwa',
      'Prem Dhillon',
      'Arijit Singh',
      'Diljit Dosanjh',
      'Cheema Y',
      'Arjan Dhillon',
      'Amrinder Gill',
      'Shubh',
      'Navaan Sandhu',
      'KAROL G',
    ];

    int boxLineCounter = 0;
    int circleLineCounter = 0;

    // Repeat sequence 3 full cycles:
    // (4 horizontal box lines x 10 boxes) -> (1 horizontal circle line x 6 circles) -> (1-2 long video boxes)
    for (int cycle = 0; cycle < 3; cycle++) {
      // 4 square box lines with 10 boxes each
      for (int l = 0; l < 4; l++) {
        final lineTitle = lineTitles[boxLineCounter % lineTitles.length];
        final currentLineIdx = boxLineCounter;
        _homeSections.add(
          HomeSection(
            id: 'box_line_${cycle}_$l',
            type: HomeSectionType.boxLine,
            title: lineTitle,
            boxes: List.generate(10, (b) {
              final boxName = '$lineTitle #${b + 1}';
              final artist = artistNames[(currentLineIdx + b) % artistNames.length];
              return BoxModel(
                id: 'box_${cycle}_${l}_$b',
                name: boxName,
                subtitle: b % 2 == 0 ? 'Album • $artist' : 'Playlist',
                description:
                    'The latest & grandest in $lineTitle. Cover: $artist',
                colorValue: _palette[(currentLineIdx + b) % _palette.length],
                tracks: _generateSampleTracks(boxName, artist),
              );
            }),
          ),
        );
        boxLineCounter++;
      }

      // 1 circular line with 6 circles
      final cIdx = circleLineCounter;
      _homeSections.add(
        HomeSection(
          id: 'circle_line_$cycle',
          type: HomeSectionType.circleLine,
          title: cycle == 0
              ? 'Your favorite artists'
              : 'Suggested artists ${cycle + 1}',
          circles: List.generate(6, (c) {
            final name = artistNames[(cIdx * 6 + c) % artistNames.length];
            return CircleItem(
              id: 'artist_${cycle}_$c',
              name: name,
              monthlyListeners: '${893 - c * 45}K monthly listeners',
              colorValue: _palette[(c + cycle + 2) % _palette.length],
              popularTracks: _generateSampleTracks(name, name),
            );
          }),
        ),
      );
      circleLineCounter++;

      // 1-2 YouTube-style long video / episode cards in the sequence
      _homeSections.add(
        HomeSection(
          id: 'featured_video_${cycle}_1',
          type: HomeSectionType.featuredVideo,
          title: 'Featured Episode',
          video: FeaturedVideoModel(
            id: 'vid_${cycle}_1',
            bannerHeadline: cycle == 0
                ? 'Do It Anyway'
                : (cycle == 1 ? 'Studio Sessions' : 'Behind The Beats'),
            title: cycle == 0
                ? 'How to Trick Your Brain Into Liking Discipline'
                : 'Deep Focus & Late Night Music Production Breakdown',
            channel: 'Psyphoria',
            meta: 'Oct 21 • 100K+ plays',
            durationLabel: '27:11',
            colorValue: cycle == 0 ? 0xFFB81D13 : 0xFF1B4D3E,
            audioTrack: TrackItem(
              id: 'vid_track_${cycle}_1',
              title: cycle == 0
                  ? 'How to Trick Your Brain Into Liking Discipline'
                  : 'Studio Sessions Full Audio',
              artist: 'Psyphoria',
              url: _sampleStreamUrl1,
            ),
          ),
        ),
      );

      if (cycle == 1) {
        _homeSections.add(
          HomeSection(
            id: 'featured_video_${cycle}_2',
            type: HomeSectionType.featuredVideo,
            title: 'Trending Video Podcast',
            video: FeaturedVideoModel(
              id: 'vid_${cycle}_2',
              bannerHeadline: 'Unfiltered Talks',
              title: 'The Evolution of Modern Punjabi & Global Pop Sound',
              channel: 'Music Insider',
              meta: 'Nov 12 • 240K+ plays',
              durationLabel: '42:05',
              colorValue: 0xFF283593,
              audioTrack: TrackItem(
                id: 'vid_track_${cycle}_2',
                title: 'The Evolution of Modern Punjabi & Global Pop Sound',
                artist: 'Music Insider',
                url: _sampleStreamUrl1,
              ),
            ),
          ),
        );
      }
    }
  }

  // ==========================================================================
  // LOCAL PERSISTENCE
  // ==========================================================================

  Future<File> _getStateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/music_app_persistent_v2.json');
  }

  Future<void> _savePersistentState() async {
    try {
      final file = await _getStateFile();
      final payload = {
        'playlist': _playlist.map((t) => t.toJson()).toList(),
        'likedSongs': _likedSongs.map((t) => t.toJson()).toList(),
        'downloads': _downloads.map((t) => t.toJson()).toList(),
        'recents': _recents.map((t) => t.toJson()).toList(),
        'followedArtists': _followedArtists.toList(),
        'savedBoxIds': _savedBoxIds.toList(),
        'settings': _settings.toJson(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> _loadPersistentState() async {
    try {
      final file = await _getStateFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _playlist = (data['playlist'] as List?)
                  ?.map((e) => TrackItem.fromJson(e))
                  .toList() ??
              [];
          _likedSongs = (data['likedSongs'] as List?)
                  ?.map((e) => TrackItem.fromJson(e))
                  .toList() ??
              [];
          _downloads = (data['downloads'] as List?)
                  ?.map((e) => TrackItem.fromJson(e))
                  .toList() ??
              [];
          _recents = (data['recents'] as List?)
                  ?.map((e) => TrackItem.fromJson(e))
                  .toList() ??
              [];
          _followedArtists =
              Set<String>.from(data['followedArtists'] ?? const []);
          _savedBoxIds = Set<String>.from(data['savedBoxIds'] ?? const []);
          if (data['settings'] != null) {
            _settings = AppSettings.fromJson(data['settings']);
          }
        });
      }
    } catch (_) {}
  }

  // ==========================================================================
  // AUDIO PLAYBACK & ACTIONS
  // ==========================================================================

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
      if (state.processingState == ProcessingState.completed &&
          _settings.autoplay) {
        _playNextInQueue();
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
    super.dispose();
  }

  Future<void> _playTrack(TrackItem track,
      {List<TrackItem>? queue, bool openModal = true}) async {
    if (track.url.trim().isEmpty || !track.url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid audio stream URL')),
      );
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingTrack = track;
        if (queue != null && queue.isNotEmpty) {
          _currentQueue = List.from(queue);
        }
        // Respect Private Session setting: do not record recents when private session is ON
        if (!_settings.privateSession) {
          _recents.removeWhere((t) => t.id == track.id);
          _recents.insert(0, track);
          if (_recents.length > 50) {
            _recents = _recents.sublist(0, 50);
          }
        }
      });
      await _savePersistentState();

      await _audioPlayer.setUrl(track.url.trim());
      _audioPlayer.play();
      if (openModal && mounted) {
        _openFullPlayerModal(track);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
    }
  }

  void _playNextInQueue() {
    if (_currentPlayingTrack == null || _currentQueue.isEmpty) return;
    final idx =
        _currentQueue.indexWhere((t) => t.id == _currentPlayingTrack!.id);
    if (idx != -1 && idx + 1 < _currentQueue.length) {
      _playTrack(_currentQueue[idx + 1], openModal: false);
    }
  }

  void _playPreviousInQueue() {
    if (_currentPlayingTrack == null || _currentQueue.isEmpty) return;
    final idx =
        _currentQueue.indexWhere((t) => t.id == _currentPlayingTrack!.id);
    if (idx > 0) {
      _playTrack(_currentQueue[idx - 1], openModal: false);
    } else {
      _audioPlayer.seek(Duration.zero);
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
    _savePersistentState();
  }

  bool _isLiked(TrackItem track) =>
      _likedSongs.any((item) => item.id == track.id);

  void _downloadTrack(TrackItem track) {
    if (_settings.dataSaverMode && !_settings.downloadOverCellular) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Data Saver is ON. Enable "Downloads over cellular" in Settings to download.'),
        ),
      );
      return;
    }
    if (!_downloads.any((t) => t.id == track.id)) {
      setState(() {
        track.isDownloaded = true;
        _downloads.add(track);
      });
      _savePersistentState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Downloaded "${track.title}" (${_settings.downloadQuality})')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already downloaded')),
      );
    }
  }

  void _addToPlaylist(TrackItem track) {
    if (!_playlist.any((t) => t.id == track.id)) {
      setState(() => _playlist.add(track));
      _savePersistentState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${track.title}" to Your Playlist')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track already in Your Playlist')),
      );
    }
  }

  void _toggleFollowArtist(String artistId) {
    setState(() {
      if (_followedArtists.contains(artistId)) {
        _followedArtists.remove(artistId);
      } else {
        _followedArtists.add(artistId);
      }
    });
    _savePersistentState();
  }

  void _toggleSaveBox(String boxId) {
    setState(() {
      if (_savedBoxIds.contains(boxId)) {
        _savedBoxIds.remove(boxId);
      } else {
        _savedBoxIds.add(boxId);
      }
    });
    _savePersistentState();
  }

  // ==========================================================================
  // MODALS & DETAIL PAGES (BOX, CIRCLE, SETTINGS, RECENTS, PLAYER)
  // ==========================================================================

  void _openBoxDetailScreen(BoxModel box) {
    final tracksToDisplay =
        box.id == 'shortcut_0' && _likedSongs.isNotEmpty ? _likedSongs : box.tracks;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setPageState) {
            final isSaved = _savedBoxIds.contains(box.id);
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: Color(box.colorValue),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          if (tracksToDisplay.isNotEmpty) {
                            _openTrack3DotsMenu(tracksToDisplay.first);
                          }
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(box.colorValue),
                              const Color(0xFF121212),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Hero(
                            tag: 'box_${box.id}',
                            child: Container(
                              width: 170,
                              height: 170,
                              margin: const EdgeInsets.only(top: 32),
                              decoration: BoxDecoration(
                                color: Color(box.colorValue),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.album,
                                      size: 64, color: Colors.white),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      box.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            box.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            box.description,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.graphic_eq,
                                  color: Color(0xFF1DB954), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Made for ${_settings.username} • ${tracksToDisplay.length} songs',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: isSaved
                                      ? const Color(0xFF1DB954)
                                      : Colors.white70,
                                  size: 28,
                                ),
                                onPressed: () {
                                  _toggleSaveBox(box.id);
                                  setPageState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.arrow_circle_down_outlined,
                                    color: Colors.white70,
                                    size: 28),
                                onPressed: () {
                                  for (final t in tracksToDisplay) {
                                    _downloadTrack(t);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined,
                                    color: Colors.white70, size: 26),
                                onPressed: () {
                                  Share.share(
                                      'Listen to ${box.name} on Music Stream!');
                                },
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.shuffle,
                                    color: Color(0xFF1DB954), size: 28),
                                onPressed: () {
                                  if (tracksToDisplay.isNotEmpty) {
                                    final shuffled =
                                        List<TrackItem>.from(tracksToDisplay)
                                          ..shuffle();
                                    _playTrack(shuffled.first,
                                        queue: shuffled, openModal: true);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (tracksToDisplay.isNotEmpty) {
                                    _playTrack(tracksToDisplay.first,
                                        queue: tracksToDisplay,
                                        openModal: true);
                                  }
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1DB954),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      color: Colors.black, size: 32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracksToDisplay[index];
                        final liked = _isLiked(track);
                        return ListTile(
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Color(box.colorValue).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _currentPlayingTrack?.id == track.id
                                  ? const Color(0xFF1DB954)
                                  : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artist,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  liked
                                      ? Icons.check_circle
                                      : Icons.favorite_border,
                                  color: liked
                                      ? const Color(0xFF1DB954)
                                      : Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _toggleLike(track);
                                  setPageState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white60),
                                onPressed: () => _openTrack3DotsMenu(track),
                              ),
                            ],
                          ),
                          onTap: () => _playTrack(track,
                              queue: tracksToDisplay, openModal: true),
                        );
                      },
                      childCount: tracksToDisplay.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCircleArtistScreen(CircleItem artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setPageState) {
            final isFollowing = _followedArtists.contains(artist.id);
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 270,
                    pinned: true,
                    backgroundColor: Color(artist.colorValue),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          Share.share(
                              'Check out ${artist.name} on Music Stream!');
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        artist.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(artist.colorValue),
                                  const Color(0xFF121212),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Hero(
                                tag: 'circle_${artist.id}',
                                child: CircleAvatar(
                                  radius: 65,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.15),
                                  child: const Icon(Icons.person,
                                      size: 72, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified,
                                  color: Colors.lightBlueAccent, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Verified Artist',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            artist.monthlyListeners,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: isFollowing
                                        ? const Color(0xFF1DB954)
                                        : Colors.white54,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  _toggleFollowArtist(artist.id);
                                  setPageState(() {});
                                },
                                child: Text(
                                    isFollowing ? 'Following' : 'Follow'),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.shuffle,
                                    color: Color(0xFF1DB954), size: 28),
                                onPressed: () {
                                  if (artist.popularTracks.isNotEmpty) {
                                    final shuffled = List<TrackItem>.from(
                                        artist.popularTracks)
                                      ..shuffle();
                                    _playTrack(shuffled.first,
                                        queue: shuffled, openModal: true);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (artist.popularTracks.isNotEmpty) {
                                    _playTrack(artist.popularTracks.first,
                                        queue: artist.popularTracks,
                                        openModal: true);
                                  }
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1DB954),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      color: Colors.black, size: 32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Popular',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = artist.popularTracks[index];
                        final liked = _isLiked(track);
                        return ListTile(
                          leading: SizedBox(
                            width: 68,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(artist.colorValue)
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.music_note,
                                      size: 20, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _currentPlayingTrack?.id == track.id
                                  ? const Color(0xFF1DB954)
                                  : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.playsCount,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  liked
                                      ? Icons.check_circle
                                      : Icons.favorite_border,
                                  color: liked
                                      ? const Color(0xFF1DB954)
                                      : Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _toggleLike(track);
                                  setPageState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white60),
                                onPressed: () => _openTrack3DotsMenu(track),
                              ),
                            ],
                          ),
                          onTap: () => _playTrack(track,
                              queue: artist.popularTracks, openModal: true),
                        );
                      },
                      childCount: artist.popularTracks.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRecentsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setPageState) {
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor: const Color(0xFF121212),
                title: const Text('Recents'),
                actions: [
                  if (_recents.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _recents.clear());
                        _savePersistentState();
                        setPageState(() {});
                      },
                      child: const Text('Clear',
                          style: TextStyle(color: Color(0xFF1DB954))),
                    ),
                ],
              ),
              body: _recents.isEmpty
                  ? const Center(
                      child: Text(
                        'No recently played songs yet.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _recents.length,
                      itemBuilder: (context, index) {
                        final track = _recents[index];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF282828),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.history,
                                color: Colors.white70),
                          ),
                          title: Text(track.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(track.artist,
                              style: const TextStyle(color: Colors.white60)),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _openTrack3DotsMenu(track),
                          ),
                          onTap: () => _playTrack(track,
                              queue: _recents, openModal: true),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  void _openSettingsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSettingsState) {
            void updateSetting(VoidCallback fn) {
              setState(fn);
              setSettingsState(() {});
              _savePersistentState();
            }

            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor: const Color(0xFF121212),
                title: const Text('Settings'),
              ),
              body: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Top Quick Toggles (Data saver mode | Private session)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => updateSetting(() =>
                                _settings.dataSaverMode =
                                    !_settings.dataSaverMode),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF242424),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('Data saver mode',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _settings.dataSaverMode ? 'On' : 'Automatic',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _settings.dataSaverMode
                                          ? const Color(0xFF1DB954)
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => updateSetting(() =>
                                _settings.privateSession =
                                    !_settings.privateSession),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF242424),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('Private session',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _settings.privateSession ? 'On' : 'Off',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _settings.privateSession
                                          ? const Color(0xFF1DB954)
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. Account
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined, size: 28),
                    title: const Text('Account',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_settings.username} • Edit profile'),
                    onTap: () {
                      final ctrl =
                          TextEditingController(text: _settings.username);
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: const Color(0xFF242424),
                          title: const Text('Edit Username'),
                          content: TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(
                                hintText: 'Enter username'),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                if (ctrl.text.trim().isNotEmpty) {
                                  updateSetting(() =>
                                      _settings.username = ctrl.text.trim());
                                }
                                Navigator.pop(dCtx);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 2. Content and display
                  ListTile(
                    leading: const Icon(Icons.music_note_outlined, size: 28),
                    title: const Text('Content and display',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Category filter • Language preferences'),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1E1E1E),
                        builder: (bCtx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ['All', 'Music', 'Podcasts', 'Audiobooks']
                              .map((cat) => ListTile(
                                    title: Text(cat),
                                    trailing: _selectedCategoryFilter == cat
                                        ? const Icon(Icons.check,
                                            color: Color(0xFF1DB954))
                                        : null,
                                    onTap: () {
                                      updateSetting(
                                          () => _selectedCategoryFilter = cat);
                                      Navigator.pop(bCtx);
                                    },
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),

                  // 3. Privacy and social
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline, size: 28),
                    title: const Text('Privacy and social',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Private session (pauses Recents history) & Public playlists'),
                    value: _settings.privateSession,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) =>
                        updateSetting(() => _settings.privateSession = val),
                  ),

                  // 4. Playback
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined, size: 28),
                    title: const Text('Playback',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Gapless playback • Autoplay'),
                    value: _settings.autoplay,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) =>
                        updateSetting(() => _settings.autoplay = val),
                  ),

                  // 5. Notifications
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.notifications_outlined, size: 28),
                    title: const Text('Notifications',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Push • Email alerts'),
                    value: _settings.pushNotifications,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) =>
                        updateSetting(() => _settings.pushNotifications = val),
                  ),

                  // 6. Apps and devices
                  ListTile(
                    leading: const Icon(Icons.speaker_group_outlined, size: 28),
                    title: const Text('Apps and devices',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Connected devices • ${_downloads.length} offline tracks'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Active Device: This Android Phone'),
                        ),
                      );
                    },
                  ),

                  // 7. Data-saving and offline
                  SwitchListTile(
                    secondary:
                        const Icon(Icons.arrow_circle_down_outlined, size: 28),
                    title: const Text('Data-saving and offline',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Downloads over cellular'),
                    value: _settings.downloadOverCellular,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) => updateSetting(
                        () => _settings.downloadOverCellular = val),
                  ),

                  // 8. Media quality
                  ListTile(
                    leading: const Icon(Icons.equalizer, size: 28),
                    title: const Text('Media quality',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Wi-Fi: ${_settings.streamingQuality} • Download: ${_settings.downloadQuality}'),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1E1E1E),
                        builder: (bCtx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ['Low', 'Normal', 'High', 'Very High']
                              .map((q) => ListTile(
                                    title: Text('$q Quality'),
                                    trailing: _settings.streamingQuality == q
                                        ? const Icon(Icons.check,
                                            color: Color(0xFF1DB954))
                                        : null,
                                    onTap: () {
                                      updateSetting(() {
                                        _settings.streamingQuality = q;
                                        _settings.downloadQuality = q;
                                      });
                                      Navigator.pop(bCtx);
                                    },
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),

                  // 9. Advertising
                  SwitchListTile(
                    secondary: const Icon(Icons.featured_play_list_outlined,
                        size: 28),
                    title: const Text('Advertising',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Tailored ads & recommendations'),
                    value: _settings.tailoredAds,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) =>
                        updateSetting(() => _settings.tailoredAds = val),
                  ),

                  // 10. About and support / Reset Data
                  ListTile(
                    leading: const Icon(Icons.info_outline, size: 28),
                    title: const Text('About and support',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Version 1.0.0 • Clear local cache'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: const Color(0xFF242424),
                          title: const Text('Clear Recents Cache?'),
                          content: const Text(
                              'This will clear your recently played list while keeping your liked songs and playlists.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                updateSetting(() => _recents.clear());
                                Navigator.pop(dCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Recents cache cleared')),
                                );
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openTrack3DotsMenu(TrackItem track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.music_note, size: 36, color: Colors.white),
                title: Text(track.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(track.artist),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (track.url.isNotEmpty) {
                    Share.share(
                        'Check out this song: ${track.title}\n${track.url}');
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  _isLiked(track) ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked(track) ? const Color(0xFF1DB954) : Colors.white,
                ),
                title: Text(_isLiked(track)
                    ? 'Remove from Liked Songs'
                    : 'Add to Liked Songs'),
                onTap: () {
                  _toggleLike(track);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadTrack(track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Your Playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addToPlaylist(track);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullPlayerModal(TrackItem track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeTrack = _currentPlayingTrack ?? track;
            final maxDur = _duration.inSeconds.toDouble() > 0
                ? _duration.inSeconds.toDouble()
                : 1.0;
            final curPos = _position.inSeconds.toDouble().clamp(0.0, maxDur);

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
                      Text(
                        activeTrack.artist.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _openTrack3DotsMenu(activeTrack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.all(_isPlaying ? 0 : 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black54,
                              blurRadius: 24,
                              offset: Offset(0, 12)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.music_note,
                              size: 110, color: Colors.white24),
                          if (_isPlaying)
                            Positioned(
                              bottom: 20,
                              child: Row(
                                children: List.generate(
                                  5,
                                  (i) => AnimatedContainer(
                                    duration:
                                        Duration(milliseconds: 250 + i * 70),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: 4,
                                    height: 14.0 + (i % 3) * 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1DB954),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeTrack.title,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeTrack.artist,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isLiked(activeTrack)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isLiked(activeTrack)
                              ? const Color(0xFF1DB954)
                              : Colors.white70,
                          size: 28,
                        ),
                        onPressed: () {
                          _toggleLike(activeTrack);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    min: 0.0,
                    max: maxDur,
                    value: curPos,
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}'),
                      Text(
                          '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white),
                        onPressed: () {
                          _playPreviousInQueue();
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        iconSize: 68,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
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
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () {
                          _playNextInQueue();
                          setModalState(() {});
                        },
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

  // ==========================================================================
  // HOME & PLAYLIST TABS
  // ==========================================================================

  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top Header Bar with Profile Avatar, Category Chips, Recents & Settings
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openSettingsScreen,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF4285F4),
                    child: Text(
                      _settings.username.isNotEmpty
                          ? _settings.username[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Music', 'Podcasts'].map((cat) {
                        final selected = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: selected,
                            selectedColor: const Color(0xFF1DB954),
                            backgroundColor: const Color(0xFF282828),
                            labelStyle: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCategoryFilter = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Recents',
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: _openRecentsScreen,
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: _openSettingsScreen,
                ),
              ],
            ),
          ),
        ),

        // 8 Compact Shortcut Boxes at Top (2 columns x 4 rows)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final shortcut = _top8Shortcuts[index];
                return _AnimatedPressCard(
                  onTap: () => _openBoxDetailScreen(shortcut),
                  child: Hero(
                    tag: 'box_${shortcut.id}',
                    child: Material(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(6),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: double.infinity,
                            color: Color(shortcut.colorValue),
                            child: Icon(
                              index == 0 ? Icons.favorite : Icons.music_note,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shortcut.name,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: _top8Shortcuts.length,
            ),
          ),
        ),

        // Repeating Sequence: 4 Box Lines (10 boxes each) + 1 Circle Line (6 circles) + Long Video Card
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final section = _homeSections[index];
              if (section.type == HomeSectionType.boxLine) {
                return _buildHorizontalBoxLine(section);
              } else if (section.type == HomeSectionType.circleLine) {
                return _buildHorizontalCircleLine(section);
              } else {
                return _buildFeaturedVideoCard(section.video!);
              }
            },
            childCount: _homeSections.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }

  Widget _buildHorizontalBoxLine(HomeSection section) {
    final boxes = section.boxes ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
          child: Text(
            section.title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: boxes.length,
            itemBuilder: (context, idx) {
              final box = boxes[idx];
              return _AnimatedPressCard(
                onTap: () => _openBoxDetailScreen(box),
                child: Container(
                  width: 136,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'box_${box.id}',
                        child: Container(
                          height: 136,
                          width: 136,
                          decoration: BoxDecoration(
                            color: Color(box.colorValue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(Icons.album,
                                    size: 52, color: Colors.white70),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        box.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        box.subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildHorizontalCircleLine(HomeSection section) {
    final circles = section.circles ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
          child: Text(
            section.title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: circles.length,
            itemBuilder: (context, idx) {
              final artist = circles[idx];
              return _AnimatedPressCard(
                onTap: () => _openCircleArtistScreen(artist),
                child: Container(
                  width: 124,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'circle_${artist.id}',
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Color(artist.colorValue),
                          child: const Icon(Icons.person,
                              size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildFeaturedVideoCard(FeaturedVideoModel video) {
    final isSaved = _isLiked(video.audioTrack);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 6),
      child: _AnimatedPressCard(
        onTap: () => _playTrack(video.audioTrack, openModal: true),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wide 16:9 YouTube/Spotify-style Video Banner
              Container(
                height: 195,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(video.colorValue),
                      Colors.black87,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          video.bannerHeadline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    // Duration badge top-left (27:11)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.durationLabel,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Right-side vertical controls (+, mute, play)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleLike(video.audioTrack),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved ? Icons.check : Icons.add,
                                color: isSaved
                                    ? const Color(0xFF1DB954)
                                    : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isVideoMuted = !_isVideoMuted);
                              _audioPlayer.setVolume(_isVideoMuted ? 0.5 : 1.0);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isVideoMuted
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow,
                                color: Colors.black, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom metadata row
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(video.colorValue),
                  child: const Icon(Icons.podcasts, color: Colors.white),
                ),
                title: Text(
                  video.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${video.channel} • ${video.meta}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () => _openTrack3DotsMenu(video.audioTrack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistLibraryTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: const Text('Your Playlist & Library',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _openRecentsScreen,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettingsScreen,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF1DB954),
            tabs: [
              Tab(text: 'My Playlist'),
              Tab(text: 'Liked Songs'),
              Tab(text: 'Downloads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTrackListSection(
              tracks: _playlist,
              emptyMessage:
                  'Your Playlist is empty. Tap the 3 dots on any song to add it here.',
              onRemove: (track) {
                setState(() => _playlist.removeWhere((t) => t.id == track.id));
                _savePersistentState();
              },
            ),
            _buildTrackListSection(
              tracks: _likedSongs,
              emptyMessage: 'No Liked Songs yet.',
              onRemove: (track) => _toggleLike(track),
            ),
            _buildTrackListSection(
              tracks: _downloads,
              emptyMessage: 'No Downloaded Songs yet.',
              onRemove: (track) {
                setState(() => _downloads.removeWhere((t) => t.id == track.id));
                _savePersistentState();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackListSection({
    required List<TrackItem> tracks,
    required String emptyMessage,
    required Function(TrackItem) onRemove,
  }) {
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 110, top: 8),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(track.artist,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: () => onRemove(track),
          ),
          onTap: () => _playTrack(track, queue: tracks, openModal: true),
        );
      },
    );
  }

  // ==========================================================================
  // BUILD SCAFFOLD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _currentTabIndex == 0
              ? KeyedSubtree(key: const ValueKey(0), child: _buildHomeTab())
              : KeyedSubtree(
                  key: const ValueKey(1), child: _buildPlaylistLibraryTab()),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Mini Player
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentPlayingTrack == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    key: ValueKey(_currentPlayingTrack!.id),
                    onTap: () => _openFullPlayerModal(_currentPlayingTrack!),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPlayingTrack!.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _currentPlayingTrack!.artist,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isLiked(_currentPlayingTrack!)
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: _isLiked(_currentPlayingTrack!)
                                  ? const Color(0xFF1DB954)
                                  : Colors.white,
                            ),
                            onPressed: () =>
                                _toggleLike(_currentPlayingTrack!),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
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
                    ),
                  ),
          ),
          // Clean 2-Tab Bottom Bar (Home & Your Playlist - Search removed)
          BottomNavigationBar(
            currentIndex: _currentTabIndex,
            backgroundColor: const Color(0xFF121212),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            onTap: (idx) => setState(() => _currentTabIndex = idx),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Your Playlist',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMOOTH SPRING SCALE ANIMATION WRAPPER FOR BOXES & CIRCLES
// ============================================================================

class _AnimatedPressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedPressCard({required this.child, required this.onTap});

  @override
  State<_AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<_AnimatedPressCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
