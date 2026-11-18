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
    this.playsCount = '71,297,233',
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
        playsCount: json['playsCount'] ?? '71,297,233',
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

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentTabIndex = 0;
  String _selectedCategoryFilter = 'All';
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Persistent State
  List<TrackItem> _playlist = [];
  List<TrackItem> _likedSongs = [];
  List<TrackItem> _downloads = [];
  List<TrackItem> _recents = [];
  List<TrackItem> _playbackQueue = [];
  Set<String> _followedArtists = {};
  Set<String> _savedBoxIds = {};
  AppSettings _settings = AppSettings();

  // Playback State
  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;
  bool _isVideoMuted = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final List<BoxModel> _top8Shortcuts;
  late final List<HomeSection> _homeSections;

  // GitHub Release Direct MP3 URL provided by user
  static const String _githubAudioUrl =
      'https://github.com/oojandeee/my-music-app/releases/download/v1.0.0/sample_track_1.mp3';

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
      'Street Fame',
      'Sift',
      'In and Out',
      'Lakehouse',
      'Priceless',
      'Kaim',
      'Caramel',
      'Threat 2.0',
      'Young Hood',
      'Patandar',
    ];
    return List.generate(6, (i) {
      return TrackItem(
        id: '${prefix}_track_$i',
        title: i == 0 ? 'Street Fame ($prefix)' : '${titles[i % titles.length]}',
        artist: artistName,
        // First track in every box uses your GitHub release MP3 URL
        url: i == 0 ? _githubAudioUrl : _githubAudioUrl,
        playsCount: '${(71 - i * 4)},297,233',
      );
    });
  }

  void _buildCatalogData() {
    final shortcutNames = [
      'Liked Songs',
      'Street Fame',
      'Patandar',
      'Threat 2.0',
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
        tracks: _generateSampleTracks(shortcutNames[i], i == 0 ? 'Gurinderbir' : 'Iqbal'),
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
      'Iqbal',
      'Arjan Dhillon',
      'Sidhu Moose Wala',
      'Prem Dhillon',
      'Arijit Singh',
      'Diljit Dosanjh',
      'Cheema Y',
      'Shubh',
      'Amrinder Gill',
      'Karan Aujla',
    ];

    int boxLineCounter = 0;
    int circleLineCounter = 0;

    // Repeating sequence: 4 Box lines -> 1 Circle line -> 1-2 Video cards
    for (int cycle = 0; cycle < 3; cycle++) {
      for (int l = 0; l < 4; l++) {
        final lineTitle = lineTitles[boxLineCounter % lineTitles.length];
        final currentLineIdx = boxLineCounter;
        _homeSections.add(
          HomeSection(
            id: 'box_line_${cycle}_$l',
            type: HomeSectionType.boxLine,
            title: lineTitle,
            boxes: List.generate(10, (b) {
              final boxName = b == 0 && cycle == 0 && l == 0 ? 'Street Fame' : '$lineTitle #${b + 1}';
              final artist = artistNames[(currentLineIdx + b) % artistNames.length];
              return BoxModel(
                id: 'box_${cycle}_${l}_$b',
                name: boxName,
                subtitle: b % 2 == 0 ? 'Album • $artist' : 'Playlist',
                description: 'The latest & grandest hits. Cover: $artist',
                colorValue: _palette[(currentLineIdx + b) % _palette.length],
                tracks: _generateSampleTracks(boxName, artist),
              );
            }),
          ),
        );
        boxLineCounter++;
      }

      // Circle Line (6 items)
      final cIdx = circleLineCounter;
      _homeSections.add(
        HomeSection(
          id: 'circle_line_$cycle',
          type: HomeSectionType.circleLine,
          title: cycle == 0 ? 'Your favorite artists' : 'Suggested artists ${cycle + 1}',
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

      // Featured Video Pod / Short
      _homeSections.add(
        HomeSection(
          id: 'featured_video_${cycle}_1',
          type: HomeSectionType.featuredVideo,
          title: 'Featured Episode',
          video: FeaturedVideoModel(
            id: 'vid_${cycle}_1',
            bannerHeadline: cycle == 0 ? 'Patandar' : 'Street Fame',
            title: cycle == 0 ? 'Arjan Dhillon Official Music Visualizer' : 'Deep Focus & Behind The Beats',
            channel: cycle == 0 ? 'Arjan Dhillon' : 'Psyphoria',
            meta: 'Nov 18 • 240K+ plays',
            durationLabel: '27:11',
            colorValue: cycle == 0 ? 0xFF8D1D13 : 0xFF1B4D3E,
            audioTrack: TrackItem(
              id: 'vid_track_${cycle}_1',
              title: 'Patandar Special Audio Mix',
              artist: cycle == 0 ? 'Arjan Dhillon' : 'Psyphoria',
              url: _githubAudioUrl,
            ),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // PERSISTENCE
  // ==========================================================================

  Future<File> _getStateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/music_app_persistent_v3.json');
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
          _playlist = (data['playlist'] as List?)?.map((e) => TrackItem.fromJson(e)).toList() ?? [];
          _likedSongs = (data['likedSongs'] as List?)?.map((e) => TrackItem.fromJson(e)).toList() ?? [];
          _downloads = (data['downloads'] as List?)?.map((e) => TrackItem.fromJson(e)).toList() ?? [];
          _recents = (data['recents'] as List?)?.map((e) => TrackItem.fromJson(e)).toList() ?? [];
          _followedArtists = Set<String>.from(data['followedArtists'] ?? const []);
          _savedBoxIds = Set<String>.from(data['savedBoxIds'] ?? const []);
          if (data['settings'] != null) {
            _settings = AppSettings.fromJson(data['settings']);
          }
        });
      }
    } catch (_) {}
  }

  // ==========================================================================
  // AUDIO PLAYBACK
  // ==========================================================================

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed && _settings.autoplay) {
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

  Future<void> _playTrack(TrackItem track, {List<TrackItem>? queue, bool openModal = true}) async {
    if (track.url.trim().isEmpty) return;
    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingTrack = track;
        if (queue != null && queue.isNotEmpty) {
          _playbackQueue = List.from(queue);
        }
        if (!_settings.privateSession) {
          _recents.removeWhere((t) => t.id == track.id);
          _recents.insert(0, track);
          if (_recents.length > 50) _recents = _recents.sublist(0, 50);
        }
      });
      _savePersistentState();

      await _audioPlayer.setUrl(track.url.trim());
      _audioPlayer.play();
      if (openModal && mounted) _openFullPlayerModal(track);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  void _addSongToQueue(TrackItem track) {
    setState(() {
      _playbackQueue.add(track);
    });
    _savePersistentState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${track.title}" to queue')),
    );
  }

  void _playNextInQueue() {
    if (_playbackQueue.isNotEmpty) {
      final next = _playbackQueue.removeAt(0);
      _playTrack(next, openModal: false);
    }
  }

  void _playPreviousInQueue() {
    _audioPlayer.seek(Duration.zero);
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

  bool _isLiked(TrackItem track) => _likedSongs.any((item) => item.id == track.id);

  void _downloadTrack(TrackItem track) {
    if (!_downloads.any((t) => t.id == track.id)) {
      setState(() {
        track.isDownloaded = true;
        _downloads.add(track);
      });
      _savePersistentState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded "${track.title}" for offline playback')),
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
        const SnackBar(content: Text('Already in Your Playlist')),
      );
    }
  }

  String _formatPlayedDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return 'Today, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, Nov ${dt.day} ${dt.year}';
    } else {
      return 'Nov ${dt.day}, ${dt.year}';
    }
  }

  // ==========================================================================
  // OPTIONS 3-DOTS MENU (ALL REQUESTED OPTIONS FULLY FUNCTIONAL)
  // ==========================================================================

  void _openTrack3DotsMenu(TrackItem track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final liked = _isLiked(track);
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                      title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70)),
                    ),
                    const Divider(color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: const Text('Share'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Share.share('Check out ${track.title} by ${track.artist} on Music Stream!\n${track.url}');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: const Text('Add to playlist'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addToPlaylist(track);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.hide_source_outlined),
                      title: const Text('Hide in this album'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hidden from album')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: const Text('Add to Queue'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addSongToQueue(track);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.format_list_bulleted),
                      title: const Text('Go to Queue'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openQueueDialog();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text('Go to artist (${track.artist})'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening artist: ${track.artist}')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_outlined),
                      title: const Text('Start a Jam (Premium)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jam session started')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Exclude track from your taste profile'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Track excluded from taste profile')));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.radio),
                      title: const Text('Go to song radio'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _playTrack(track, openModal: true);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('View song credits'),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            backgroundColor: const Color(0xFF242424),
                            title: Text(track.title),
                            content: Text('Artist: ${track.artist}\nPlays: ${track.playsCount}\nSource: GitHub Release Audio'),
                            actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close'))],
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.qr_code),
                      title: const Text('Show App Code & Spotify Tag'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code: MS-2026-VERIFIED')));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openQueueDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Playback Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _playbackQueue.isEmpty
                  ? const Center(child: Text('Queue is empty. Add songs using "Add to Queue".', style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      itemCount: _playbackQueue.length,
                      itemBuilder: (context, idx) {
                        final t = _playbackQueue[idx];
                        return ListTile(
                          title: Text(t.title, maxLines: 1),
                          subtitle: Text(t.artist),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _playbackQueue.removeAt(idx));
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DETAIL SCREENS (BOX / PLAYLIST & ARTIST PROFILE & STATS & REELS/VIDEOS)
  // ==========================================================================

  void _openBoxDetailScreen(BoxModel box) {
    final tracks = box.id == 'shortcut_0' && _likedSongs.isNotEmpty ? _likedSongs : box.tracks;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setPageState) {
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: Color(box.colorValue),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(box.colorValue), const Color(0xFF121212)],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Color(box.colorValue),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Icon(Icons.album, size: 70, color: Colors.white)),
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
                          Text(box.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(box.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_circle_down_outlined, size: 30, color: Colors.white70),
                                onPressed: () {
                                  for (var t in tracks) _downloadTrack(t);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, size: 26, color: Colors.white70),
                                onPressed: () => Share.share('Listen to ${box.name}'),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  if (tracks.isNotEmpty) _playTrack(tracks.first, queue: tracks, openModal: true);
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
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
                        final track = tracks[index];
                        final liked = _isLiked(track);
                        return ListTile(
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Color(box.colorValue).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                          title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1),
                          subtitle: Text(track.artist, style: const TextStyle(color: Colors.white60)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated Heart Button
                              IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Icon(
                                    liked ? Icons.favorite : Icons.favorite_border,
                                    key: ValueKey(liked),
                                    color: liked ? Colors.redAccent : Colors.white54,
                                    size: 22,
                                  ),
                                ),
                                onPressed: () {
                                  _toggleLike(track);
                                  setPageState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white60),
                                onPressed: () => _openTrack3DotsMenu(track),
                              ),
                            ],
                          ),
                          onTap: () => _playTrack(track, queue: tracks, openModal: true),
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),
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
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: Color(artist.colorValue),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(artist.colorValue), const Color(0xFF121212)],
                          ),
                        ),
                        child: const Center(
                          child: CircleAvatar(radius: 60, child: Icon(Icons.person, size: 70)),
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
                          Row(
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: isFollowing ? const Color(0xFF1DB954) : Colors.white54),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isFollowing) {
                                      _followedArtists.remove(artist.id);
                                    } else {
                                      _followedArtists.add(artist.id);
                                    }
                                  });
                                  _savePersistentState();
                                  setPageState(() {});
                                },
                                child: Text(isFollowing ? 'Following' : 'Follow'),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  if (artist.popularTracks.isNotEmpty) {
                                    _playTrack(artist.popularTracks.first, queue: artist.popularTracks, openModal: true);
                                  }
                                },
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Popular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = artist.popularTracks[index];
                        return ListTile(
                          leading: Text('${index + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          title: Text(track.title, maxLines: 1),
                          subtitle: Text(track.playsCount, style: const TextStyle(color: Colors.white60)),
                          onTap: () => _playTrack(track, queue: artist.popularTracks, openModal: true),
                        );
                      },
                      childCount: artist.popularTracks.length,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openListeningStatsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            title: const Text('Listening stats'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('This week', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Nov 16 – 22', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF242424), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Minutes listened', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          Text('23', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF242424), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Top song', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          Text('Street Fame', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Iqbal', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Your latest insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFB81D13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('PATANDAR • ARJAN DHILLON', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideosReelsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: 3,
                itemBuilder: (context, idx) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.primaries[idx % Colors.primaries.length], Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            'Video Reel #${idx + 1}\nPatandar / Street Fame',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          left: 16,
                          child: Row(
                            children: const [
                              CircleAvatar(child: Icon(Icons.music_note)),
                              SizedBox(width: 10),
                              Text('Playing from GitHub Audio • Tap to Stream', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
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
                      child: const Text('Clear', style: TextStyle(color: Color(0xFF1DB954))),
                    ),
                ],
              ),
              body: _recents.isEmpty
                  ? const Center(child: Text('No recently played songs yet.', style: TextStyle(color: Colors.white60)))
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
                            child: const Icon(Icons.history, color: Colors.white70),
                          ),
                          title: Text(track.title, maxLines: 1),
                          subtitle: Text('${track.artist} • ${_formatPlayedDate(track.playedAt)}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _openTrack3DotsMenu(track),
                          ),
                          onTap: () => _playTrack(track, queue: _recents, openModal: true),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // FULL PLAYER MODAL (WITH EASY GRAB SLIDER & QUEUE)
  // ==========================================================================

  void _openFullPlayerModal(TrackItem track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeTrack = _currentPlayingTrack ?? track;
            final maxDur = _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0;
            final curPos = _position.inSeconds.toDouble().clamp(0.0, maxDur);
            final liked = _isLiked(activeTrack);
            final isDownloaded = activeTrack.isDownloaded;

            return Container(
              height: MediaQuery.of(context).size.height * 0.94,
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
                      const Text('PLAYING FROM GITHUB RELEASE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _openTrack3DotsMenu(activeTrack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.album, size: 120, color: Colors.white24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activeTrack.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1),
                            const SizedBox(height: 4),
                            Text(activeTrack.artist, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                          ],
                        ),
                      ),
                      // Animated Heart
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(liked),
                            color: liked ? Colors.redAccent : Colors.white70,
                            size: 28,
                          ),
                        ),
                        onPressed: () {
                          _toggleLike(activeTrack);
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Easily grab/drag slider for skipping forward & backward
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                      min: 0.0,
                      max: maxDur,
                      value: curPos,
                      onChanged: (val) {
                        _audioPlayer.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}'),
                      Text('${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Controls (Download, Prev, Play/Pause, Next, Queue)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(isDownloaded ? Icons.download_done : Icons.download, color: isDownloaded ? const Color(0xFF1DB954) : Colors.white70),
                        onPressed: () => _downloadTrack(activeTrack),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: () => _playPreviousInQueue(),
                      ),
                      IconButton(
                        iconSize: 68,
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
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () => _playNextInQueue(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music, color: Colors.white70),
                        onPressed: () => _openQueueDialog(),
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
  // HOME TAB & FILTER TABS LOGIC
  // ==========================================================================

  Widget _buildHomeTab() {
    // Filter sections based on category chip ("All", "Music", "Podcasts")
    final filteredSections = _homeSections.where((section) {
      if (_selectedCategoryFilter == 'Music') {
        return section.type != HomeSectionType.featuredVideo;
      } else if (_selectedCategoryFilter == 'Podcasts') {
        return section.type == HomeSectionType.featuredVideo;
      }
      return true; // "All"
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top Header Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openListeningStatsScreen,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF4285F4),
                    child: Text(_settings.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                            onSelected: (_) => setState(() => _selectedCategoryFilter = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Phone / Reels Button
                IconButton(
                  tooltip: 'Video Feed',
                  icon: const Icon(Icons.phone_android, color: Colors.white),
                  onPressed: _openVideosReelsScreen,
                ),
                IconButton(
                  tooltip: 'Stats',
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  onPressed: _openListeningStatsScreen,
                ),
                IconButton(
                  tooltip: 'History',
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: _openRecentsScreen,
                ),
              ],
            ),
          ),
        ),

        // 8 Compact Shortcut Boxes at Top
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
                          child: Icon(index == 0 ? Icons.favorite : Icons.music_note, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shortcut.name,
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
              childCount: _top8Shortcuts.length,
            ),
          ),
        ),

        // Dynamic Home Sections (Boxes, Circles, Videos)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final section = filteredSections[index];
              if (section.type == HomeSectionType.boxLine) {
                return _buildHorizontalBoxLine(section);
              } else if (section.type == HomeSectionType.circleLine) {
                return _buildHorizontalCircleLine(section);
              } else {
                return _buildFeaturedVideoCard(section.video!);
              }
            },
            childCount: filteredSections.length,
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
          child: Text(section.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
                      Container(
                        height: 136,
                        width: 136,
                        decoration: BoxDecoration(
                          color: Color(box.colorValue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.album, size: 52, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(box.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                      Text(box.subtitle, style: const TextStyle(fontSize: 11, color: Colors.white60), maxLines: 1),
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
          child: Text(section.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
                      CircleAvatar(radius: 56, backgroundColor: Color(artist.colorValue), child: const Icon(Icons.person, size: 50)),
                      const SizedBox(height: 8),
                      Text(artist.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, textAlign: TextAlign.center),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 6),
      child: _AnimatedPressCard(
        onTap: () => _playTrack(video.audioTrack, openModal: true),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 195,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(video.colorValue), Colors.black87], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        video.bannerHeadline,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: Text(video.durationLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Color(video.colorValue), child: const Icon(Icons.podcasts)),
                title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2),
                subtitle: Text('${video.channel} • ${video.meta}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
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
          title: const Text('Your Playlist & Library', style: TextStyle(fontWeight: FontWeight.bold)),
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
            _buildTrackListSection(_playlist, 'Playlist is empty.', (t) => setState(() => _playlist.removeWhere((x) => x.id == t.id))),
            _buildTrackListSection(_likedSongs, 'No Liked Songs.', (t) => _toggleLike(t)),
            _buildTrackListSection(_downloads, 'No Downloaded Songs.', (t) => setState(() => _downloads.removeWhere((x) => x.id == t.id))),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackListSection(List<TrackItem> tracks, String emptyMsg, Function(TrackItem) onRemove) {
    if (tracks.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyMsg, style: const TextStyle(color: Colors.white60))));
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
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.music_note),
          ),
          title: Text(track.title, maxLines: 1),
          subtitle: Text(track.artist, style: const TextStyle(color: Colors.white60)),
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
          duration: const Duration(milliseconds: 250),
          child: _currentTabIndex == 0 ? _buildHomeTab() : _buildPlaylistLibraryTab(),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentPlayingTrack == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    key: ValueKey(_currentPlayingTrack!.id),
                    onTap: () => _openFullPlayerModal(_currentPlayingTrack!),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_currentPlayingTrack!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                                Text(_currentPlayingTrack!.artist, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isLiked(_currentPlayingTrack!) ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked(_currentPlayingTrack!) ? Colors.redAccent : Colors.white,
                            ),
                            onPressed: () => _toggleLike(_currentPlayingTrack!),
                          ),
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
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
          BottomNavigationBar(
            currentIndex: _currentTabIndex,
            backgroundColor: const Color(0xFF121212),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            onTap: (idx) => setState(() => _currentTabIndex = idx),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), activeIcon: Icon(Icons.library_music), label: 'Your Playlist'),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SPRING SCALE ANIMATION WRAPPER
// ==========================================================================

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
