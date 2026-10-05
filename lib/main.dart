import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyMusicApp());
}

class MyMusicApp extends StatelessWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class OnlineSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String streamUrl;

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.streamUrl,
  });
}

class SaavnService {
  // Uses open-source JioSaavn backend API to return real direct MP3/AAC CDN links
  static Future<List<OnlineSong>> searchSongs(String query) async {
    final searchUrl = Uri.parse(
      'https://saavn.dev/api/search/songs?query=${Uri.encodeComponent(query)}&limit=20',
    );

    try {
      final response = await http.get(searchUrl).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['data']?['results'] ?? [];

        List<OnlineSong> songs = [];
        for (var item in songsJson) {
          String songId = item['id']?.toString() ?? '';

          // Extract direct working audio stream URL
          List downloadUrls = item['downloadUrl'] ?? [];
          String audioUrl = '';
          if (downloadUrls.isNotEmpty) {
            // Get highest available quality URL (320kbps or 160kbps)
            audioUrl = downloadUrls.last['url'] ?? '';
          }

          if (songId.isNotEmpty && audioUrl.isNotEmpty) {
            List images = item['image'] ?? [];
            String thumb = images.isNotEmpty ? images.last['url'] : '';

            songs.add(
              OnlineSong(
                id: songId,
                title: _cleanText(item['name'] ?? 'Unknown Track'),
                artist: _cleanText(item['primaryArtists'] ?? 'Unknown Artist'),
                thumbnailUrl: thumb,
                streamUrl: audioUrl,
              ),
            );
          }
        }
        return songs;
      }
    } catch (_) {}
    return [];
  }

  static String _cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'");
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<OnlineSong> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    final results = await SaavnService.searchSongs(query);

    setState(() {
      _isLoading = false;
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Player')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
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
                onSubmitted: _performSearch,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.purpleAccent))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final song = _searchResults[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              song.thumbnailUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.music_note),
                            ),
                          ),
                          title: Text(song.title,
                            
