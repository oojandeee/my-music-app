import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const SpotifyStyleMusicApp());
}

class SpotifyStyleMusicApp extends StatelessWidget {
  const SpotifyStyleMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Music App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212), elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF121212),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class SongItem {
  final String title;
  final String artist;
  final String url;
  final bool isEmpty;

  SongItem({
    required this.title,
    required this.artist,
    required this.url,
    this.isEmpty = false,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();Here is the complete, updated **`lib/main.dart`** code. It fixes the audio playback issue, adds the seek bar (progress slider with current position and remaining duration), and implements a bottom navigation bar with four tabs (**Home**, **Search**, **Create**, **Premium**) including recent search history logic limited to 5 items.

```dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyMusicApp());
}

class MyMusicApp extends StatelessWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Music App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF121212),
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class SongItem {
  final String title;
  final String artist;
  final String url;
  final bool isEmpty;

  SongItem({
    required this.title,
    required this.artist,
    required this.url,
    this.isEmpty = false,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Recent Searches List (Max 5)
  final List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 30 Boxes for Home Tab (1 Real Song + 29 Empty Slots)
  final List<SongItem> _homeGridBoxes = [
    SongItem(
      title: 'ASTARR',
      artist: 'Prem Dhillon',
      url: '[https://archive.org/download/sample-audio-files/sample1.mp3](https://archive.org/download/sample-audio-files/sample1.mp3)',
    ),
    ...List.generate(
      29,
      (index) => SongItem(
        title: 'Empty Slot ${index + 1}',
        artist: 'Add Song Here',
        url: '',
        isEmpty: true,
      ),
    ),
  ];

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
      _searchQuery = query;
      _searchController.text = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildSearchTab(),
      _buildEmptyTab('Create'),
      _buildEmptyTab('Premium'),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'CREATE'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'PREMIUM'),
        ],
      ),
    );
  }

  // --- HOME TAB ---
  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Jump Back In',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GridView.builder(
              itemCount: _homeGridBoxes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final item = _homeGridBoxes[index];
                return _buildSongCard(item, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongCard(SongItem item, int index) {
    return GestureDetector(
      onTap: () {
        if (item.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Slot ${index + 1} is empty.')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(song: item),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: item.isEmpty ? const Color(0xFF282828) : Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(
                    item.isEmpty ? Icons.add : Icons.music_note,
                    size: 48,
                    color: item.isEmpty ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.isEmpty ? Colors.grey : Colors.white,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.artist,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- SEARCH TAB ---
  Widget _buildSearchTab() {
    final searchResults = _homeGridBoxes
        .where((song) =>
            !song.isEmpty &&
            (song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                song.artist.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search songs or artists...',
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: const Color(0xFF282828),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) => _executeSearch(value),
          ),
          const SizedBox(height: 16),

          // Recent Searches Section
          if (_recentSearches.isNotEmpty) ...[
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  backgroundColor: const Color(0xFF282828),
                  onPressed: () => _executeSearch(search),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Search Results
          if (_searchQuery.isNotEmpty) ...[
            const Text('Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: searchResults.isEmpty
                  ? const Center(child: Text('No matching songs found.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final song = searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.music_note, color: Colors.purpleAccent),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerScreen(song: song),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ] else ...[
            // 4 Empty Boxes below Recent Searches when search is idle
            const Text('Browse Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Category ${index + 1}',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- PLACEHOLDER TAB ---
  Widget _buildEmptyTab(String title) {
    return Center(
      child: Text(
        '$title Screen',
        style: const TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
}

// --- PLAYER SCREEN WITH PROGRESS BAR ---
class PlayerScreen extends StatefulWidget {
  final SongItem song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.song.url);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.purpleAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.music_note, size: 100, color: Colors.white70),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.song.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.song.artist,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Real-Time Progress Bar & Duration Indicators
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = _audioPlayer.duration ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      activeColor: Colors.purpleAccent,
                      inactiveColor: Colors.grey[800],
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble() > 0.0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      value: position.inMilliseconds.toDouble().clamp(
                            0.0,
                            duration.inMilliseconds.toDouble() > 0.0
                                ? duration.inMilliseconds.toDouble()
                                : 1.0,
                          ),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position), style: const TextStyle(color: Colors.grey)),
                          Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            // Play / Pause Button
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                return IconButton(
                  iconSize: 72,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.purpleAccent,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.play();
                    }
                  },
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
