import 'dart:async';
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
  final String assetPath;
  final String playsCount;
  final DateTime playedAt;
  bool isDownloaded;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.assetPath,
    this.playsCount = '71,297,233',
    DateTime? playedAt,
    this.isDownloaded = false,
  }) : playedAt = playedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'assetPath': assetPath,
        'playsCount': playsCount,
        'playedAt': playedAt.toIso8601String(),
        'isDownloaded': isDownloaded,
      };

  factory TrackItem.fromJson(Map<String, dynamic> json) => TrackItem(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Unknown Title',
        artist: json['artist'] ?? 'Unknown Artist',
        assetPath: json['assetPath'] ?? 'sample_track_1.mp3',
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

class UserProfileData {
  String firstName;
  String lastName;
  String email;
  String phone;
  String city;
  String address;
  int? selectedAvatarIndex; // null means use first letter of name
  bool isCreated;

  UserProfileData({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.address = '',
    this.selectedAvatarIndex,
    this.isCreated = false,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? 'Music Lover' : full;
  }

  String get initialLetter {
    if (firstName.trim().isNotEmpty) {
      return firstName.trim()[0].toUpperCase();
    }
    return 'G';
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'city': city,
        'address': address,
        'selectedAvatarIndex': selectedAvatarIndex,
        'isCreated': isCreated,
      };

  factory UserProfileData.fromJson(Map<String, dynamic> json) =>
      UserProfileData(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        city: json['city'] ?? '',
        address: json['address'] ?? '',
        selectedAvatarIndex: json['selectedAvatarIndex'],
        isCreated: json['isCreated'] ?? false,
      );
}

class AppSettings {
  bool privateSession;
  bool publicPlaylists;
  bool gaplessPlayback;
  bool autoplay;
  bool pushNotifications;
  String streamingQuality;
  String downloadQuality;
  String themeMode; // 'Dark', 'Light'
  bool equalizerEnabled;

  AppSettings({
    this.privateSession = false,
    this.publicPlaylists = true,
    this.gaplessPlayback = true,
    this.autoplay = true,
    this.pushNotifications = true,
    this.streamingQuality = 'High',
    this.downloadQuality = 'Very High',
    this.themeMode = 'Dark',
    this.equalizerEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'privateSession': privateSession,
        'publicPlaylists': publicPlaylists,
        'gaplessPlayback': gaplessPlayback,
        'autoplay': autoplay,
        'pushNotifications': pushNotifications,
        'streamingQuality': streamingQuality,
        'downloadQuality': downloadQuality,
        'themeMode': themeMode,
        'equalizerEnabled': equalizerEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        privateSession: json['privateSession'] ?? false,
        publicPlaylists: json['publicPlaylists'] ?? true,
        gaplessPlayback: json['gaplessPlayback'] ?? true,
        autoplay: json['autoplay'] ?? true,
        pushNotifications: json['pushNotifications'] ?? true,
        streamingQuality: json['streamingQuality'] ?? 'High',
        downloadQuality: json['downloadQuality'] ?? 'Very High',
        themeMode: json['themeMode'] ?? 'Dark',
        equalizerEnabled: json['equalizerEnabled'] ?? true,
      );
}

class ShopCosmeticItem {
  final String id;
  final String name;
  final String tier; // Wood, Iron, Silver, Gold, Diamond, Flowers
  final String type; // 'badge' or 'frame'
  final int cost;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const ShopCosmeticItem({
    required this.id,
    required this.name,
    required this.tier,
    required this.type,
    required this.cost,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });
}

class MissionItem {
  final String id;
  final String title;
  final String description;
  final String metricType; // 'songs', 'minutes', 'streak', 'likes', 'playlist'
  final int targetValue;
  final int coinReward;
  final int expReward;

  const MissionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.metricType,
    required this.targetValue,
    required this.coinReward,
    required this.expReward,
  });
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
        scaffoldBackgroundColor:
            isLight ? Colors.white : const Color(0xFF121212),
        colorScheme: isLight
            ? ColorScheme.light(
                primary: const Color(0xFF1DB954), surface: Colors.grey[100]!)
            : const ColorScheme.dark(
                primary: Color(0xFF1DB954), surface: Color(0xFF181818)),
      ),
      home:
          MainTabScreen(settings: _settings, onSettingsChanged: updateSettings),
    );
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class MainTabScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const MainTabScreen(
      {super.key, required this.settings, required this.onSettingsChanged});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentTabIndex = 0;
  String _selectedCategoryFilter = 'All';
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _listeningTrackerTimer;

  // Core Music & App Persistence
  List<TrackItem> _playlist = [];
  List<TrackItem> _likedSongs = [];
  List<TrackItem> _downloads = [];
  List<TrackItem> _recents = [];
  List<TrackItem> _playbackQueue = [];
  Set<String> _followedArtists = {};
  Set<String> _hiddenTrackIds = {};
  Set<String> _excludedTrackIds = {};

  // Gamification, Profile, Quests, Level & Economy State
  UserProfileData _profile = UserProfileData();
  int _coins = 50;
  int _totalExp = 0;
  int _listeningStreak = 1;
  int _previousStreakBeforeLoss = 0;
  String _lastActiveDateStr = '';
  int _dailyRewardDayIndex = 1; // 1 to 7
  String _lastDailyClaimDateStr = '';
  int _streakSaverTokens = 1;
  DateTime? _doubleExpEndTime;

  // Long-Term Mission Progress Counters
  int _totalSongsListened = 0;
  int _totalUsageMinutes = 23;
  int _currentTrackSecondsListened = 0;
  int _lastAwardedMinuteBlock = 0;
  Set<String> _claimedMissionIds = {};

  // Exchange Store Owned & Equipped Cosmetics
  Set<String> _ownedCosmeticIds = {'badge_wood', 'frame_wood'};
  String _equippedBadgeId = 'badge_wood';
  String _equippedFrameId = 'frame_wood';

  // Playback State
  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final List<BoxModel> _top8Shortcuts;
  late final List<HomeSection> _homeSections;

  // Bundled Root Asset File from pubspec.yaml
  static const String _bundledAssetPath = 'sample_track_1.mp3';

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

  // JioHotstar-style Avatar Choices
  static const List> _avatarCatalog = [
    {'name': 'Beat King', 'icon': Icons.headphones, 'bg': 0xFF1DB954},
    {'name': 'Star Boy', 'icon': Icons.star_rounded, 'bg': 0xFFE8115B},
    {'name': 'Cyber DJ', 'icon': Icons.graphic_eq, 'bg': 0xFF0D73EC},
    {'name': 'Fire Soul', 'icon': Icons.local_fire_department, 'bg': 0xFFBA5D07},
    {'name': 'Royal Crown', 'icon': Icons.workspace_premium, 'bg': 0xFF8D67AB},
    {'name': 'Night Owl', 'icon': Icons.nightlight_round, 'bg': 0xFF1E3264},
    {'name': 'Rockstar', 'icon': Icons.electric_bolt, 'bg': 0xFFD97706},
    {'name': 'Melody', 'icon': Icons.music_note, 'bg': 0xFFAF2896},
    {'name': 'Vibe Master', 'icon': Icons.album, 'bg': 0xFF148A08},
    {'name': 'Galaxy', 'icon': Icons.auto_awesome, 'bg': 0xFF477D95},
  ];

  // Exchange Store Badges & Frames Catalog
  static const List<ShopCosmeticItem> _shopItems = [
    // Badges
    ShopCosmeticItem(
      id: 'badge_wood',
      name: 'Wood Badge',
      tier: 'Wood',
      type: 'badge',
      cost: 20,
      primaryColor: Color(0xFF8D5524),
      secondaryColor: Color(0xFF5C3818),
      icon: Icons.shield,
    ),
    ShopCosmeticItem(
      id: 'badge_iron',
      name: 'Iron Badge',
      tier: 'Iron',
      type: 'badge',
      cost: 60,
      primaryColor: Color(0xFF9CA3AF),
      secondaryColor: Color(0xFF4B5563),
      icon: Icons.security,
    ),
    ShopCosmeticItem(
      id: 'badge_silver',
      name: 'Silver Badge',
      tier: 'Silver',
      type: 'badge',
      cost: 150,
      primaryColor: Color(0xFFE5E7EB),
      secondaryColor: Color(0xFF9CA3AF),
      icon: Icons.verified,
    ),
    ShopCosmeticItem(
      id: 'badge_gold',
      name: 'Gold Badge',
      tier: 'Gold',
      type: 'badge',
      cost: 350,
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFB45309),
      icon: Icons.workspace_premium,
    ),
    ShopCosmeticItem(
      id: 'badge_diamond',
      name: 'Diamond Badge',
      tier: 'Diamond',
      type: 'badge',
      cost: 800,
      primaryColor: Color(0xFF38BDF8),
      secondaryColor: Color(0xFF0284C7),
      icon: Icons.diamond,
    ),
    // Avatar Frames
    ShopCosmeticItem(
      id: 'frame_wood',
      name: 'Wood Frame',
      tier: 'Wood',
      type: 'frame',
      cost: 30,
      primaryColor: Color(0xFF8D5524),
      secondaryColor: Color(0xFF5C3818),
      icon: Icons.crop_square,
    ),
    ShopCosmeticItem(
      id: 'frame_iron',
      name: 'Iron Frame',
      tier: 'Iron',
      type: 'frame',
      cost: 80,
      primaryColor: Color(0xFF9CA3AF),
      secondaryColor: Color(0xFF4B5563),
      icon: Icons.radio_button_unchecked,
    ),
    ShopCosmeticItem(
      id: 'frame_silver',
      name: 'Silver Frame',
      tier: 'Silver',
      type: 'frame',
      cost: 180,
      primaryColor: Color(0xFFF3F4F6),
      secondaryColor: Color(0xFF9CA3AF),
      icon: Icons.brightness_low,
    ),
    ShopCosmeticItem(
      id: 'frame_flowers',
      name: 'Floral Blossom Frame',
      tier: 'Flowers',
      type: 'frame',
      cost: 280,
      primaryColor: Color(0xFFF472B6),
      secondaryColor: Color(0xFFDB2777),
      icon: Icons.local_florist,
    ),
    ShopCosmeticItem(
      id: 'frame_gold',
      name: 'Royal Gold Frame',
      tier: 'Gold',
      type: 'frame',
      cost: 450,
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.stars,
    ),
    ShopCosmeticItem(
      id: 'frame_diamond',
      name: 'Eternal Diamond Frame',
      tier: 'Diamond',
      type: 'frame',
      cost: 1000,
      primaryColor: Color(0xFF38BDF8),
      secondaryColor: Color(0xFF818CF8),
      icon: Icons.auto_awesome,
    ),
  ];

  // Long-Term Missions (Months of Progression)
  static const List<MissionItem> _longTermMissions = [
    MissionItem(
      id: 'm_songs_10',
      title: 'Warming Up',
      description: 'Listen to 10 songs completely or actively',
      metricType: 'songs',
      targetValue: 10,
      coinReward: 100,
      expReward: 150,
    ),
    MissionItem(
      id: 'm_mins_50',
      title: 'Dedicated Listener',
      description: 'Use the app and listen for 50 minutes',
      metricType: 'minutes',
      targetValue: 50,
      coinReward: 150,
      expReward: 250,
    ),
    MissionItem(
      id: 'm_songs_50',
      title: 'Music Enthusiast',
      description: 'Listen to 50 songs across playlists & mixes',
      metricType: 'songs',
      targetValue: 50,
      coinReward: 250,
      expReward: 400,
    ),
    MissionItem(
      id: 'm_songs_100',
      title: 'Century Club',
      description: 'Listen to 100 songs in the app',
      metricType: 'songs',
      targetValue: 100,
      coinReward: 400,
      expReward: 700,
    ),
    MissionItem(
      id: 'm_mins_300',
      title: '5-Hour Marathon',
      description: 'Record 300 minutes of total listening time',
      metricType: 'minutes',
      targetValue: 300,
      coinReward: 600,
      expReward: 1000,
    ),
    MissionItem(
      id: 'm_streak_14',
      title: 'Two-Week Pyro',
      description: 'Maintain a 14-day listening streak',
      metricType: 'streak',
      targetValue: 14,
      coinReward: 500,
      expReward: 900,
    ),
    MissionItem(
      id: 'm_songs_500',
      title: 'Audiophile Legend (Multi-Month)',
      description: 'Listen to 500 songs over your journey',
      metricType: 'songs',
      targetValue: 500,
      coinReward: 1200,
      expReward: 2500,
    ),
    MissionItem(
      id: 'm_mins_1500',
      title: '25-Hour Titan (Multi-Month)',
      description: 'Listen to music & podcasts for 1,500 minutes',
      metricType: 'minutes',
      targetValue: 1500,
      coinReward: 2000,
      expReward: 4000,
    ),
    MissionItem(
      id: 'm_streak_60',
      title: '60-Day Unstoppable Streak',
      description: 'Keep your fire streak alive for 60 days',
      metricType: 'streak',
      targetValue: 60,
      coinReward: 2500,
      expReward: 5000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _buildCatalogData();
    _loadPersistentState();
    _initAudioListeners();
    _startSecondBySecondExpAndUsageTracker();
  }

  // ==========================================================================
  // LEVEL & EXP CALCULATION (FREE FIRE STYLE SCALING)
  // ==========================================================================

  bool get _isDoubleExpActive =>
      _doubleExpEndTime != null && DateTime.now().isBefore(_doubleExpEndTime!);

  int get _currentLevel {
    int lv = 1;
    int expRemaining = _totalExp;
    while (true) {
      int needed = _expRequiredForLevel(lv);
      if (expRemaining >= needed) {
        expRemaining -= needed;
        lv++;
      } else {
        break;
      }
    }
    return lv;
  }

  int _expRequiredForLevel(int level) {
    // Increases with every level: Lv.1 needs 200 EXP, Lv.2 needs 350 EXP, Lv.3 needs 500 EXP...
    return 200 + (level - 1) * 150;
  }

  int get _expIntoCurrentLevel {
    int lv = 1;
    int expRemaining = _totalExp;
    while (true) {
      int needed = _expRequiredForLevel(lv);
      if (expRemaining >= needed) {
        expRemaining -= needed;
        lv++;
      } else {
        break;
      }
    }
    return expRemaining;
  }

  int get _expNeededForNextLevel => _expRequiredForLevel(_currentLevel);

  void _grantExp(int baseExp) {
    final earned = _isDoubleExpActive ? baseExp * 2 : baseExp;
    final oldLv = _currentLevel;
    setState(() {
      _totalExp += earned;
    });
    final newLv = _currentLevel;
    if (newLv > oldLv && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1DB954),
          content: Text(
            '🎉 LEVEL UP! You reached Lv.$newLv!',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  // Tracks active listening seconds to award 50 EXP per minute block (0-1m = 50, 1-2m = +50 -> 100 total, etc.)
  void _startSecondBySecondExpAndUsageTracker() {
    _listeningTrackerTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPlaying) return;
      _currentTrackSecondsListened++;

      // Check daily streak validation on active listening >= 1 second
      if (_currentTrackSecondsListened == 1) {
        _validateAndIncrementDailyStreak();
      }

      // Every 60 seconds of listening increases total usage minutes
      if (_currentTrackSecondsListened % 60 == 0) {
        setState(() {
          _totalUsageMinutes += 1;
        });
        _savePersistentState();
      }

      // 0s-60s = block 1 (+50 EXP), 61s-120s = block 2 (+50 EXP -> 100 total), etc.
      final currentMinuteBlock = ((_currentTrackSecondsListened - 1) ~/ 60) + 1;
      if (currentMinuteBlock > _lastAwardedMinuteBlock) {
        _lastAwardedMinuteBlock = currentMinuteBlock;
        _grantExp(50);
        _savePersistentState();
      }
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _validateAndIncrementDailyStreak() {
    final today = _todayKey();
    if (_lastActiveDateStr == today) return;

    if (_lastActiveDateStr.isNotEmpty) {
      final lastDate = DateTime.tryParse(_lastActiveDateStr);
      if (lastDate != null) {
        final diffDays = DateTime.now().difference(lastDate).inDays;
        if (diffDays == 1) {
          setState(() {
            _listeningStreak += 1;
            _lastActiveDateStr = today;
          });
        } else if (diffDays > 1) {
          setState(() {
            if (_listeningStreak > 0) {
              _previousStreakBeforeLoss = _listeningStreak;
            }
            _listeningStreak = 0;
            _lastActiveDateStr = today;
          });
        }
      }
    } else {
      setState(() {
        _listeningStreak = 1;
        _lastActiveDateStr = today;
      });
    }
    _savePersistentState();
  }

  // ==========================================================================
  // CATALOG DATA USING BUNDLED sample_track_1.mp3
  // ==========================================================================

  List<TrackItem> _generateSampleTracks(String prefix, String artistName) {
    return List.generate(6, (i) {
      return TrackItem(
        id: '${prefix}_track_$i',
        title: i == 0 ? 'Karol G (Hit Single)' : 'Track ${i + 1} ($prefix)',
        artist: i == 0 ? 'Karol G, Judeline, rusowsky' : artistName,
        assetPath: _bundledAssetPath,
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
        tracks: _generateSampleTracks(
            shortcutNames[i], i == 0 ? 'Karol G' : 'Iqbal'),
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
              final boxName = b == 0 && cycle == 0 && l == 0
                  ? 'Karol G Hits'
                  : '$lineTitle #${b + 1}';
              final artist =
                  artistNames[(currentLineIdx + b) % artistNames.length];
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

      _homeSections.add(
        HomeSection(
          id: 'featured_video_${cycle}_1',
          type: HomeSectionType.featuredVideo,
          title: 'Featured Episode',
          video: FeaturedVideoModel(
            id: 'vid_${cycle}_1',
            bannerHeadline: cycle == 0 ? 'Karol G Live' : 'Patandar',
            title: cycle == 0
                ? 'Karol G Global Tour Visualizer & Audio'
                : 'Deep Focus & Behind The Beats',
            channel: cycle == 0 ? 'Karol G' : 'Psyphoria',
            meta: 'Nov 19 • 240K+ plays',
            durationLabel: '27:11',
            colorValue: cycle == 0 ? 0xFFE8115B : 0xFF1B4D3E,
            audioTrack: TrackItem(
              id: 'vid_track_${cycle}_1',
              title: 'Karol G Special Podcast & Audio Mix',
              artist: 'Karol G',
              assetPath: _bundledAssetPath,
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
    return File('${dir.path}/music_app_persistent_v6.json');
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
        'hiddenTrackIds': _hiddenTrackIds.toList(),
        'excludedTrackIds': _excludedTrackIds.toList(),
        'settings': widget.settings.toJson(),
        'profile': _profile.toJson(),
        'coins': _coins,
        'totalExp': _totalExp,
        'listeningStreak': _listeningStreak,
        'previousStreakBeforeLoss': _previousStreakBeforeLoss,
        'lastActiveDateStr': _lastActiveDateStr,
        'dailyRewardDayIndex': _dailyRewardDayIndex,
        'lastDailyClaimDateStr': _lastDailyClaimDateStr,
        'streakSaverTokens': _streakSaverTokens,
        'doubleExpEndTime': _doubleExpEndTime?.toIso8601String(),
        'totalSongsListened': _totalSongsListened,
        'totalUsageMinutes': _totalUsageMinutes,
        'claimedMissionIds': _claimedMissionIds.toList(),
        'ownedCosmeticIds': _ownedCosmeticIds.toList(),
        'equippedBadgeId': _equippedBadgeId,
        'equippedFrameId': _equippedFrameId,
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
          _hiddenTrackIds =
              Set<String>.from(data['hiddenTrackIds'] ?? const []);
          _excludedTrackIds =
              Set<String>.from(data['excludedTrackIds'] ?? const []);
          if (data['settings'] != null) {
            widget.onSettingsChanged(AppSettings.fromJson(data['settings']));
          }
          if (data['profile'] != null) {
            _profile = UserProfileData.fromJson(data['profile']);
          }
          _coins = data['coins'] ?? 50;
          _totalExp = data['totalExp'] ?? 0;
          _listeningStreak = data['listeningStreak'] ?? 1;
          _previousStreakBeforeLoss = data['previousStreakBeforeLoss'] ?? 0;
          _lastActiveDateStr = data['lastActiveDateStr'] ?? '';
          _dailyRewardDayIndex = data['dailyRewardDayIndex'] ?? 1;
          _lastDailyClaimDateStr = data['lastDailyClaimDateStr'] ?? '';
          _streakSaverTokens = data['streakSaverTokens'] ?? 1;
          if (data['doubleExpEndTime'] != null) {
            _doubleExpEndTime = DateTime.tryParse(data['doubleExpEndTime']);
          }
          _totalSongsListened = data['totalSongsListened'] ?? 0;
          _totalUsageMinutes = data['totalUsageMinutes'] ?? 23;
          _claimedMissionIds =
              Set<String>.from(data['claimedMissionIds'] ?? const []);
          _ownedCosmeticIds = Set<String>.from(
              data['ownedCosmeticIds'] ?? const ['badge_wood', 'frame_wood']);
          _equippedBadgeId = data['equippedBadgeId'] ?? 'badge_wood';
          _equippedFrameId = data['equippedFrameId'] ?? 'frame_wood';
        });
      }
    } catch (_) {}
  }

  // ==========================================================================
  // AUDIO PLAYBACK (USING BUNDLED ASSET)
  // ==========================================================================

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed &&
          widget.settings.autoplay) {
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
    _listeningTrackerTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playTrack(TrackItem track,
      {List<TrackItem>? queue, bool openModal = true}) async {
    if (_excludedTrackIds.contains(track.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This track is excluded from your taste profile.')),
      );
      return;
    }
    try {
      await _audioPlayer.stop();
      setState(() {
        _currentPlayingTrack = track;
        _currentTrackSecondsListened = 0;
        _lastAwardedMinuteBlock = 0;
        _totalSongsListened += 1;
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

      // Plays directly from bundled root asset: sample_track_1.mp3
      await _audioPlayer.setAsset(track.assetPath);
      _audioPlayer.play();
      if (openModal && mounted) _openFullPlayerModal(track);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Playback error: $e')));
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

  bool _isLiked(TrackItem track) =>
      _likedSongs.any((item) => item.id == track.id);
  bool _isInPlaylist(TrackItem track) =>
      _playlist.any((item) => item.id == track.id);

  void _downloadTrack(TrackItem track) {
    if (!_downloads.any((t) => t.id == track.id)) {
      setState(() {
        track.isDownloaded = true;
        _downloads.add(track);
      });
      _savePersistentState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Downloaded "${track.title}" for offline playback')),
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
  // OPTIONS 3-DOTS MENU
  // ==========================================================================

  void _openTrack3DotsMenu(TrackItem track, {VoidCallback? onHide}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
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
                  title: Text(track.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1),
                  subtitle: Text(track.artist,
                      style: const TextStyle(color: Colors.white70)),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Share.share(
                        'Listening to ${track.title} by ${track.artist}!');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: Text(_isInPlaylist(track)
                      ? 'Remove from playlist'
                      : 'Add to playlist'),
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
                      SnackBar(
                          content:
                              Text('Hidden "${track.title}" from this album')),
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
                      SnackBar(
                          content: Text(
                              'Excluded "${track.title}" from your taste profile')),
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
                        content: Text(
                            'Artist: ${track.artist}\nPlays: ${track.playsCount}\nSource: Bundled Offline Asset (${track.assetPath})'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('Close'))
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
            const Text('Playback Queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _playbackQueue.isEmpty
                  ? const Center(
                      child: Text('Queue is empty.',
                          style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      itemCount: _playbackQueue.length,
                      itemBuilder: (context, idx) {
                        final t = _playbackQueue[idx];
                        return ListTile(
                          title: Text(t.title, maxLines: 1),
                          subtitle: Text(t.artist),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
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
                        if (t.title.toLowerCase().contains(q) ||
                            t.artist.toLowerCase().contains(q)) {
                          if (!searchResults.any((x) => x.id == t.id)) {
                            searchResults.add(t);
                          }
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
                        if (!artistResults.any((x) => x.id == c.id)) {
                          artistResults.add(c);
                        }
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
                  ? const Center(
                      child: Text('Type to search across all boxes and podcasts',
                          style: TextStyle(color: Colors.white54)))
                  : (searchResults.isEmpty && artistResults.isEmpty)
                      ? const Center(
                          child: Text('No results found',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (artistResults.isNotEmpty) ...[
                              const Text('Artists',
                                  style: TextStyle(
                                      color: Color(0xFF1DB954),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              ...artistResults.map((artist) => ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor:
                                            Color(artist.colorValue),
                                        child: const Icon(Icons.person)),
                                    title: Text(artist.name,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    subtitle: Text(artist.monthlyListeners,
                                        style: const TextStyle(
                                            color: Colors.white60)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _openCircleArtistScreen(artist);
                                    },
                                  )),
                              const SizedBox(height: 16),
                            ],
                            if (searchResults.isNotEmpty) ...[
                              const Text('Songs & Audio',
                                  style: TextStyle(
                                      color: Color(0xFF1DB954),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              ...searchResults.map((track) => ListTile(
                                    leading: const Icon(Icons.music_note,
                                        color: Colors.white),
                                    title: Text(track.title,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    subtitle: Text(track.artist,
                                        style: const TextStyle(
                                            color: Colors.white60)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _playTrack(track,
                                          queue: searchResults,
                                          openModal: true);
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
  // SETTINGS, FEEDBACK & EQUALIZER
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
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide Feedback',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name*', hintText: 'Enter your name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject*', hintText: 'Enter subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Feedback*',
                    hintText: 'Write your feedback here...'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954)),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty ||
                        subjectCtrl.text.trim().isEmpty ||
                        feedbackCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill all required fields')),
                      );
                      return;
                    }
                    nameCtrl.clear();
                    subjectCtrl.clear();
                    feedbackCtrl.clear();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submitted successfully')),
                    );
                  },
                  child: const Text('Submit',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                      const Text('Powerful Equalizer',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Switch(
                        value: widget.settings.equalizerEnabled,
                        activeColor: const Color(0xFF1DB954),
                        onChanged: (val) {
                          widget.onSettingsChanged(AppSettings(
                            privateSession: widget.settings.privateSession,
                            publicPlaylists: widget.settings.publicPlaylists,
                            gaplessPlayback: widget.settings.gaplessPlayback,
                            autoplay: widget.settings.autoplay,
                            pushNotifications:
                                widget.settings.pushNotifications,
                            streamingQuality: widget.settings.streamingQuality,
                            downloadQuality: widget.settings.downloadQuality,
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
                    children: List.generate(
                      5,
                      (i) => SizedBox(
                        height: 100,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: 3.0 + (i * 1.5),
                            min: -15.0,
                            max: 15.0,
                            activeColor: Colors.amber,
                            onChanged: widget.settings.equalizerEnabled
                                ? (_) {}
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('BASS',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: bassVal,
                            min: 0,
                            max: 10,
                            activeColor: Colors.amber,
                            onChanged: widget.settings.equalizerEnabled
                                ? (v) => setEqState(() => bassVal = v)
                                : null,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('VIRTUALIZER',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: virtualizerVal,
                            min: 0,
                            max: 10,
                            activeColor: Colors.amber,
                            onChanged: widget.settings.equalizerEnabled
                                ? (v) => setEqState(() => virtualizerVal = v)
                                : null,
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
              const Text('All-Time Usage & Insights',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Minutes listened',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('$_totalUsageMinutes',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Songs played',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text('$_totalSongsListened',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
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

            final isLight = widget.settings.themeMode == 'Light';
            return Scaffold(
              backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor:
                    isLight ? Colors.white : const Color(0xFF121212),
                title: Text('Settings',
                    style: TextStyle(
                        color: isLight ? Colors.black : Colors.white)),
                iconTheme: IconThemeData(
                    color: isLight ? Colors.black : Colors.white),
              ),
              body: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined, size: 28),
                    title: const Text('Theme',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Current: ${widget.settings.themeMode} Theme'),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF1E1E1E),
                        builder: (bCtx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ['System Theme', 'Light']
                              .map((t) => ListTile(
                                    title: Text(t),
                                    trailing: (t == 'System Theme' &&
                                                widget.settings.themeMode ==
                                                    'Dark') ||
                                            (t == 'Light' &&
                                                widget.settings.themeMode ==
                                                    'Light')
                                        ? const Icon(Icons.check,
                                            color: Color(0xFF1DB954))
                                        : null,
                                    onTap: () {
                                      updateSetting(() {
                                        widget.settings.themeMode =
                                            t == 'System Theme'
                                                ? 'Dark'
                                                : 'Light';
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
                  ListTile(
                    leading: const Icon(Icons.equalizer, size: 28),
                    title: const Text('Equalizer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Powerful frequency adjustment & bass boost'),
                    onTap: () => _openEqualizerScreen(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, size: 28),
                    title: const Text('Listening stats',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'All-time usage recorded: $_totalUsageMinutes minutes'),
                    onTap: () => _openListeningStatsScreen(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined, size: 28),
                    title: const Text('Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Send name, subject, and feedback'),
                    onTap: () => _openFeedbackScreen(),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.lock_outline, size: 28),
                    title: const Text('Private session',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Listen anonymously without history'),
                    value: widget.settings.privateSession,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) =>
                        updateSetting(() => widget.settings.privateSession = val),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined, size: 28),
                    title: const Text('Autoplay',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Automatically play next song in queue'),
                    value: widget.settings.autoplay,
                    activeColor: const Color(0xFF1DB954),
                    onChanged: (val) =>
                        updateSetting(() => widget.settings.autoplay = val),
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
  // BOX & ARTIST DETAIL SCREENS (WITH HERO EXPANSION)
  // ==========================================================================

  void _openBoxDetailScreen(BoxModel box) {
    final tracks =
        box.tracks.where((t) => !_hiddenTrackIds.contains(t.id)).toList();
    final isLight = widget.settings.themeMode == 'Light';

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: StatefulBuilder(
            builder: (context, setPageState) {
              final visibleTracks = tracks
                  .where((t) => !_hiddenTrackIds.contains(t.id))
                  .toList();
              return Scaffold(
                backgroundColor:
                    isLight ? Colors.white : const Color(0xFF121212),
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
                              colors: [
                                Color(box.colorValue),
                                isLight ? Colors.white : const Color(0xFF121212)
                              ],
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
                                child: const Center(
                                    child: Icon(Icons.album,
                                        size: 70, color: Colors.white)),
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
                            Text(box.name,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isLight ? Colors.black : Colors.white)),
                            const SizedBox(height: 6),
                            Text(box.description,
                                style: TextStyle(
                                    color: isLight
                                        ? Colors.black54
                                        : Colors.white70,
                                    fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_circle_down_outlined,
                                      size: 30,
                                      color: isLight
                                          ? Colors.black54
                                          : Colors.white70),
                                  onPressed: () {
                                    for (var t in visibleTracks) {
                                      _downloadTrack(t);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.share,
                                      size: 26,
                                      color: isLight
                                          ? Colors.black54
                                          : Colors.white70),
                                  onPressed: () =>
                                      Share.share('Listen to ${box.name}'),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    if (visibleTracks.isNotEmpty) {
                                      _playTrack(visibleTracks.first,
                                          queue: visibleTracks,
                                          openModal: true);
                                    }
                                  },
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF1DB954),
                                        shape: BoxShape.circle),
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
                          final track = visibleTracks[index];
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
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            ),
                            title: Text(track.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isLight ? Colors.black : Colors.white),
                                maxLines: 1),
                            subtitle: Text(track.artist,
                                style: TextStyle(
                                    color: isLight
                                        ? Colors.black54
                                        : Colors.white60)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    inPlaylist
                                        ? Icons.check_circle
                                        : Icons.playlist_add,
                                    color: inPlaylist
                                        ? const Color(0xFF1DB954)
                                        : (isLight
                                            ? Colors.black45
                                            : Colors.white54),
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
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: liked
                                          ? Colors.redAccent
                                          : (isLight
                                              ? Colors.black45
                                              : Colors.white54),
                                      size: 22,
                                    ),
                                  ),
                                  onPressed: () {
                                    _toggleLike(track);
                                    setPageState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.more_vert,
                                      color: isLight
                                          ? Colors.black45
                                          : Colors.white60),
                                  onPressed: () => _openTrack3DotsMenu(track,
                                      onHide: () => setPageState(() {})),
                                ),
                              ],
                            ),
                            onTap: () => _playTrack(track,
                                queue: visibleTracks, openModal: true),
                          );
                        },
                        childCount: visibleTracks.length,
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
    final isLight = widget.settings.themeMode == 'Light';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: StatefulBuilder(
            builder: (context, setPageState) {
              final isFollowing = _followedArtists.contains(artist.id);
              return Scaffold(
                backgroundColor:
                    isLight ? Colors.white : const Color(0xFF121212),
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 260,
                      pinned: true,
                      backgroundColor: Color(artist.colorValue),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(artist.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(artist.colorValue),
                                isLight ? Colors.white : const Color(0xFF121212)
                              ],
                            ),
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'circle_${artist.id}',
                              child: const CircleAvatar(
                                  radius: 60,
                                  child: Icon(Icons.person, size: 70)),
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
                                    foregroundColor:
                                        isLight ? Colors.black : Colors.white,
                                    side: BorderSide(
                                        color: isFollowing
                                            ? const Color(0xFF1DB954)
                                            : Colors.white54),
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
                                  child:
                                      Text(isFollowing ? 'Following' : 'Follow'),
                                ),
                                const Spacer(),
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
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.black, size: 32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Popular',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isLight ? Colors.black : Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = artist.popularTracks[index];
                          return ListTile(
                            leading: Text('${index + 1}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isLight ? Colors.black : Colors.white)),
                            title: Text(track.title,
                                style: TextStyle(
                                    color:
                                        isLight ? Colors.black : Colors.white),
                                maxLines: 1),
                            subtitle: Text(track.playsCount,
                                style: TextStyle(
                                    color: isLight
                                        ? Colors.black54
                                        : Colors.white60)),
                            onTap: () => _playTrack(track,
                                queue: artist.popularTracks, openModal: true),
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

  // ==========================================================================
  // FULL PLAYER MODAL (WITH SLIDER, LYRICS & BEAT ANIMATION)
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
            final maxDur = _duration.inSeconds.toDouble() > 0
                ? _duration.inSeconds.toDouble()
                : 1.0;
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
                      const Text('PLAYING FROM OFFLINE ASSET',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
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
                          const Icon(Icons.album,
                              size: 120, color: Colors.white24),
                          if (_isPlaying)
                            Positioned(
                              bottom: 24,
                              child: Row(
                                children: List.generate(
                                  5,
                                  (i) => AnimatedContainer(
                                    duration:
                                        Duration(milliseconds: 200 + i * 80),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: 4,
                                    height: 14.0 + (i % 3) * 14,
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
                            Text(activeTrack.title,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                                maxLines: 1),
                            const SizedBox(height: 4),
                            Text(activeTrack.artist,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white60)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          inPlaylist
                              ? Icons.check_circle
                              : Icons.playlist_add,
                          color: inPlaylist
                              ? const Color(0xFF1DB954)
                              : Colors.white70,
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
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
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
                                  Text('Synced Lyrics - ${activeTrack.title}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  const Text(
                                      'They say we’re too young\nTo get ourselves sprung\nOh we didn’t care\nWe made it very clear...',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          height: 1.5)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white),
                        onPressed: () => _playPreviousInQueue(),
                      ),
                      IconButton(
                        iconSize: 68,
                        icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white),
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
                        icon: const Icon(Icons.queue_music,
                            color: Colors.white70),
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
  // TAB 1: HOME TAB
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_listeningStreak == 0 &&
                        _previousStreakBeforeLoss > 0) {
                      _showStreakSaverDialog();
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('$_listeningStreak',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
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
                            onSelected: (_) =>
                                setState(() => _selectedCategoryFilter = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'History',
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => Scaffold(
                          appBar: AppBar(title: const Text('Recents')),
                          body: _recents.isEmpty
                              ? const Center(
                                  child: Text('No recently played songs.',
                                      style: TextStyle(color: Colors.white60)))
                              : ListView.builder(
                                  itemCount: _recents.length,
                                  itemBuilder: (context, i) {
                                    final t = _recents[i];
                                    return ListTile(
                                      title: Text(t.title),
                                      subtitle: Text(
                                          '${t.artist} • ${_formatPlayedDate(t.playedAt)}'),
                                      onTap: () =>
                                          _playTrack(t, openModal: true),
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
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: _openSettingsScreen,
                ),
              ],
            ),
          ),
        ),
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
                          child: Icon(
                              index == 0 ? Icons.search : Icons.music_note,
                              color: Colors.white,
                              size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shortcut.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
          child: Text(section.title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
                            child: Icon(Icons.album,
                                size: 52, color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(box.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1),
                      Text(box.subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white60),
                          maxLines: 1),
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
          child: Text(section.title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
                            child: const Icon(Icons.person, size: 50)),
                      ),
                      const SizedBox(height: 8),
                      Text(artist.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          textAlign: TextAlign.center),
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
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 195,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(video.colorValue), Colors.black87],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        video.bannerHeadline,
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(video.durationLabel,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Color(video.colorValue),
                    child: const Icon(Icons.podcasts)),
                title: Text(video.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white),
                    maxLines: 2),
                subtitle: Text('${video.channel} • ${video.meta}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _openTrack3DotsMenu(video.audioTrack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: YOUR PLAYLIST & LIBRARY TAB
  // ==========================================================================

  Widget _buildPlaylistLibraryTab() {
    final isLight = widget.settings.themeMode == 'Light';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
          title: Text('Your Playlist & Library',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.black : Colors.white)),
          bottom: TabBar(
            indicatorColor: const Color(0xFF1DB954),
            labelColor: isLight ? Colors.black : Colors.white,
            tabs: const [
              Tab(text: 'My Playlist'),
              Tab(text: 'Liked Songs'),
              Tab(text: 'Downloads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTrackListSection(
                _playlist,
                'Playlist is empty.',
                (t) => setState(
                    () => _playlist.removeWhere((x) => x.id == t.id))),
            _buildTrackListSection(
                _likedSongs, 'No Liked Songs.', (t) => _toggleLike(t)),
            _buildTrackListSection(
                _downloads,
                'No Downloaded Songs.',
                (t) => setState(
                    () => _downloads.removeWhere((x) => x.id == t.id))),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackListSection(List<TrackItem> tracks, String emptyMsg,
      Function(TrackItem) onRemove) {
    final isLight = widget.settings.themeMode == 'Light';
    if (tracks.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyMsg,
                  style: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white60))));
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
                borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(track.title,
              style: TextStyle(color: isLight ? Colors.black : Colors.white),
              maxLines: 1),
          subtitle: Text(track.artist,
              style:
                  TextStyle(color: isLight ? Colors.black54 : Colors.white60)),
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
  // TAB 3: QUESTS TAB (DAILY REWARDS, MYSTERY BOX, LONG MISSIONS, EXCHANGE)
  // ==========================================================================

  void _claimDailyReward(int day) {
    final today = _todayKey();
    if (_lastDailyClaimDateStr == today) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Today\'s reward is already claimed! Come back tomorrow.')),
      );
      return;
    }
    if (day != _dailyRewardDayIndex) return;

    setState(() {
      _lastDailyClaimDateStr = today;
      if (day < 7) {
        final rewardCoins = day * 10; // Day 1=10, Day 2=20 ... Day 6=60
        _coins += rewardCoins;
        _dailyRewardDayIndex += 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: const Color(0xFF1DB954),
              content: Text('Claimed Day $day Reward: +$rewardCoins Coins! 🪙',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold))),
        );
      } else {
        // Day 7 Mystery Box!
        _coins += 200;
        _streakSaverTokens += 1;
        _doubleExpEndTime = DateTime.now().add(const Duration(hours: 24));
        _dailyRewardDayIndex = 1; // Cycle resets for next week
        _showMysteryBoxOpenedDialog();
      }
    });
    _savePersistentState();
  }

  void _showMysteryBoxOpenedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text('Day 7 Mystery Box!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('You unlocked grand rewards:',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.monetization_on, color: Colors.amber),
              title: Text('+200 Bonus Coins'),
            ),
            ListTile(
              leading: Icon(Icons.bolt, color: Color(0xFF1DB954)),
              title: Text('2x EXP Booster (24 Hours)'),
            ),
            ListTile(
              leading: Icon(Icons.shield, color: Colors.lightBlueAccent),
              title: Text('+1 Streak Saver Token'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome!',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showStreakSaverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Restore Lost Streak? 🔥'),
        content: Text(
          'Your previous streak of $_previousStreakBeforeLoss days reset to 0 because you missed a day.\n\nStreak Saver Tokens available: $_streakSaverTokens',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954)),
            onPressed: _streakSaverTokens > 0
                ? () {
                    setState(() {
                      _streakSaverTokens -= 1;
                      _listeningStreak = _previousStreakBeforeLoss;
                      _previousStreakBeforeLoss = 0;
                    });
                    _savePersistentState();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '🔥 Streak restored to $_listeningStreak days!')),
                    );
                  }
                : null,
            child: const Text('Use Streak Saver',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  int _getMissionProgress(MissionItem mission) {
    switch (mission.metricType) {
      case 'songs':
        return _totalSongsListened;
      case 'minutes':
        return _totalUsageMinutes;
      case 'streak':
        return _listeningStreak;
      default:
        return 0;
    }
  }

  Widget _buildQuestsTab() {
    final isLight = widget.settings.themeMode == 'Light';
    final alreadyClaimedToday = _lastDailyClaimDateStr == _todayKey();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
          title: Row(
            children: [
              Text('Quests & Rewards',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLight ? Colors.black : Colors.white)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('$_coins',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              ),
            ],
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF1DB954),
            labelColor: isLight ? Colors.black : Colors.white,
            tabs: const [
              // Calendar + Star custom Daily Rewards icon
              Tab(
                icon: Icon(Icons.event_available),
                text: 'Daily Rewards',
              ),
              // Target Bullseye Missions icon
              Tab(
                icon: Icon(Icons.track_changes),
                text: 'Missions',
              ),
              // Swap Arrows Exchange icon
              Tab(
                icon: Icon(Icons.swap_horiz),
                text: 'Exchange',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Sub-tab 1: 7-Day Daily Rewards
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                if (_previousStreakBeforeLoss > 0 && _listeningStreak == 0)
                  Card(
                    color: Colors.redAccent.withOpacity(0.2),
                    child: ListTile(
                      leading: const Icon(Icons.local_fire_department,
                          color: Colors.orange),
                      title: Text(
                          'Restore your $_previousStreakBeforeLoss-day streak!'),
                      subtitle: Text(
                          'You have $_streakSaverTokens Streak Saver token(s)'),
                      trailing: ElevatedButton(
                        onPressed: _showStreakSaverDialog,
                        child: const Text('Restore'),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('7-Day Login & Listen Rewards',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    Chip(
                      label: Text('Tokens: $_streakSaverTokens 🛡️'),
                      backgroundColor: Colors.blueGrey.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isDoubleExpActive)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF1DB954)),
                        SizedBox(width: 8),
                        Text('2x EXP Booster is ACTIVE!',
                            style: TextStyle(
                                color: Color(0xFF1DB954),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, idx) {
                    final day = idx + 1;
                    final isTodayTarget =
                        day == _dailyRewardDayIndex && !alreadyClaimedToday;
                    final isCompleted = day < _dailyRewardDayIndex ||
                        (day == _dailyRewardDayIndex && alreadyClaimedToday);
                    final isMysteryBox = day == 7;

                    return GestureDetector(
                      onTap:
                          isTodayTarget ? () => _claimDailyReward(day) : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTodayTarget
                              ? const Color(0xFF1DB954).withOpacity(0.22)
                              : const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTodayTarget
                                ? const Color(0xFF1DB954)
                                : (isMysteryBox
                                    ? Colors.amber
                                    : Colors.white12),
                            width: isTodayTarget ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Day $day',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70)),
                            const SizedBox(height: 6),
                            Icon(
                              isMysteryBox
                                  ? Icons.card_giftcard
                                  : Icons.monetization_on,
                              color: isMysteryBox
                                  ? Colors.amber
                                  : Colors.amberAccent,
                              size: 30,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isMysteryBox
                                  ? 'Mystery Box'
                                  : '+${day * 10} Coins',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCompleted
                                  ? 'Claimed ✓'
                                  : (isTodayTarget ? 'TAP TO CLAIM' : 'Locked'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? const Color(0xFF1DB954)
                                    : (isTodayTarget
                                        ? Colors.amber
                                        : Colors.white38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Sub-tab 2: Long-Term Missions
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: _longTermMissions.length,
              itemBuilder: (context, idx) {
                final m = _longTermMissions[idx];
                final current = _getMissionProgress(m);
                final isClaimed = _claimedMissionIds.contains(m.id);
                final canClaim = !isClaimed && current >= m.targetValue;
                final progressRatio =
                    (current / m.targetValue).clamp(0.0, 1.0);

                return Card(
                  color: const Color(0xFF202020),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.track_changes,
                                color: Color(0xFF1DB954)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(m.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white)),
                            ),
                            Text('+${m.coinReward} 🪙  +${m.expReward} EXP',
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(m.description,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progressRatio,
                          backgroundColor: Colors.white12,
                          color: const Color(0xFF1DB954),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${current.clamp(0, m.targetValue)} / ${m.targetValue}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isClaimed
                                    ? Colors.grey
                                    : (canClaim
                                        ? const Color(0xFF1DB954)
                                        : Colors.white12),
                              ),
                              onPressed: canClaim
                                  ? () {
                                      setState(() {
                                        _claimedMissionIds.add(m.id);
                                        _coins += m.coinReward;
                                      });
                                      _grantExp(m.expReward);
                                      _savePersistentState();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Mission Completed! +${m.coinReward} Coins & +${m.expReward} EXP')),
                                      );
                                    }
                                  : null,
                              child: Text(
                                isClaimed
                                    ? 'Completed ✓'
                                    : (canClaim ? 'Claim Reward' : 'In Progress'),
                                style: TextStyle(
                                    color:
                                        canClaim ? Colors.black : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Sub-tab 3: Exchange Store (Badges & Avatar Frames)
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: _shopItems.length,
              itemBuilder: (context, idx) {
                final item = _shopItems[idx];
                final isOwned = _ownedCosmeticIds.contains(item.id);
                final isEquipped = item.type == 'badge'
                    ? _equippedBadgeId == item.id
                    : _equippedFrameId == item.id;

                return Card(
                  color: const Color(0xFF202020),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.primaryColor.withOpacity(0.25),
                      child: Icon(item.icon, color: item.primaryColor),
                    ),
                    title: Text('${item.name} (${item.tier})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                        item.type == 'badge'
                            ? 'Profile Badge'
                            : 'Avatar Border Frame',
                        style: const TextStyle(color: Colors.white60)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEquipped
                            ? Colors.blueGrey
                            : (isOwned
                                ? const Color(0xFF1DB954)
                                : Colors.amber),
                      ),
                      onPressed: () {
                        if (isOwned) {
                          setState(() {
                            if (item.type == 'badge') {
                              _equippedBadgeId = item.id;
                            } else {
                              _equippedFrameId = item.id;
                            }
                          });
                          _savePersistentState();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Equipped ${item.name}!')),
                          );
                        } else if (_coins >= item.cost) {
                          setState(() {
                            _coins -= item.cost;
                            _ownedCosmeticIds.add(item.id);
                            if (item.type == 'badge') {
                              _equippedBadgeId = item.id;
                            } else {
                              _equippedFrameId = item.id;
                            }
                          });
                          _savePersistentState();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Purchased & Equipped ${item.name}!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Need ${item.cost - _coins} more coins!')),
                          );
                        }
                      },
                      child: Text(
                        isEquipped
                            ? 'Equipped'
                            : (isOwned ? 'Equip' : '${item.cost} 🪙'),
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: PROFILE TAB (CREATE PROFILE, AVATAR PICKER, LV.X, FRAMES & BADGES)
  // ==========================================================================

  ShopCosmeticItem get _currentBadge => _shopItems.firstWhere(
      (i) => i.id == _equippedBadgeId,
      orElse: () => _shopItems.first);

  ShopCosmeticItem get _currentFrame => _shopItems.firstWhere(
      (i) => i.id == _equippedFrameId,
      orElse: () => _shopItems[5]);

  void _openJioHotstarAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Choose Your Avatar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() => _profile.selectedAvatarIndex = null);
                      _savePersistentState();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Use Name Initial',
                        style: TextStyle(color: Color(0xFF1DB954))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _avatarCatalog.length,
                  itemBuilder: (context, idx) {
                    final av = _avatarCatalog[idx];
                    final isSelected = _profile.selectedAvatarIndex == idx;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _profile.selectedAvatarIndex = idx);
                        _savePersistentState();
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1DB954)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Color(av['bg'] as int),
                              child: Icon(av['icon'] as IconData,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(av['name'] as String,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
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

  void _openCreateOrEditProfileForm() {
    final firstCtrl = TextEditingController(text: _profile.firstName);
    final lastCtrl = TextEditingController(text: _profile.lastName);
    final emailCtrl = TextEditingController(text: _profile.email);
    final phoneCtrl = TextEditingController(text: _profile.phone);
    final cityCtrl = TextEditingController(text: _profile.city);
    final addressCtrl = TextEditingController(text: _profile.address);

    bool errFirst = false;
    bool errLast = false;
    bool errEmail = false;
    bool errPhone = false;
    bool errCity = false;
    bool errAddress = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setFormState) {
            InputDecoration buildFieldDeco(String label, bool hasError) {
              return InputDecoration(
                labelText: label,
                errorText: hasError ? 'Required field' : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: hasError ? Colors.redAccent : Colors.white24,
                      width: hasError ? 2 : 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: hasError
                          ? Colors.redAccent
                          : const Color(0xFF1DB954),
                      width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.redAccent, width: 2),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Your Profile',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: firstCtrl,
                      decoration: buildFieldDeco('First Name *', errFirst),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastCtrl,
                      decoration: buildFieldDeco('Last Name *', errLast),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: buildFieldDeco('Email Address *', errEmail),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: buildFieldDeco('Phone Number *', errPhone),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: buildFieldDeco('City *', errCity),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: buildFieldDeco('Full Address *', errAddress),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954)),
                        onPressed: () {
                          setFormState(() {
                            errFirst = firstCtrl.text.trim().isEmpty;
                            errLast = lastCtrl.text.trim().isEmpty;
                            errEmail = emailCtrl.text.trim().isEmpty;
                            errPhone = phoneCtrl.text.trim().isEmpty;
                            errCity = cityCtrl.text.trim().isEmpty;
                            errAddress = addressCtrl.text.trim().isEmpty;
                          });

                          if (errFirst ||
                              errLast ||
                              errEmail ||
                              errPhone ||
                              errCity ||
                              errAddress) {
                            return;
                          }

                          setState(() {
                            _profile.firstName = firstCtrl.text.trim();
                            _profile.lastName = lastCtrl.text.trim();
                            _profile.email = emailCtrl.text.trim();
                            _profile.phone = phoneCtrl.text.trim();
                            _profile.city = cityCtrl.text.trim();
                            _profile.address = addressCtrl.text.trim();
                            _profile.isCreated = true;
                          });
                          _savePersistentState();
                          Navigator.pop(ctx);
                          _showBigTickSuccessDialog();
                        },
                        child: const Text('Save Profile',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
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

  void _showBigTickSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFF1DB954),
                child: Icon(Icons.check, size: 54, color: Colors.black),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Profile created successfully',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final isLight = widget.settings.themeMode == 'Light';
    final frame = _currentFrame;
    final badge = _currentBadge;
    final avatarData = _profile.selectedAvatarIndex != null &&
            _profile.selectedAvatarIndex! < _avatarCatalog.length
        ? _avatarCatalog[_profile.selectedAvatarIndex!]
        : null;

    return Scaffold(
      backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : const Color(0xFF121212),
        title: Text('Profile',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black : Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: isLight ? Colors.black : Colors.white),
            onPressed: _openSettingsScreen,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          // Avatar with Equipped Frame + Photo Picker + Level Pill (Lv.1, Lv.2...)
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Equipped Frame Border
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [frame.primaryColor, frame.secondaryColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: frame.primaryColor.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: avatarData != null
                            ? Color(avatarData['bg'] as int)
                            : const Color(0xFF5B9BD5),
                        child: avatarData != null
                            ? Icon(avatarData['icon'] as IconData,
                                size: 52, color: Colors.white)
                            : Text(
                                _profile.initialLetter,
                                style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                      ),
                    ),
                    // JioHotstar Photo/Avatar Edit Button
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _openJioHotstarAvatarPicker,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.black),
                        ),
                      ),
                    ),
                    // Free Fire Style Level Badge (Hold to see EXP needed!)
                    Positioned(
                      top: -4,
                      left: -14,
                      child: GestureDetector(
                        onLongPress: () {
                          final remaining =
                              _expNeededForNextLevel - _expIntoCurrentLevel;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF202020),
                              title: Text('Level $_currentLevel Progress'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total EXP Earned: $_totalExp EXP'),
                                  const SizedBox(height: 6),
                                  Text(
                                      'Current Level EXP: $_expIntoCurrentLevel / $_expNeededForNextLevel EXP'),
                                  const SizedBox(height: 6),
                                  Text(
                                    'EXP Needed for Lv.${_currentLevel + 1}: $remaining EXP',
                                    style: const TextStyle(
                                        color: Color(0xFF1DB954),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'))
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Text(
                            'Lv.$_currentLevel',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _profile.displayName,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isLight ? Colors.black : Colors.white),
                ),
                const SizedBox(height: 4),
                const Text('Hold Lv badge to view EXP required for next level',
                    style: TextStyle(fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 10),
                // Equipped Badge & Frame Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(badge.icon,
                          color: badge.primaryColor, size: 18),
                      label: Text(badge.name),
                      backgroundColor: badge.primaryColor.withOpacity(0.18),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: Icon(frame.icon,
                          color: frame.primaryColor, size: 18),
                      label: Text(frame.name),
                      backgroundColor: frame.primaryColor.withOpacity(0.18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Create Your Profile / Edit Profile Card
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(_profile.isCreated ? Icons.edit : Icons.person_add,
                  color: Colors.black),
              label: Text(
                _profile.isCreated ? 'Edit Your Profile' : 'Create Your Profile',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              onPressed: _openCreateOrEditProfileForm,
            ),
          ),

          if (_profile.isCreated) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saved Profile Details',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1DB954))),
                  const Divider(color: Colors.white12),
                  _profileDetailRow(
                      'Full Name', '${_profile.firstName} ${_profile.lastName}'),
                  _profileDetailRow('Email', _profile.email),
                  _profileDetailRow('Phone', _profile.phone),
                  _profileDetailRow('City', _profile.city),
                  _profileDetailRow('Address', _profile.address),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 95,
              child: Text('$label:',
                  style: const TextStyle(color: Colors.white60))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }

  // ==========================================================================
  // MAIN SCAFFOLD WITH 4 ANIMATED BOTTOM TABS
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final isLight = widget.settings.themeMode == 'Light';
    Widget activePage;
    switch (_currentTabIndex) {
      case 0:
        activePage = _buildHomeTab();
        break;
      case 1:
        activePage = _buildPlaylistLibraryTab();
        break;
      case 2:
        activePage = _buildQuestsTab();
        break;
      case 3:
      default:
        activePage = _buildProfileTab();
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: activePage,
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
                                borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_currentPlayingTrack!.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white),
                                    maxLines: 1),
                                Text(_currentPlayingTrack!.artist,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                    maxLines: 1),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isLiked(_currentPlayingTrack!)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isLiked(_currentPlayingTrack!)
                                  ? Colors.redAccent
                                  : Colors.white,
                            ),
                            onPressed: () =>
                                _toggleLike(_currentPlayingTrack!),
                          ),
                          IconButton(
                            icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 28),
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
          Container(
            color: isLight ? Colors.white : const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavTabItem(
                    0, Icons.home_outlined, Icons.home_filled, 'Home'),
                _buildNavTabItem(1, Icons.library_music_outlined,
                    Icons.library_music, 'Playlist'),
                _buildNavTabItem(
                    2, Icons.event_available_outlined, Icons.event_available, 'Quests'),
                _buildNavTabItem(
                    3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabItem(
      int index, IconData iconOutlined, IconData iconFilled, String label) {
    final selected = _currentTabIndex == index;
    final isLight = widget.settings.themeMode == 'Light';
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isLight ? Colors.black12 : Colors.white24)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(selected ? iconFilled : iconOutlined,
                size: 20, color: isLight ? Colors.black : Colors.white),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.black : Colors.white,
                ),
              ),
            ],
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
