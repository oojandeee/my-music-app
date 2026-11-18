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
  String themeMode; // 'System', 'Dark', 'Light'
  bool equalizerEnabled;

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
    this.themeMode = 'Dark',
    this.equalizerEnabled = true,
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
        'themeMode': themeMode,
        'equalizerEnabled': equalizerEnabled,
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
        themeMode: json['themeMode'] ?? 'Dark',
        equalizerEnabled: json['equalizerEnabled'] ?? true,
      );
}

// ============================================================================
// APP ROOT
// ============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainAppRoot();
  }
}

class MainAppRoot extends StatefulWidget {
  const MainAppRoot({super.key});

  @override
  State<MainAppRoot> createState() => MainAppRootState();

  static MainAppRootState of(BuildContext context) =>
      context.findAncestorStateOfType<MainAppRootState>()!;
}

class MainAppRootState extends State<MainAppRoot> {
  AppSettings _settings = AppSettings();

  void updateSettings(AppSettings newSettings) {
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _settings.themeMode == 'Light';
    return MaterialApp(
      title: 'Music Stream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: isLight ? Colors.white : const Color(0xFF121212),
        colorScheme: isLight
            ? ColorScheme.light(primary: const Color(0xFF1DB954), surface: Colors.grey[100]!)
            : ColorScheme.dark(primary: const Color(0xFF1DB954), surface: const Color(0xFF181818)),
      ),
      home: MainTabScreen(settings: _settings, onSettingsChanged: updateSettings),
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class MainTabScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const MainTabScreen({super.key, required this.settings, required this.onSettingsChanged});

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
  Set<String> _hiddenTrackIds = {};
  Set<String> _excludedTrackIds = {};
  int _listeningStreak = 1;
  int _totalUsageMinutes = 23; // Tracked usage time

  // Playback State
  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final List<BoxModel> _top8Shortcuts;
  late final List<HomeSection> _homeSections;

  // Reliable public raw MP3 audio URL guaranteeing zero source errors
  static const String _stableAudioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

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
    return List.generate(6, (i) {
      return TrackItem(
        id: '${prefix}_track_$i',
        title: i == 0 ? 'Karol G (Hit Single)' : 'Track ${i + 1} ($prefix)',
        artist: i == 0 ? 'Karol G, Judeline, rusowsky' : artistName,
        url: _stableAudioUrl,
        playsCount: '${(71 - i * 4)},297,233',
      );
    });
  }

  void _buildCatalogData() {
    final shortcutNames = [
      'Search',
      'Karol G Mix',
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
        subtitle: i == 0 ? 'Tap to Search' : 'Curated Mix',
        description: 'Quick access to ${shortcutNames[i]} and top tracks.',
        colorValue: _palette[i % _palette.length],
        tracks: _generateSampleTracks(shortcutNames[i], i == 0 ? 'Karol G' : 'Iqbal'),
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
    ];
    final artistNames = [
      'Karol G',
      'Arjan Dhillon',
      'Sidhu Moose Wala',
      'Prem Dhillon',
      'Arijit Singh',
      'Diljit Dosanjh',
      'Cheema Y',
      'Shubh',
    ];

    int boxLineCounter = 0;
    int circleLineCounter = 0;

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
              final boxName = b == 0 && cycle == 0 && l == 0 ? 'Karol G Hits' : '$lineTitle #${b + 1}';
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

      _homeSections.add(
        HomeSection(
          id: 'featured_video_${cycle}_1',
          type: HomeSectionType.featuredVideo,
          title: 'Featured Episode',
          video: FeaturedVideoModel(
            id: 'vid_${cycle}_1',
            bannerHeadline: cycle == 0 ? 'Karol G Live' : 'Patandar',
            title: cycle == 0 ? 'Karol G Global Tour Visualizer & Audio' : 'Deep Focus & Behind The Beats',
            channel: cycle == 0 ? 'Karol G' : 'Psyphoria',
            meta: 'Nov 18 • 240K+ plays',
            durationLabel: '27:11',
            colorValue: cycle == 0 ? 0xFFE8115B : 0xFF1B4D3E,
            audioTrack: TrackItem(
              id: 'vid_track_${cycle}_1',
              title: 'Karol G Special Audio Mix',
              artist: 'Karol G',
              url: _stableAudioUrl,
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
    return File('${dir.path}/music_app_persistent_v5.json');
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
        'hiddenTrackIds': _hiddenTrackIds.toList(),
        'excludedTrackIds': _excludedTrackIds.toList(),
        'settings': widget.settings.toJson(),
        'listeningStreak': _listeningStreak,
        'totalUsageMinutes': _totalUsageMinutes,
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
          _hiddenTrackIds = Set<String>.from(data['hiddenTrackIds'] ?? const []);
          _excludedTrackIds = Set<String>.from(data['excludedTrackIds'] ?? const []);
          if (data['settings'] != null) {
            widget.onSettingsChanged(AppSettings.fromJson(data['settings']));
          }
          _listeningStreak = data['listeningStreak'] ?? 1;
          _totalUsageMinutes = data['totalUsageMinutes'] ?? 23;
        });
      }
    } catch (_) {}
  }

