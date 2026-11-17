import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: Colors.white),
      ),
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music App Dashboard'),
        backgroundColor: const Color(0xFF181818),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 80, color: Colors.white54),
              const SizedBox(height: 24),
              const Text(
                'Welcome to your Music App',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Click the button below to open the fully working 30-second iTunes Preview player script.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ).wrap(
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ITunesSearchScreen()),
                      );
                    },
                    child: const Text(
                      'Open Working iTunes 30s Preview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// STANDALONE WORKING ITUNES 30-SECOND PREVIEW SCRIPT
// ---------------------------------------------------------
class TrackItem {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? artworkUrl;

  TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
  });
}

class ITunesSearchScreen extends StatefulWidget {
  const ITunesSearchScreen({super.key});

  @override
  State<ITunesSearchScreen> createState() => _ITunesSearchScreenState();
}

class _ITunesSearchScreenState extends State<ITunesSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  TrackItem? _currentlyPlaying;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchITunes(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final encodedTerm = Uri.encodeComponent(query.trim());
      // Using HTTPS endpoint with proper url encoding
      final uri = Uri.parse('https://itunes.apple.com/search?term=$encodedTerm&media=music&limit=25');
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data['results'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isLoading = false;
            _errorMessage = 'Server status code: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _playPreview(TrackItem track) async {
    if (track.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview audio available for this track.')),
      );
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() => _currentlyPlaying = track);
      
      await _audioPlayer.setUrl(track.url);
      _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iTunes 30s Preview'),
        backgroundColor: const Color(0xFF181818),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                hintStyle: const TextStyle(color: Colors.white54),
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
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: _searchResults.isEmpty && !_isLoading
                  ? const Center(child: Text('Search for music to preview', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final track = TrackItem(
                          id: item['trackId']?.toString() ?? index.toString(),
                          title: item['trackName'] ?? 'Unknown Title',
                          artist: item['artistName'] ?? 'Unknown Artist',
                          url: item['previewUrl'] ?? '',
                          artworkUrl: item['artworkUrl100'],
                        );

                        final isSelected = _currentlyPlaying?.id == track.id;

                        return ListTile(
                          leading: track.artworkUrl != null
                              ? Image.network(track.artworkUrl!, width: 48, height: 48, fit: BoxFit.cover)
                              : const Icon(Icons.music_note, size: 48),
                          title: Text(track.title, maxLines: 1, style: TextStyle(color: isSelected ? Colors.greenAccent : Colors.white)),
                          subtitle: Text(track.artist, maxLines: 1, style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: Icon(isSelected && _isPlaying ? Icons.pause_circle : Icons.play_circle, size: 36, color: Colors.white),
                            onPressed: () => _playPreview(track),
                          ),
                          onTap: () => _playPreview(track),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension helper for button wrapping layout cleanly
extension on ButtonStyle {
  Widget wrap(Widget child) {
    return this == null ? child : Builder(builder: (context) => child);
  }
}
