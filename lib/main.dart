import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final FlutterLocalNotificationsPlugin _notifsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifsPlugin.initialize(
    const InitializationSettings(android: androidInit),
  );
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
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? 'Unknown Title').toString(),
        artist: (json['artist'] ?? 'Unknown Artist').toString(),
        assetPath: (json['assetPath'] ?? 'sample_track_1.mp3').toString(),
        playsCount: (json['playsCount'] ?? '71,297,233').toString(),
        playedAt: json['playedAt'] != null
            ? DateTime.tryParse(json['playedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isDownloaded: json['isDownloaded'] == true,
      );
}

class BoxModel {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final int colorValue;
  final bool useGreenMusicLogo;
  final List<TrackItem> tracks;

  BoxModel({
    required this.id,
    required this.name,
    this.subtitle = 'Playlist',
    this.description =
        'Curated collection ready for your repository or custom audio tracks.',
    required this.colorValue,
    this.useGreenMusicLogo = false,
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

class AvatarPreset {
  final String id;
  final String label;
  final Color bgStart;
  final Color bgEnd;
  final String badgeText;
  final IconData icon;

  const AvatarPreset({
    required this.id,
    required this.label,
    required this.bgStart,
    required this.bgEnd,
    required this.badgeText,
    required this.icon,
  });
}

class UserProfileData {
  String firstName;
  String lastName;
  String birthday;
  String city;
  String address;
  String avatarId;
  bool isCreated;

  UserProfileData({
    this.firstName = '',
    this.lastName = '',
    this.birthday = '',
    this.city = '',
    this.address = '',
    this.avatarId = 'avatar_kids',
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
        'birthday': birthday,
        'city': city,
        'address': address,
        'avatarId': avatarId,
        'isCreated': isCreated,
      };

  factory UserProfileData.fromJson(Map<String, dynamic> json) =>
      UserProfileData(
        firstName: (json['firstName'] ?? '').toString(),
        lastName: (json['lastName'] ?? '').toString(),
        birthday: (json['birthday'] ?? json['email'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        avatarId: (json['avatarId'] ?? 'avatar_kids').toString(),
        isCreated: json['isCreated'] == true,
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
  String themeMode;
  bool equalizerEnabled;
  double volumeBoost;

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
    this.volumeBoost = 1.25,
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
        'volumeBoost': volumeBoost,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        privateSession: json['privateSession'] == true,
        publicPlaylists: json['publicPlaylists'] != false,
        gaplessPlayback: json['gaplessPlayback'] != false,
        autoplay: json['autoplay'] != false,
        pushNotifications: json['pushNotifications'] != false,
        streamingQuality: (json['streamingQuality'] ?? 'High').toString(),
        downloadQuality: (json['downloadQuality'] ?? 'Very High').toString(),
        themeMode: (json['themeMode'] ?? 'Dark').toString(),
        equalizerEnabled: json['equalizerEnabled'] != false,
        volumeBoost: (json['volumeBoost'] as num?)?.toDouble() ?? 1.25,
      );
}

class ShopCosmeticItem {
  final String id;
  final String name;
  final String tier;
  final String type;
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
  final String metricType;
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
    final mode = _settings.themeMode;
    final isLight = mode == 'Light';
    final isNeon = mode == 'Neon';
    final isMidnight = mode == 'Midnight';

    final bgColor = isLight
        ? Colors.white
        : isNeon
            ? const Color(0xFF070514)
            : isMidnight
                ? const Color(0xFF000000)
                : const Color(0xFF121212);

    final primaryAccent =
        isNeon ? const Color(0xFF00F5D4) : const Color(0xFF1DB954);

    return MaterialApp(
      title: 'Music Stream',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        colorScheme: isLight
            ? ColorScheme.light(
                primary: primaryAccent, surface: Colors.grey[100]!)
            : ColorScheme.dark(
                primary: primaryAccent,
                secondary: isNeon ? const Color(0xFFFF007F) : primaryAccent,
                surface:
                    isNeon ? const Color(0xFF130D2E) : const Color(0xFF181818),
              ),
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

class _MainTabScreenState extends State<MainTabScreen>
    with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  String _selectedCategoryFilter = 'All';
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _listeningTrackerTimer;
  late final AnimationController _beatAnimController;

  List<TrackItem> _playlist = [];
  List<TrackItem> _likedSongs = [];
  List<TrackItem> _downloads = [];
  List<TrackItem> _recents = [];
  List<TrackItem> _playbackQueue = [];
  Set<String> _followedArtists = {};
  Set<String> _hiddenTrackIds = {};
  Set<String> _excludedTrackIds = {};

  UserProfileData _profile = UserProfileData();
  int _coins = 50;
  int _totalExp = 0;
  int _listeningStreak = 1;
  int _previousStreakBeforeLoss = 0;
  String _lastActiveDateStr = '';
  int _dailyRewardDayIndex = 1;
  String _lastDailyClaimDateStr = '';
  int _streakSaverTokens = 1;
  DateTime? _doubleExpEndTime;

  int _totalSongsListened = 0;
  int _totalUsageMinutes = 23;
  int _currentTrackSecondsListened = 0;
  int _lastAwardedMinuteBlock = 0;
  Set<String> _claimedMissionIds = {};

  Set<String> _ownedCosmeticIds = {'badge_wood', 'frame_wood'};
  String _equippedBadgeId = 'badge_wood';
  String _equippedFrameId = 'frame_wood';

  TrackItem? _currentPlayingTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final List<BoxModel> _top8Shortcuts;
  late final List<HomeSection> _homeSections;

  static const String _karolAssetPath = 'sample_track_1.mp3';
  static const String _taylorAssetPath = 'taylor_swift.mp3';

  static const List<AvatarPreset> _avatarPresets = [
    AvatarPreset(
      id: 'avatar_kids',
      label: 'Kids',
      bgStart: Color(0xFF7C3AED),
      bgEnd: Color(0xFFEC4899),
      badgeText: 'KIDS',
      icon: Icons.child_care,
    ),
    AvatarPreset(
      id: 'avatar_spider',
      label: 'Spider',
      bgStart: Color(0xFFDC2626),
      bgEnd: Color(0xFF1E3A8A),
      badgeText: 'SPIDER',
      icon: Icons.flash_on,
    ),
    AvatarPreset(
      id: 'avatar_buzz',
      label: 'Space',
      bgStart: Color(0xFF16A34A),
      bgEnd: Color(0xFF6D28D9),
      badgeText: 'SPACE',
      icon: Icons.rocket_launch,
    ),
    AvatarPreset(
      id: 'avatar_mirabel',
      label: 'Mirabel',
      bgStart: Color(0xFF8B5CF6),
      bgEnd: Color(0xFFF472B6),
      badgeText: 'STAR',
      icon: Icons.auto_awesome,
    ),
    AvatarPreset(
      id: 'avatar_iron',
      label: 'Armor',
      bgStart: Color(0xFFB91C1C),
      bgEnd: Color(0xFFF59E0B),
      badgeText: 'MK85',
      icon: Icons.shield,
    ),
    AvatarPreset(
      id: 'avatar_simba',
      label: 'Lion',
      bgStart: Color(0xFFD97706),
      bgEnd: Color(0xFF78350F),
      badgeText: 'LION',
      icon: Icons.pets,
    ),
    AvatarPreset(
      id: 'avatar_smiley',
      label: 'Smile',
      bgStart: Color(0xFF0284C7),
      bgEnd: Color(0xFF7C3AED),
      badgeText: ':)',
      icon: Icons.sentiment_satisfied_alt,
    ),
    AvatarPreset(
      id: 'avatar_panda',
      label: 'Panda',
      bgStart: Color(0xFF334155),
      bgEnd: Color(0xFF0F172A),
      badgeText: 'PANDA',
      icon: Icons.cruelty_free,
    ),
    AvatarPreset(
      id: 'avatar_moana',
      label: 'Ocean',
      bgStart: Color(0xFF0D9488),
      bgEnd: Color(0xFF1D4ED8),
      badgeText: 'WAVE',
      icon: Icons.waves,
    ),
    AvatarPreset(
      id: 'avatar_bart',
      label: 'Bart',
      bgStart: Color(0xFFFACC15),
      bgEnd: Color(0xFFEA580C),
      badgeText: 'BART',
      icon: Icons.face,
    ),
    AvatarPreset(
      id: 'avatar_baymax',
      label: 'Care',
      bgStart: Color(0xFFE2E8F0),
      bgEnd: Color(0xFF64748B),
      badgeText: 'BOT',
      icon: Icons.favorite,
    ),
    AvatarPreset(
      id: 'avatar_grogu',
      label: 'Force',
      bgStart: Color(0xFF4D7C0F),
      bgEnd: Color(0xFF1E293B),
      badgeText: 'JEDI',
      icon: Icons.spa,
    ),
  ];

  static const List<String> _sampleLyricsLines = [
    'Lights go low in the midnight air',
    'Every heartbeat echoes everywhere',
    'Turn the volume up till the walls can feel',
    'Chasing every moment that is real',
    'Hands up high in the neon glow',
    'Nowhere else that we rather go',
    'Every single note pulls us right back in',
    'Let the rhythm roll, let the night begin',
    'Shadow and light on the dancefloor line',
    'Your voice and the bass keep the signal fine',
    'No more waiting on a quiet screen',
    'Loudest story that we’ve ever seen',
  ];

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

  static const List<ShopCosmeticItem> _shopItems = [
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
    ShopCosmeticItem(
      id: 'frame_wood',
      name: 'Wood Frame',
      tier: 'Wood',
      type: 'frame',
      cost: 30,
      primaryColor: Color(0xFF8D5524),
      secondaryColor: Color(0xFF5C3818),
      icon: Icons.filter_vintage,
    ),
    ShopCosmeticItem(
      id: 'frame_iron',
      name: 'Iron Frame',
      tier: 'Iron',
      type: 'frame',
      cost: 80,
      primaryColor: Color(0xFF9CA3AF),
      secondaryColor: Color(0xFF4B5563),
      icon: Icons.filter_vintage,
    ),
    ShopCosmeticItem(
      id: 'frame_silver',
      name: 'Silver Frame',
      tier: 'Silver',
      type: 'frame',
      cost: 180,
      primaryColor: Color(0xFFF3F4F6),
      secondaryColor: Color(0xFF9CA3AF),
      icon: Icons.filter_vintage,
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
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.auto_awesome,
    ),
    ShopCosmeticItem(
      id: 'frame_diamond',
      name: 'Eternal Diamond Frame',
      tier: 'Diamond',
      type: 'frame',
      cost: 1000,
      primaryColor: Color(0xFF67E8F9),
      secondaryColor: Color(0xFF818CF8),
      icon: Icons.diamond,
    ),
  ];

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
    _beatAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _buildCatalogData();
    _loadPersistentState();
    _initAudioListeners();
    _applyVolumeBoost();
    _startSecondBySecondExpAndUsageTracker();
  }

  void _applyVolumeBoost() {
    final effectiveVol = widget.settings.equalizerEnabled
        ? widget.settings.volumeBoost.clamp(0.0, 2.0)
        : 1.0;
    _audioPlayer.setVolume(effectiveVol.clamp(0.0, 1.0));
  }

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
    return (200 + (level - 1) * 150).toInt();
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
    final int earned = _isDoubleExpActive ? (baseExp * 2).toInt() : baseExp;
    final int oldLv = _currentLevel;
    setState(() {
      _totalExp = (_totalExp + earned).toInt();
    });
    final int newLv = _currentLevel;
    if (newLv > oldLv && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1DB954),
          content: Text(
            'LEVEL UP! You reached Lv.$newLv!',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _startSecondBySecondExpAndUsageTracker() {
    _listeningTrackerTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPlaying) return;
      _currentTrackSecondsListened++;

      if (_currentTrackSecondsListened == 1) {
        _validateAndIncrementDailyStreak();
      }

      if (_currentTrackSecondsListened % 60 == 0) {
        setState(() {
          _totalUsageMinutes += 1;
        });
        _savePersistentState();
      }

      final int currentMinuteBlock =
          ((_currentTrackSecondsListened - 1) ~/ 60) + 1;
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
        final int diffDays = DateTime.now().difference(lastDate).inDays;
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

  TrackItem _karolTrack(String idPrefix) => TrackItem(
        id: '${idPrefix}_karol_g',
        title: 'Karol G (Hit Single)',
        artist: 'Karol G, Judeline, rusowsky',
        assetPath: _karolAssetPath,
        playsCount: '71,297,233',
      );

  TrackItem _taylorTrack(String idPrefix) => TrackItem(
        id: '${idPrefix}_taylor_swift',
        title: 'Taylor Swift',
        artist: 'Taylor Swift',
        assetPath: _taylorAssetPath,
        playsCount: '98,410,120',
      );

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
      List<TrackItem> tracks = [];
      if (i == 1) {
        tracks = [_karolTrack('shortcut_1')];
      } else if (i == 3) {
        tracks = [_taylorTrack('shortcut_3')];
      }
      return BoxModel(
        id: 'shortcut_$i',
        name: shortcutNames[i],
        subtitle: i == 0 ? 'Tap to Search' : 'Curated Mix',
        description:
            'Quick shortcut for ${shortcutNames[i]} — ready to expand with your tracks.',
        colorValue: i % 2 == 1 ? 0xFF000000 : _palette[i % _palette.length],
        useGreenMusicLogo: i % 2 == 1,
        tracks: tracks,
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
      'Taylor Swift',
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
        final int currentLineIdx = boxLineCounter;
        final bool isFirstLine = cycle == 0 && l == 0;
        _homeSections.add(
          HomeSection(
            id: 'box_line_${cycle}_$l',
            type: HomeSectionType.boxLine,
            title: lineTitle,
            boxes: List.generate(10, (b) {
              final bool isFirstBox = isFirstLine && b == 0;
              final bool isSecondBox = isFirstLine && b == 1;
              final boxName = isFirstBox
                  ? 'Karol G Hits'
                  : isSecondBox
                      ? 'Taylor Swift Spotlight'
                      : '$lineTitle #${b + 1}';
              final int artistIdx =
                  ((currentLineIdx + b) % artistNames.length).toInt();
              final artist = artistNames[artistIdx];
              final int colorIdx =
                  ((currentLineIdx + b) % _palette.length).toInt();

              List<TrackItem> boxTracks = [];
              if (isFirstBox) {
                boxTracks = [_karolTrack('first_box')];
              } else if (isSecondBox) {
                boxTracks = [_taylorTrack('second_box')];
              }

              return BoxModel(
                id: 'box_${cycle}_${l}_$b',
                name: boxName,
                subtitle: b % 2 == 0 ? 'Album • $artist' : 'Playlist',
                description:
                    'Customizable box template — add your own tracks or connect them from the repository anytime.',
                colorValue: _palette[colorIdx],
                useGreenMusicLogo: false,
                tracks: boxTracks,
              );
            }),
          ),
        );
        boxLineCounter++;
      }

      final int cIdx = circleLineCounter;
      _homeSections.add(
        HomeSection(
          id: 'circle_line_$cycle',
          type: HomeSectionType.circleLine,
          title: cycle == 0
              ? 'Your favorite artists'
              : 'Suggested artists ${cycle + 1}',
          circles: List.generate(6, (c) {
            final int artistIdx = ((cIdx * 6 + c) % artistNames.length).toInt();
            final name = artistNames[artistIdx];
            final int listeners = (893 - c * 45).clamp(100, 999).toInt();
            final int colorIdx = ((c + cycle + 2) % _palette.length).toInt();
            List<TrackItem> artistTracks = [];
            if (name == 'Karol G' && cycle == 0) {
              artistTracks = [_karolTrack('artist_karol')];
            } else if (name == 'Taylor Swift' && cycle == 0) {
              artistTracks = [_taylorTrack('artist_taylor')];
            }
            return CircleItem(
              id: 'artist_${cycle}_$c',
              name: name,
              monthlyListeners: '${listeners}K monthly listeners',
              colorValue: _palette[colorIdx],
              popularTracks: artistTracks,
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
            bannerHeadline: cycle == 0 ? 'Karol G Live' : 'Taylor Swift',
            title: cycle == 0
                ? 'Karol G Global Tour Visualizer & Audio'
                : 'Taylor Swift Acoustic & Studio Session',
            channel: cycle == 0 ? 'Karol G' : 'Taylor Swift',
            meta: 'Nov 19 • 240K+ plays',
            durationLabel: '27:11',
            colorValue: cycle == 0 ? 0xFFE8115B : 0xFF1B4D3E,
            audioTrack: cycle == 0
                ? _karolTrack('vid_0')
                : _taylorTrack('vid_1'),
          ),
        ),
      );
    }
  }

  Future<void> _handleNotificationAction(String? actionId) async {
    if (actionId == null) return;
    switch (actionId) {
      case 'prev_track':
        _playPreviousInQueue();
        break;
      case 'rewind_10':
        final target = Duration(
            seconds: math.max(0, _audioPlayer.position.inSeconds - 10));
        await _audioPlayer.seek(target);
        if (_currentPlayingTrack != null) {
          _showNowPlayingNotification(_currentPlayingTrack!, _isPlaying);
        }
        break;
      case 'pause_track':
        await _audioPlayer.pause();
        if (_currentPlayingTrack != null) {
          _showNowPlayingNotification(_currentPlayingTrack!, false);
        }
        break;
      case 'play_track':
        await _audioPlayer.play();
        if (_currentPlayingTrack != null) {
          _showNowPlayingNotification(_currentPlayingTrack!, true);
        }
        break;
      case 'forward_10':
        final totalMs = _audioPlayer.duration?.inMilliseconds ??
            _duration.inMilliseconds;
        final targetMs = math.min(
            totalMs > 0 ? totalMs : 180000,
            _audioPlayer.position.inMilliseconds + 10000);
        await _audioPlayer.seek(Duration(milliseconds: targetMs));
        if (_currentPlayingTrack != null) {
          _showNowPlayingNotification(_currentPlayingTrack!, _isPlaying);
        }
        break;
      case 'next_track':
        _playNextInQueue();
        break;
    }
  }

  Future<void> _showNowPlayingNotification(TrackItem track, bool playing) async {
    if (!widget.settings.pushNotifications) return;
    try {
      final posSec = _position.inSeconds;
      final durSec = _duration.inSeconds > 0 ? _duration.inSeconds : 180;
      final androidDetails = AndroidNotificationDetails(
        'music_playback_channel',
        'Now Playing Controls',
        channelDescription:
            'Playback controls for currently playing song (prev, seek, play/pause, next)',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: playing,
        autoCancel: false,
        showProgress: true,
        maxProgress: durSec,
        progress: posSec.clamp(0, durSec),
        subText:
            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'prev_track',
            '⏮',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'rewind_10',
            '⏪ -10s',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            playing ? 'pause_track' : 'play_track',
            playing ? '⏸' : '▶',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'forward_10',
            '+10s ⏩',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'next_track',
            '⏭',
            showsUserInterface: true,
          ),
        ],
      );

      await _notifsPlugin.show(
        1001,
        track.title,
        '${track.artist}  •  [${_formatDuration(_position)} ——●—— ${_formatDuration(_duration)}]',
        NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<File> _getStateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/music_app_persistent_v10.json');
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

  List<TrackItem> _parseTrackList(dynamic rawList) {
    final result = <TrackItem>[];
    if (rawList is Iterable) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          result.add(TrackItem.fromJson(item));
        } else if (item is Map) {
          result.add(TrackItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return result;
  }

  Future<void> _loadPersistentState() async {
    try {
      final file = await _getStateFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return;
        final data = Map<String, dynamic>.from(decoded);
        if (!mounted) return;
        setState(() {
          _playlist = _parseTrackList(data['playlist']);
          _likedSongs = _parseTrackList(data['likedSongs']);
          _downloads = _parseTrackList(data['downloads']);
          _recents = _parseTrackList(data['recents']);
          _followedArtists =
              Set<String>.from(data['followedArtists'] ?? const []);
          _hiddenTrackIds =
              Set<String>.from(data['hiddenTrackIds'] ?? const []);
          _excludedTrackIds =
              Set<String>.from(data['excludedTrackIds'] ?? const []);
          if (data['settings'] is Map) {
            widget.onSettingsChanged(AppSettings.fromJson(
                Map<String, dynamic>.from(data['settings'] as Map)));
          }
          if (data['profile'] is Map) {
            _profile = UserProfileData.fromJson(
                Map<String, dynamic>.from(data['profile'] as Map));
          }
          _coins = (data['coins'] as num?)?.toInt() ?? 50;
          _totalExp = (data['totalExp'] as num?)?.toInt() ?? 0;
          _listeningStreak = (data['listeningStreak'] as num?)?.toInt() ?? 1;
          _previousStreakBeforeLoss =
              (data['previousStreakBeforeLoss'] as num?)?.toInt() ?? 0;
          _lastActiveDateStr = (data['lastActiveDateStr'] ?? '').toString();
          _dailyRewardDayIndex =
              (data['dailyRewardDayIndex'] as num?)?.toInt() ?? 1;
          _lastDailyClaimDateStr =
              (data['lastDailyClaimDateStr'] ?? '').toString();
          _streakSaverTokens =
              (data['streakSaverTokens'] as num?)?.toInt() ?? 1;
          if (data['doubleExpEndTime'] != null) {
            _doubleExpEndTime =
                DateTime.tryParse(data['doubleExpEndTime'].toString());
          }
          _totalSongsListened =
              (data['totalSongsListened'] as num?)?.toInt() ?? 0;
          _totalUsageMinutes =
              (data['totalUsageMinutes'] as num?)?.toInt() ?? 23;
          _claimedMissionIds =
              Set<String>.from(data['claimedMissionIds'] ?? const []);
          _ownedCosmeticIds = Set<String>.from(
              data['ownedCosmeticIds'] ?? const ['badge_wood', 'frame_wood']);
          _equippedBadgeId =
              (data['equippedBadgeId'] ?? 'badge_wood').toString();
          _equippedFrameId =
              (data['equippedFrameId'] ?? 'frame_wood').toString();
        });
        _applyVolumeBoost();
      }
    } catch (_) {}
  }

  void _initAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
      if (_currentPlayingTrack != null) {
        _showNowPlayingNotification(_currentPlayingTrack!, state.playing);
      }
      if (state.processingState == ProcessingState.completed &&
          widget.settings.autoplay) {
        _playNextInQueue();
      }
    });
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });
    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() => _duration = dur);
      }
    });
  }

  @override
  void dispose() {
    _beatAnimController.dispose();
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
      _applyVolumeBoost();
      setState(() {
        _currentPlayingTrack = track;
        _position = Duration.zero;
        _currentTrackSecondsListened = 0;
        _lastAwardedMinuteBlock = 0;
        _totalSongsListened += 1;
        if (queue != null && queue.isNotEmpty) {
          _playbackQueue = List<TrackItem>.from(queue);
        }
        if (!widget.settings.privateSession) {
          _recents.removeWhere((t) => t.id == track.id);
          _recents.insert(0, track);
          if (_recents.length > 50) _recents = _recents.sublist(0, 50);
        }
      });
      _savePersistentState();

      final dur = await _audioPlayer.setAsset(track.assetPath);
      if (dur != null && mounted) {
        setState(() => _duration = dur);
      }
      _audioPlayer.play();
      _showNowPlayingNotification(track, true);
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
    } else if (_currentPlayingTrack != null) {
      final alternate = _currentPlayingTrack!.assetPath == _karolAssetPath
          ? _taylorTrack('next_auto')
          : _karolTrack('next_auto');
      _playTrack(alternate, openModal: false);
    }
  }

  void _playPreviousInQueue() {
    if (_position.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
    } else if (_recents.length > 1) {
      final prev = _recents[1];
      _playTrack(prev, openModal: false);
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
    if (_currentPlayingTrack != null) {
      _showNowPlayingNotification(_currentPlayingTrack!, _isPlaying);
    }
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

  Widget _buildGreenMusicLogoTile({double size = 48, double radius = 6}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.45)),
      ),
      child: CustomPaint(
        painter: _GreenMusicLogoPainter(),
      ),
    );
  }

  Widget _buildCircleDotBoxTile(
      {required int colorValue, double size = 48, double radius = 8}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorValue),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.46, size * 0.46),
          painter: _CircleDotLogoPainter(),
        ),
      ),
    );
  }

  Widget _buildTrackPlayingEqualizerBars(TrackItem track) {
    final isThisPlaying =
        _isPlaying && _currentPlayingTrack?.id == track.id;
    if (!isThisPlaying) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _beatAnimController,
      builder: (context, _) {
        final t = _beatAnimController.value;
        final heights = [
          (6 + 10 * ((math.sin(t * math.pi * 2) + 1) / 2)).toDouble(),
          (6 + 10 * ((math.sin(t * math.pi * 2 + 1.8) + 1) / 2)).toDouble(),
          (6 + 10 * ((math.sin(t * math.pi * 2 + 3.6) + 1) / 2)).toDouble(),
        ];
        return Container(
          margin: const EdgeInsets.only(right: 8),
          width: 18,
          height: 18,
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: heights
                .map((h) => Container(
                      width: 4,
                      height: h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildBuyerFriendlyEmptyBoxView(BoxModel box, bool isLight) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircleDotBoxTile(
              colorValue: box.colorValue, size: 76, radius: 16),
          const SizedBox(height: 18),
          Text(
            '${box.name} is ready for your tracks',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This box is intentionally clean so you can plug in songs directly from your repository or backend without extra clutter. Demo tracks are included in the first two boxes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isLight ? Colors.black54 : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  AvatarPreset _resolveAvatarPreset(String avatarId) {
    return _avatarPresets.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => _avatarPresets.first,
    );
  }

  Widget _buildPresetAvatarCircle(AvatarPreset preset,
      {double radius = 32, bool selected = false}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [preset.bgStart, preset.bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: selected ? Colors.white : Colors.white24,
          width: selected ? 3 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(preset.icon, color: Colors.white, size: radius * 0.68),
          Text(
            preset.badgeText,
            style: TextStyle(
              color: Colors.white,
              fontSize: (radius * 0.25).clamp(7, 11),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

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
                  leading: _buildGreenMusicLogoTile(size: 46, radius: 6),
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
                            'Artist: ${track.artist}\nPlays: ${track.playsCount}\nAsset: ${track.assetPath}'),
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

  void _openSearchScreen() {
    final searchController = TextEditingController();
    var searchResults = <TrackItem>[];
    var artistResults = <CircleItem>[];

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
    double boostVal = widget.settings.volumeBoost.clamp(0.2, 2.0);
    double bassVal = 6.5;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setEqState) {
            final boostPercent = (boostVal * 100).round();
            return Container(
              padding: const EdgeInsets.all(20),
              height: 430,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Equalizer & Volume Boost',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.bold)),
                      Switch(
                        value: widget.settings.equalizerEnabled,
                        activeColor: const Color(0xFF1DB954),
                        onChanged: (val) {
                          widget.settings.equalizerEnabled = val;
                          widget.onSettingsChanged(widget.settings);
                          _applyVolumeBoost();
                          _savePersistentState();
                          setEqState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.volume_up, color: Color(0xFF1DB954)),
                                SizedBox(width: 8),
                                Text('Volume Boost',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(
                              '$boostPercent%',
                              style: const TextStyle(
                                color: Color(0xFF1DB954),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: boostVal,
                          min: 0.2,
                          max: 2.0,
                          divisions: 18,
                          activeColor: const Color(0xFF1DB954),
                          onChanged: widget.settings.equalizerEnabled
                              ? (v) {
                                  setEqState(() => boostVal = v);
                                  widget.settings.volumeBoost = v;
                                  widget.onSettingsChanged(widget.settings);
                                  _applyVolumeBoost();
                                  _savePersistentState();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Frequency & Bass Punch',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Slider(
                    value: bassVal,
                    min: 0,
                    max: 10,
                    activeColor: Colors.amber,
                    onChanged: widget.settings.equalizerEnabled
                        ? (v) {
                            setEqState(() => bassVal = v);
                            _applyVolumeBoost();
                          }
                        : null,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954)),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply Boost',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  if (_profile.isCreated) ...[
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF1DB954).withOpacity(0.4)),
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
                          _profileDetailRow('Full Name',
                              '${_profile.firstName} ${_profile.lastName}'),
                          _profileDetailRow('Birthday', _profile.birthday),
                          _profileDetailRow('City', _profile.city),
                          _profileDetailRow('Address', _profile.address),
                        ],
                      ),
                    ),
                  ],
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
                          children: ['Dark', 'Light', 'Neon', 'Midnight']
                              .map((t) => ListTile(
                                    title: Text('$t Theme'),
                                    trailing: widget.settings.themeMode == t
                                        ? const Icon(Icons.check,
                                            color: Color(0xFF1DB954))
                                        : null,
                                    onTap: () {
                                      updateSetting(() {
                                        widget.settings.themeMode = t;
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
                    title: const Text('Equalizer & Volume Boost',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Boost: ${(widget.settings.volumeBoost * 100).round()}%'),
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
                              child: _buildCircleDotBoxTile(
                                  colorValue: box.colorValue,
                                  size: 160,
                                  radius: 14),
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
                            if (visibleTracks.isNotEmpty) ...[
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
                                      _playTrack(visibleTracks.first,
                                          queue: visibleTracks,
                                          openModal: true);
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
                          ],
                        ),
                      ),
                    ),
                    if (visibleTracks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildBuyerFriendlyEmptyBoxView(box, isLight),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = visibleTracks[index];
                            final liked = _isLiked(track);
                            final inPlaylist = _isInPlaylist(track);
                            return ListTile(
                              leading: _buildCircleDotBoxTile(
                                  colorValue: box.colorValue,
                                  size: 46,
                                  radius: 6),
                              title: Row(
                                children: [
                                  _buildTrackPlayingEqualizerBars(track),
                                  Expanded(
                                    child: Text(
                                      track.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: (_isPlaying &&
                                                _currentPlayingTrack?.id ==
                                                    track.id)
                                            ? const Color(0xFF1DB954)
                                            : (isLight
                                                ? Colors.black
                                                : Colors.white),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
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
                                      duration:
                                          const Duration(milliseconds: 300),
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
                                if (artist.popularTracks.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _playTrack(artist.popularTracks.first,
                                          queue: artist.popularTracks,
                                          openModal: true);
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
                    if (artist.popularTracks.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Artist catalog slot ready — add tracks from your repository anytime.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color:
                                    isLight ? Colors.black54 : Colors.white60),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final track = artist.popularTracks[index];
                            return ListTile(
                              leading: Text('${index + 1}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isLight
                                          ? Colors.black
                                          : Colors.white)),
                              title: Row(
                                children: [
                                  _buildTrackPlayingEqualizerBars(track),
                                  Expanded(
                                    child: Text(
                                      track.title,
                                      style: TextStyle(
                                        color: (_isPlaying &&
                                                _currentPlayingTrack?.id ==
                                                    track.id)
                                            ? const Color(0xFF1DB954)
                                            : (isLight
                                                ? Colors.black
                                                : Colors.white),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildBeatAnimationWidget({double height = 42, int barCount = 12}) {
    return AnimatedBuilder(
      animation: _beatAnimController,
      builder: (context, _) {
        final t = _beatAnimController.value;
        return SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              final phase = (i * 0.45) + (t * math.pi * 2);
              final factor = _isPlaying
                  ? (0.25 + 0.75 * ((math.sin(phase) + 1) / 2))
                      .clamp(0.15, 1.0)
                  : 0.2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4.5,
                height: height * factor,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
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
        return StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          initialData: _position,
          builder: (context, posSnap) {
            final livePos = posSnap.data ?? _position;
            final liveDur = _audioPlayer.duration ??
                (_duration.inSeconds > 0
                    ? _duration
                    : const Duration(seconds: 180));
            final double maxDur = liveDur.inMilliseconds > 0
                ? liveDur.inMilliseconds.toDouble()
                : 180000.0;
            final double curPos =
                livePos.inMilliseconds.toDouble().clamp(0.0, maxDur);
            final activeTrack = _currentPlayingTrack ?? track;
            final bool liked = _isLiked(activeTrack);
            final bool inPlaylist = _isInPlaylist(activeTrack);

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
                      Text(activeTrack.artist.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _openTrack3DotsMenu(activeTrack),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGreenMusicLogoTile(size: 132, radius: 18),
                          const SizedBox(height: 22),
                          _buildBeatAnimationWidget(height: 44, barCount: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          setState(() {});
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
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      activeColor: const Color(0xFF1DB954),
                      inactiveColor: Colors.white24,
                      min: 0.0,
                      max: maxDur,
                      value: curPos,
                      onChanged: (val) async {
                        final target = Duration(milliseconds: val.round());
                        setState(() => _position = target);
                        await _audioPlayer.seek(target);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(livePos)),
                      Text(_formatDuration(liveDur)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lyrics, color: Colors.white70),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1E1E1E),
                            builder: (lCtx) => StreamBuilder<Duration>(
                              stream: _audioPlayer.positionStream,
                              initialData: _audioPlayer.position,
                              builder: (context, lSnap) {
                                final sec =
                                    (lSnap.data ?? Duration.zero).inSeconds;
                                final activeLineIdx =
                                    (sec ~/ 6) % _sampleLyricsLines.length;
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  height: 360,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Live Lyrics - ${activeTrack.title}',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: _sampleLyricsLines.length,
                                          itemBuilder: (context, idx) {
                                            final isCurrent =
                                                idx == activeLineIdx;
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              child: Text(
                                                _sampleLyricsLines[idx],
                                                style: TextStyle(
                                                  color: isCurrent
                                                      ? const Color(0xFF1DB954)
                                                      : Colors.white54,
                                                  fontSize: isCurrent ? 18 : 15,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                      StreamBuilder<PlayerState>(
                        stream: _audioPlayer.playerStateStream,
                        initialData: _audioPlayer.playerState,
                        builder: (context, pSnap) {
                          final playingNow = pSnap.data?.playing ?? _isPlaying;
                          return IconButton(
                            iconSize: 68,
                            icon: Icon(
                                playingNow
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white),
                            onPressed: () {
                              if (playingNow) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.play();
                              }
                            },
                          );
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
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                        shortcut.useGreenMusicLogo
                            ? _buildGreenMusicLogoTile(size: 48, radius: 0)
                            : Container(
                                width: 48,
                                height: double.infinity,
                                color: Color(shortcut.colorValue),
                                child: Icon(
                                    index == 0
                                        ? Icons.search
                                        : Icons.music_note,
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
        const SliverToBoxAdapter(child: SizedBox(height: 115)),
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
                        child: _buildCircleDotBoxTile(
                            colorValue: box.colorValue, size: 136, radius: 8),
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

  Widget _buildTrackListSection(List<TrackItem> trackList, String emptyMsg,
      void Function(TrackItem) onRemove) {
    final isLight = widget.settings.themeMode == 'Light';
    if (trackList.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyMsg,
                  style: TextStyle(
                      color: isLight ? Colors.black54 : Colors.white60))));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 115, top: 8),
      itemCount: trackList.length,
      itemBuilder: (context, index) {
        final track = trackList[index];
        return ListTile(
          leading: _buildGreenMusicLogoTile(size: 48, radius: 6),
          title: Row(
            children: [
              _buildTrackPlayingEqualizerBars(track),
              Expanded(
                child: Text(
                  track.title,
                  style: TextStyle(
                    color: (_isPlaying && _currentPlayingTrack?.id == track.id)
                        ? const Color(0xFF1DB954)
                        : (isLight ? Colors.black : Colors.white),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          subtitle: Text(track.artist,
              style:
                  TextStyle(color: isLight ? Colors.black54 : Colors.white60)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => onRemove(track),
          ),
          onTap: () => _playTrack(track, queue: trackList, openModal: true),
        );
      },
    );
  }

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
        final int rewardCoins = (day * 10).toInt();
        _coins = (_coins + rewardCoins).toInt();
        _dailyRewardDayIndex += 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: const Color(0xFF1DB954),
              content: Text('Claimed Day $day Reward: +$rewardCoins Coins!',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold))),
        );
      } else {
        _coins = (_coins + 200).toInt();
        _streakSaverTokens += 1;
        _doubleExpEndTime = DateTime.now().add(const Duration(hours: 24));
        _dailyRewardDayIndex = 1;
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        title: const Text('Restore Lost Streak?'),
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
                              'Streak restored to $_listeningStreak days!')),
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
              Tab(
                icon: Icon(Icons.event_available),
                text: 'Daily Rewards',
              ),
              Tab(
                icon: Icon(Icons.track_changes),
                text: 'Missions',
              ),
              Tab(
                icon: Icon(Icons.swap_horiz),
                text: 'Exchange',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 115),
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
                      label: Text('Tokens: $_streakSaverTokens'),
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
                                  : '+${(day * 10).toInt()} Coins',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCompleted
                                  ? 'Claimed'
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
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 115),
              itemCount: _longTermMissions.length,
              itemBuilder: (context, idx) {
                final m = _longTermMissions[idx];
                final int current = _getMissionProgress(m);
                final bool isClaimed = _claimedMissionIds.contains(m.id);
                final bool canClaim = !isClaimed && current >= m.targetValue;
                final double progressRatio =
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
                            Text(
                                '+${m.coinReward.toInt()} Coins  +${m.expReward.toInt()} EXP',
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
                                      final int coinGain = m.coinReward.toInt();
                                      final int expGain = m.expReward.toInt();
                                      setState(() {
                                        _claimedMissionIds.add(m.id);
                                        _coins = (_coins + coinGain).toInt();
                                      });
                                      _grantExp(expGain);
                                      _savePersistentState();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Mission Completed! +$coinGain Coins & +$expGain EXP')),
                                      );
                                    }
                                  : null,
                              child: Text(
                                isClaimed
                                    ? 'Completed'
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
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 115),
              itemCount: _shopItems.length,
              itemBuilder: (context, idx) {
                final item = _shopItems[idx];
                final bool isOwned = _ownedCosmeticIds.contains(item.id);
                final bool isEquipped = item.type == 'badge'
                    ? _equippedBadgeId == item.id
                    : _equippedFrameId == item.id;
                final int itemCost = item.cost.toInt();

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
                            : 'Decorative Avatar Frame',
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
                        } else if (_coins >= itemCost) {
                          setState(() {
                            _coins = (_coins - itemCost).toInt();
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
                                    'Need ${(itemCost - _coins).toInt()} more coins!')),
                          );
                        }
                      },
                      child: Text(
                        isEquipped
                            ? 'Equipped'
                            : (isOwned ? 'Equip' : '$itemCost Coins'),
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

  ShopCosmeticItem get _currentBadge => _shopItems.firstWhere(
      (i) => i.id == _equippedBadgeId,
      orElse: () => _shopItems.first);

  ShopCosmeticItem get _currentFrame => _shopItems.firstWhere(
      (i) => i.id == _equippedFrameId,
      orElse: () => _shopItems[5]);

  void _openCreateOrEditProfileForm() {
    final firstCtrl = TextEditingController(text: _profile.firstName);
    final lastCtrl = TextEditingController(text: _profile.lastName);
    final birthdayCtrl = TextEditingController(text: _profile.birthday);
    final cityCtrl = TextEditingController(text: _profile.city);
    final addressCtrl = TextEditingController(text: _profile.address);
    String selectedAvatarId = _profile.avatarId;

    bool errFirst = false;
    bool errLast = false;
    bool errBirthday = false;
    bool errCity = false;
    bool errAddress = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setFormState) {
            final activePreset = _resolveAvatarPreset(selectedAvatarId);
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
                    const Text('Create Profile',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Center(
                      child: _buildPresetAvatarCircle(activePreset,
                          radius: 44, selected: true),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatarPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final preset = _avatarPresets[idx];
                          final isSel = preset.id == selectedAvatarId;
                          return GestureDetector(
                            onTap: () => setFormState(
                                () => selectedAvatarId = preset.id),
                            child: _buildPresetAvatarCircle(preset,
                                radius: 34, selected: isSel),
                          );
                        },
                      ),
                    ),
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
                      controller: birthdayCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2002, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          birthdayCtrl.text =
                              '${picked.day}/${picked.month}/${picked.year}';
                        }
                      },
                      decoration: buildFieldDeco(
                        'Birthday (DD/MM/YYYY) *',
                        errBirthday,
                      ).copyWith(
                        suffixIcon: const Icon(Icons.cake_outlined,
                            color: Color(0xFF1DB954)),
                      ),
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
                            errBirthday = birthdayCtrl.text.trim().isEmpty;
                            errCity = cityCtrl.text.trim().isEmpty;
                            errAddress = addressCtrl.text.trim().isEmpty;
                          });

                          if (errFirst ||
                              errLast ||
                              errBirthday ||
                              errCity ||
                              errAddress) {
                            return;
                          }

                          setState(() {
                            _profile.firstName = firstCtrl.text.trim();
                            _profile.lastName = lastCtrl.text.trim();
                            _profile.birthday = birthdayCtrl.text.trim();
                            _profile.city = cityCtrl.text.trim();
                            _profile.address = addressCtrl.text.trim();
                            _profile.avatarId = selectedAvatarId;
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
              tween: Tween<double>(begin: 0.2, end: 1.0),
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
    final avatarPreset = _resolveAvatarPreset(_profile.avatarId);
    final isGoldFrame = frame.tier == 'Gold';
    final isDiamondFrame = frame.tier == 'Diamond';
    final double shineBlur = isDiamondFrame
        ? 26
        : isGoldFrame
            ? 20
            : 10;

    final int remainingExp =
        (_expNeededForNextLevel - _expIntoCurrentLevel).toInt();

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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 115),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 212,
                  height: 212,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: frame.primaryColor
                            .withOpacity(isDiamondFrame ? 0.75 : 0.45),
                        blurRadius: shineBlur,
                        spreadRadius: isDiamondFrame ? 4 : 1,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _DecorativeFiligreeFramePainter(
                      primaryColor: frame.primaryColor,
                      secondaryColor: frame.secondaryColor,
                      isGold: isGoldFrame,
                      isDiamond: isDiamondFrame,
                    ),
                  ),
                ),
                _buildPresetAvatarCircle(avatarPreset,
                    radius: 66, selected: true),
                Positioned(
                  bottom: 18,
                  right: 22,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [badge.primaryColor, badge.secondaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badge.primaryColor.withOpacity(0.85),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(badge.icon, size: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _profile.displayName,
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.black : Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF1DB954).withOpacity(0.55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.$_currentLevel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1DB954),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$remainingExp EXP to Lv.${_currentLevel + 1}',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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

  @override
  Widget build(BuildContext context) {
    final isLight = widget.settings.themeMode == 'Light';
    final double miniProgress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

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
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                            child: Row(
                              children: [
                                _buildGreenMusicLogoTile(size: 40, radius: 5),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              color: Colors.white70,
                                              fontSize: 11),
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
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
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
                          LinearProgressIndicator(
                            value: miniProgress,
                            minHeight: 2.5,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          _BouncingBallNavBar(
            currentIndex: _currentTabIndex,
            isLight: isLight,
            onSelect: (idx) => setState(() => _currentTabIndex = idx),
          ),
        ],
      ),
    );
  }
}

class _BouncingBallNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isLight;
  final ValueChanged<int> onSelect;

  const _BouncingBallNavBar({
    required this.currentIndex,
    required this.isLight,
    required this.onSelect,
  });

  static const _tabs = [
    (Icons.home_outlined, Icons.home_filled, 'Home'),
    (Icons.library_music_outlined, Icons.library_music, 'Playlist'),
    (Icons.event_available_outlined, Icons.event_available, 'Quests'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isLight ? Colors.white : const Color(0xFF121212),
      padding: const EdgeInsets.only(top: 6, bottom: 8, left: 6, right: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _tabs.length;
          final targetX = (currentIndex * itemWidth) + (itemWidth / 2) - 4.5;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (index) {
                  final selected = currentIndex == index;
                  final (iconOut, iconFill, label) = _tabs[index];
                  return SizedBox(
                    width: itemWidth,
                    child: GestureDetector(
                      onTap: () => onSelect(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? (isLight ? Colors.black12 : Colors.white24)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(selected ? iconFill : iconOut,
                                size: 20,
                                color: isLight ? Colors.black : Colors.white),
                            if (selected) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isLight ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey('ball_tab_$currentIndex'),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 420),
                curve: Curves.bounceOut,
                builder: (context, t, child) {
                  final bounceOffset = -8.0 * math.sin(t * math.pi);
                  return Positioned(
                    left: targetX,
                    top: -3 + bounceOffset,
                    child: child!,
                  );
                },
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DecorativeFiligreeFramePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isGold;
  final bool isDiamond;

  _DecorativeFiligreeFramePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isGold,
    required this.isDiamond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 12;
    final innerR = outerR - 14;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDiamond ? 3.5 : 2.5
      ..shader = SweepGradient(
        colors: [
          primaryColor,
          secondaryColor,
          Colors.white,
          primaryColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));

    canvas.drawCircle(center, outerR, ringPaint);
    canvas.drawCircle(
        center, innerR, ringPaint..strokeWidth = isGold ? 2.5 : 1.8);

    final petalCount = 16;
    final petalPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor.withOpacity(isDiamond ? 0.95 : 0.85);

    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, -innerR)
        ..quadraticBezierTo(9, -(innerR + outerR) / 2, 0, -outerR - 7)
        ..quadraticBezierTo(-9, -(innerR + outerR) / 2, 0, -innerR)
        ..close();
      canvas.drawPath(path, petalPaint);

      if (isGold || isDiamond) {
        canvas.drawCircle(
          Offset(0, -outerR - 9),
          isDiamond ? 3.5 : 2.5,
          Paint()..color = isDiamond ? Colors.white : const Color(0xFFFFF176),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DecorativeFiligreeFramePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isGold != isGold ||
        oldDelegate.isDiamond != isDiamond;
  }
}

class _CircleDotLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, radius * 0.14);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, math.max(2.2, radius * 0.24), dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GreenMusicLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);

    final greenPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final fillGreen = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final a = (i * math.pi) / 6;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * w * 0.36, c.dy + math.sin(a) * h * 0.36),
        Offset(c.dx + math.cos(a) * w * 0.44, c.dy + math.sin(a) * h * 0.44),
        greenPaint..strokeWidth = w * 0.025,
      );
    }

    final beamPath = Path()
      ..moveTo(w * 0.36, h * 0.32)
      ..lineTo(w * 0.68, h * 0.24)
      ..lineTo(w * 0.68, h * 0.33)
      ..lineTo(w * 0.36, h * 0.41)
      ..close();
    canvas.drawPath(beamPath, fillGreen);

    canvas.drawRect(
        Rect.fromLTWH(w * 0.35, h * 0.36, w * 0.045, h * 0.32), fillGreen);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.64, h * 0.29, w * 0.045, h * 0.32), fillGreen);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.31, h * 0.68),
            width: w * 0.16,
            height: h * 0.11),
        fillGreen);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.60, h * 0.61),
            width: w * 0.16,
            height: h * 0.11),
        fillGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