  // ==========================================================================
  // AUDIO PLAYBACK & STATS
  // ==========================================================================

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (state.playing) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _isPlaying) {
            setState(() {
              _listeningStreak = 2;
              _totalUsageMinutes += 1;
            });
            _savePersistentState();
          }
        });
      }
      if (state.processingState == ProcessingState.completed && widget.settings.autoplay) {
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
    if (_excludedTrackIds.contains(track.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This track is excluded from your taste profile.')),
      );
      return;
    }
    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingTrack = track;
        if (queue != null && queue.isNotEmpty) {
          _playbackQueue = List.from(queue);
        }
        if (!widget.settings.privateSession) {
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
    setState(() => _playbackQueue.add(track));
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
  bool _isInPlaylist(TrackItem track) => _playlist.any((item) => item.id == track.id);

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
        SnackBar(content: Text('"${track.title}" added to playlist')),
      );
    } else {
      setState(() => _playlist.removeWhere((t) => t.id == track.id));
      _savePersistentState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${track.title}" removed from playlist')),
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
  // OPTIONS 3-DOTS MENU (CLEANED UP & FULLY FUNCTIONAL)
  // ==========================================================================

  void _openTrack3DotsMenu(TrackItem track, {VoidCallback? onHide}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.black),
                      ),
                      title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                      subtitle: Text(track.artist, style: const TextStyle(color: Colors.white70)),
                    ),
                    const Divider(color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: const Text('Share'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Share.share('Check out ${track.title} by ${track.artist}!\n${track.url}');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.playlist_add),
                      title: Text(_isInPlaylist(track) ? 'Remove from playlist' : 'Add to playlist'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addToPlaylist(track);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.hide_source_outlined),
                      title: const Text('Hide in this album'),
                      onTap: () {
                        setState(() {
                          _hiddenTrackIds.add(track.id);
                        });
                        _savePersistentState();
                        Navigator.pop(ctx);
                        if (onHide != null) onHide();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hidden "${track.title}" from this album')),
                        );
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
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Exclude track from your taste profile'),
                      onTap: () {
                        setState(() {
                          _excludedTrackIds.add(track.id);
                        });
                        _savePersistentState();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Excluded "${track.title}" from your taste profile')),
                        );
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
                            content: Text('Artist: ${track.artist}\nPlays: ${track.playsCount}\nSource: CDN MP3 Direct Stream'),
                            actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close'))],
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
                  ? const Center(child: Text('Queue is empty.', style: TextStyle(color: Colors.white60)))
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
  // SEARCH SCREEN (YOUTUBE-STYLE BLACK SCREEN)
  // ==========================================================================

  void _openSearchScreen() {
    final searchController = TextEditingController();
    List<TrackItem> searchResults = [];
    List<CircleItem> artistResults = [];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setSearchState) {
            void performSearch(String query) {
              setSearchState(() {
                if (query.trim().isEmpty) {
                  searchResults = [];
                  artistResults = [];
                  return;
                }
                final q = query.toLowerCase();
                searchResults = [];
                for (final section in _homeSections) {
                  if (section.boxes != null) {
                    for (final b in section.boxes!) {
                      for (final t in b.tracks) {
                        if (t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q)) {
                          if (!searchResults.any((x) => x.id == t.id)) searchResults.add(t);
                        }
                      }
                    }
                  }
                }
                artistResults = [];
                for (final section in _homeSections) {
                  if (section.circles != null) {
                    for (final c in section.circles!) {
                      if (c.name.toLowerCase().contains(q)) {
                        if (!artistResults.any((x) => x.id == c.id)) artistResults.add(c);
                      }
                    }
                  }
                }
              });
            }

            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search songs, artists, podcasts...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onChanged: performSearch,
                ),
              ),
              body: searchController.text.trim().isEmpty
                  ? const Center(child: Text('Type to search across all boxes and podcasts', style: TextStyle(color: Colors.white54)))
                  : (searchResults.isEmpty && artistResults.isEmpty)
                      ? const Center(child: Text('No results found', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (artistResults.isNotEmpty) ...[
                              const Text('Artists', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              ...artistResults.map((artist) => ListTile(
                                    leading: CircleAvatar(backgroundColor: Color(artist.colorValue), child: const Icon(Icons.person)),
                                    title: Text(artist.name, style: const TextStyle(color: Colors.white)),
                                    subtitle: Text(artist.monthlyListeners, style: const TextStyle(color: Colors.white60)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _openCircleArtistScreen(artist);
                                    },
                                  )),
                              const SizedBox(height: 16),
                            ],
                            if (searchResults.isNotEmpty) ...[
                              const Text('Songs & Audio', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              ...searchResults.map((track) => ListTile(
                                    leading: const Icon(Icons.music_note, color: Colors.white),
                                    title: Text(track.title, style: const TextStyle(color: Colors.white)),
                                    subtitle: Text(track.artist, style: const TextStyle(color: Colors.white60)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _playTrack(track, queue: searchResults, openModal: true);
                                    },
                                  )),
                            ],
                          ],
                        ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // FEEDBACK SCREEN IN SETTINGS
  // ==========================================================================

  void _openFeedbackScreen() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name*', hintText: 'Enter your name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject*', hintText: 'Enter subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Feedback*', hintText: 'Write your feedback here...'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty || subjectCtrl.text.trim().isEmpty || feedbackCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submitted successfully')),
                    );
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // EQUALIZER SCREEN IN SETTINGS
  // ==========================================================================

  void _openEqualizerScreen() {
    double bassVal = 5.0;
    double virtualizerVal = 3.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setEqState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Powerful Equalizer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Switch(
                        value: widget.settings.equalizerEnabled,
                        activeColor: const Color(0xFF1DB954),
                        onChanged: (val) {
                          widget.onSettingsChanged(AppSettings(
                            username: widget.settings.username,
                            privateSession: widget.settings.privateSession,
                            publicPlaylists: widget.settings.publicPlaylists,
                            gaplessPlayback: widget.settings.gaplessPlayback,
                            autoplay: widget.settings.autoplay,
                            pushNotifications: widget.settings.pushNotifications,
                            emailNotifications: widget.settings.emailNotifications,
                            dataSaverMode: widget.settings.dataSaverMode,
                            downloadOverCellular: widget.settings.downloadOverCellular,
                            streamingQuality: widget.settings.streamingQuality,
                            downloadQuality: widget.settings.downloadQuality,
                            tailoredAds: widget.settings.tailoredAds,
                            themeMode: widget.settings.themeMode,
                            equalizerEnabled: val,
                          ));
                          setEqState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text('60Hz', style: TextStyle(color: Colors.white60)),
                      Text('230Hz', style: TextStyle(color: Colors.white60)),
                      Text('910Hz', style: TextStyle(color: Colors.white60)),
                      Text('3.6kHz', style: TextStyle(color: Colors.white60)),
                      Text('14kHz', style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => SizedBox(
                      height: 100,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: 3.0 + (i * 1.5),
                          min: -15.0,
                          max: 15.0,
                          activeColor: Colors.amber,
                          onChanged: widget.settings.equalizerEnabled ? (_) {} : null,
                        ),
                      ),
                    )),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('BASS', style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: bassVal,
                            min: 0,
                            max: 10,
                            activeColor: Colors.amber,
                            onChanged: widget.settings.equalizerEnabled ? (v) => setEqState(() => bassVal = v) : null,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('VIRTUALIZER', style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: virtualizerVal,
                            min: 0,
                            max: 10,
                            activeColor: Colors.amber,
                            onChanged: widget.settings.equalizerEnabled ? (v) => setEqState(() => virtualizerVal = v) : null,
                          ),
                        ],
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

  // ==========================================================================
  // DETAIL SCREENS (BOX / PLAYLIST & ARTIST PROFILE & SETTINGS)
  // ==========================================================================

  void _openBoxDetailScreen(BoxModel box) {
    final rawTracks = box.id == 'shortcut_0' && _likedSongs.isNotEmpty ? _likedSongs : box.tracks;
    final tracks = rawTracks.where((t) => !_hiddenTrackIds.contains(t.id)).toList();

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: StatefulBuilder(
            builder: (context, setPageState) {
              return Scaffold(
                backgroundColor: widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212),
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
                              colors: [Color(box.colorValue), widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212)],
                            ),
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'box_${box.id}',
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
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(box.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white)),
                            const SizedBox(height: 6),
                            Text(box.description, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white70, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_circle_down_outlined, size: 30, color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white70),
                                  onPressed: () {
                                    for (var t in tracks) _downloadTrack(t);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.share, size: 26, color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white70),
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
                          final inPlaylist = _isInPlaylist(track);
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
                            title: Text(track.title, style: TextStyle(fontWeight: FontWeight.w600, color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white), maxLines: 1),
                            subtitle: Text(track.artist, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white60)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    inPlaylist ? Icons.check_circle : Icons.playlist_add,
                                    color: inPlaylist ? const Color(0xFF1DB954) : (widget.settings.themeMode == 'Light' ? Colors.black45 : Colors.white54),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    _addToPlaylist(track);
                                    setPageState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: AnimatedRotation(
                                    turns: liked ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      liked ? Icons.favorite : Icons.favorite_border,
                                      color: liked ? Colors.redAccent : (widget.settings.themeMode == 'Light' ? Colors.black45 : Colors.white54),
                                      size: 22,
                                    ),
                                  ),
                                  onPressed: () {
                                    _toggleLike(track);
                                    setPageState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.more_vert, color: widget.settings.themeMode == 'Light' ? Colors.black45 : Colors.white60),
                                  onPressed: () => _openTrack3DotsMenu(track, onHide: () => setPageState(() {})),
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
      ),
    );
  }

  void _openCircleArtistScreen(CircleItem artist) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: StatefulBuilder(
            builder: (context, setPageState) {
              final isFollowing = _followedArtists.contains(artist.id);
              return Scaffold(
                backgroundColor: widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212),
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
                              colors: [Color(artist.colorValue), widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212)],
                            ),
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'circle_${artist.id}',
                              child: const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 70)),
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
                            Row(
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white,
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
                            Text('Popular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = artist.popularTracks[index];
                          return ListTile(
                            leading: Text('${index + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white)),
                            title: Text(track.title, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white), maxLines: 1),
                            subtitle: Text(track.playsCount, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white60)),
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
                        children: [
                          const Text('Minutes listened', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('$_totalUsageMinutes', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
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
                          Text('Karol G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Karol G, Judeline', style: TextStyle(color: Colors.white60, fontSize: 11)),
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
                  color: const Color(0xFFE8115B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('KAROL G HITS • GLOBAL MIX', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
              backgroundColor: widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor: widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212),
                title: Text('Settings', style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white)),
                iconTheme: IconThemeData(color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white),
              ),
              body: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  // Theme Switcher (System, Dark, Light)
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined, size: 28),
                    title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Current: ${widget.settings.themeMode} Theme'),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1E1E1E),
                        builder: (bCtx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ['System Theme', 'Dark', 'Light']
                              .map((t) => ListTile(
                                    title: Text(t),
                                    trailing: widget.settings.themeMode == t ? const Icon(Icons.check, color: Color(0xFF1DB954)) : null,
                                    onTap: () {
                                      updateSetting(() {
                                        widget.settings.themeMode = t == 'System Theme' ? 'Dark' : t;
                                      });
                                      widget.onSettingsChanged(widget.settings);
                                      Navigator.pop(bCtx);
                                    },
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                  // Equalizer option
                  ListTile(
                    leading: const Icon(Icons.equalizer, size: 28),
                    title: const Text('Equalizer', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Powerful frequency adjustment & bass boost'),
                    onTap: () => _openEqualizerScreen(),
                  ),
                  // Listening stats in settings
                  ListTile(
                    leading: const Icon(Icons.bar_chart, size: 28),
                    title: const Text('Listening stats', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total app usage time recorded: $_totalUsageMinutes minutes'),
                    onTap: () => _openListeningStatsScreen(),
                  ),
                  // Feedback section
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined, size: 28),
                    title: const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Send name, subject, and feedback'),
                    onTap: () => _openFeedbackScreen(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined, size: 28),
                    title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${widget.settings.username} • Edit profile'),
                    onTap: () {
                      final ctrl = TextEditingController(text: widget.settings.username);
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: const Color(0xFF242424),
                          title: const Text('Edit Username'),
                          content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Enter username')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                if (ctrl.text.trim().isNotEmpty) {
                                  updateSetting(() => widget.settings.username = ctrl.text.trim());
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
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline, size: 28),
                    title: const Text('Privacy and social', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Private session & Public playlists'),
                    value: widget.settings.privateSession,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) => updateSetting(() => widget.settings.privateSession = val),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined, size: 28),
                    title: const Text('Playback', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Gapless playback & Autoplay'),
                    value: widget.settings.autoplay,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) => updateSetting(() => widget.settings.autoplay = val),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // FULL PLAYER MODAL (WITH EQUALIZER & LYRICS)
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
            final inPlaylist = _isInPlaylist(activeTrack);

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
                      const Text('PLAYING FROM KAROL G MIX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.album, size: 120, color: Colors.white24),
                          // Beat animation on playing track
                          if (_isPlaying)
                            Positioned(
                              bottom: 24,
                              child: Row(
                                children: List.generate(
                                  5,
                                  (i) => AnimatedContainer(
                                    duration: Duration(milliseconds: 200 + i * 80),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 4,
                                    height: 12.0 + (i % 3) * 12,
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
                            Text(activeTrack.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1),
                            const SizedBox(height: 4),
                            Text(activeTrack.artist, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          inPlaylist ? Icons.check_circle : Icons.playlist_add,
                          color: inPlaylist ? const Color(0xFF1DB954) : Colors.white70,
                          size: 26,
                        ),
                        onPressed: () {
                          _addToPlaylist(activeTrack);
                          setModalState(() {});
                        },
                      ),
                      IconButton(
                        icon: AnimatedRotation(
                          turns: liked ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lyrics, color: Colors.white70),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1E1E1E),
                            builder: (lCtx) => Container(
                              padding: const EdgeInsets.all(20),
                              height: 300,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Synced Lyrics - ${activeTrack.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  const Text('They say we’re too young\nTo ourselves sprung\nOh we didn’t care\nWe made it very clear...', style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                                ],
                              ),
                            ),
                          );
                        },
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
    final filteredSections = _homeSections.where((section) {
      if (_selectedCategoryFilter == 'Music') {
        return section.type != HomeSectionType.featuredVideo;
      } else if (_selectedCategoryFilter == 'Podcasts') {
        return section.type == HomeSectionType.featuredVideo;
      }
      return true;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top Header Bar with Streak 🔥 1 & Settings
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text('$_listeningStreak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                IconButton(
                  tooltip: 'History',
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => Scaffold(
                          backgroundColor: const Color(0xFF121212),
                          appBar: AppBar(title: const Text('Recents')),
                          body: _recents.isEmpty
                              ? const Center(child: Text('No recently played songs.', style: TextStyle(color: Colors.white60)))
                              : ListView.builder(
                                  itemCount: _recents.length,
                                  itemBuilder: (context, i) {
                                    final t = _recents[i];
                                    return ListTile(
                                      title: Text(t.title),
                                      subtitle: Text('${t.artist} • ${_formatPlayedDate(t.playedAt)}'),
                                      onTap: () => _playTrack(t, openModal: true),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  },
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

        // 8 Compact Shortcut Boxes at Top (First shortcut is named Search)
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
                  onTap: () {
                    if (index == 0) {
                      _openSearchScreen();
                    } else {
                      _openBoxDetailScreen(shortcut);
                    }
                  },
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
                          child: Icon(index == 0 ? Icons.search : Icons.music_note, color: Colors.white, size: 20),
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

        // Dynamic Home Sections
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
                      Hero(
                        tag: 'box_${box.id}',
                        child: Container(
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
                      Hero(
                        tag: 'circle_${artist.id}',
                        child: CircleAvatar(radius: 56, backgroundColor: Color(artist.colorValue), child: const Icon(Icons.person, size: 50)),
                      ),
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
        backgroundColor: widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: widget.settings.themeMode == 'Light' ? Colors.white : const Color(0xFF121212),
          title: Text('Your Playlist & Library', style: TextStyle(fontWeight: FontWeight.bold, color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white)),
          bottom: TabBar(
            indicatorColor: const Color(0xFF1DB954),
            labelColor: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white,
            tabs: const [
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
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyMsg, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white60))));
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
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(track.title, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black : Colors.white), maxLines: 1),
          subtitle: Text(track.artist, style: TextStyle(color: widget.settings.themeMode == 'Light' ? Colors.black54 : Colors.white60)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => onRemove(track),
          ),
          onTap: () => _playTrack(track, queue: tracks, openModal: true),
        );
      },
    );
  }

  // ==========================================================================
  // BUILD SCAFFOLD (WITH SMOOTH TAB PILL ANIMATION)
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final isLight = widget.settings.themeMode == 'Light';
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
          // Custom Bottom Bar with Animated "White Ball" Pill Transition
          Container(
            color: isLight ? Colors.white : const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavTabItem(0, Icons.home_outlined, Icons.home_filled, 'Home'),
                _buildNavTabItem(1, Icons.library_music_outlined, Icons.library_music, 'Your Playlist'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final selected = _currentTabIndex == index;
    final isLight = widget.settings.themeMode == 'Light';
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (isLight ? Colors.black12 : Colors.white24) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(selected ? iconFilled : iconOutlined, color: isLight ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SPRING SCALE ANIMATION WRAPPER
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
