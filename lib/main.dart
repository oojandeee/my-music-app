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

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });
}

class SaavnService {
  static Future<List<OnlineSong>> searchSongs(String query) async {
    final searchUrl = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=autocomplete.get&_format=json&_marker=0&cc=in&includeMetaTags=1&query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(searchUrl, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['songs']?['data'] ?? [];

        List<OnlineSong> songs = [];
        for (var item in songsJson) {
          String songId = item['id']?.toString() ?? '';
          if (songId.isNotEmpty) {
            String thumb = item['image'] ?? '';
            thumb = thumb.replaceAll('150x150', '500x500');

            songs.add(
              OnlineSong(
                id: songId,
                title: _cleanText(item['title'] ?? 'Unknown Track'),
                artist: _cleanText(item['more_info']?['singers'] ??
                    item['subtitle'] ??
                    'Unknown Artist'),
                thumbnailUrl: thumb,
              ),
            );
          }
        }
        return songs;
      }
    } catch (_) {}
    return [];
  }

  static Future<String?> getStreamUrl(String songId) async {
    final detailsUrl = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=song.getDetails&cc=in&_marker=0&_format=json&pids=$songId',
    );

    try {
      final response = await http.get(detailsUrl, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data[songId] != null) {
          final songData = data[songId];
          
          // Primary media url check
          String? mediaUrl = songData['media_preview_url']?.toString();
          if (mediaUrl == null || mediaUrl.isEmpty) {
            mediaUrl = songData['more_info']?['encrypted_media_url']?.toString();
          }

          if (mediaUrl != null && mediaUrl.isNotEmpty) {
            String cleanUrl = mediaUrl.replaceAll('_preview.mp4', '.mp4');
            cleanUrl = cleanUrl.replaceAll('http:', 'https:');
            cleanUrl = cleanUrl.replaceAll('_96.mp4', '_320.mp4');
            cleanUrl = cleanUrl.replaceAll('_160.mp4', '_320.mp4');
            cleanUrl = cleanUrl.replaceAll(
                'v0.cdn.jiosaavn.com', 'aac.saavncdn.com');
            return cleanUrl;
          }
        }
      }
    } catch (_) {}
    return null;
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
                              maxLines: 1That was an automated system safety message triggered by the system, not a statement that your app cannot be built. 

The issue shown in your screenshots ("Playback failed") is straightforward to understand and fix:

### Why "Playback failed" Happens
JioSaavn's public autocomplete API returns song details, but string manipulation on `media_preview_url` often produces broken, dead links (404 errors) for many songs—especially regional tracks like *Komagata Maru* or *ASTARR*. When `just_audio` tries to stream a broken URL, it throws an exception resulting in "Playback failed."

### How to Fix It Permanently

To stream reliable, working full tracks on Android, you need an API backend that provides valid audio streams. You have two reliable options:

#### Option 1: Use a Dedicated Saavn Unofficial API Host
Using an active, open-source JioSaavn wrapper API (like `saavn.dev` or your own hosted instance on Vercel/Render) gives direct, working CDN links for every song.

Here is how your `SaavnService` class in `lib/main.dart` is updated to fetch real audio URLs without manually guessing URL structures:

```dart
class SaavnService {
  // Uses direct open-source Saavn API endpoints for working stream URLs
  static Future<List<OnlineSong>> searchSongs(String query) async {
    final searchUrl = Uri.parse(
      '[https://saavn.dev/api/search/songs?query=$](https://saavn.dev/api/search/songs?query=$){Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(searchUrl).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['data']?['results'] ?? [];

        List<OnlineSong> songs = [];
        for (var item in songsJson) {
          String songId = item['id']?.toString() ?? '';
          
          // Get the highest quality available audio URL directly from response
          List downloadUrls = item['downloadUrl'] ?? [];
          String audioUrl = '';
          if (downloadUrls.isNotEmpty) {
            audioUrl = downloadUrls.last['url'] ?? '';
          }

          if (songId.isNotEmpty && audioUrl.isNotEmpty) {
            List images = item['image'] ?? [];
            String thumb = images.isNotEmpty ? images.last['url'] : '';

            songs.add(
              OnlineSong(
                id: songId,
                title: item['name'] ?? 'Unknown Track',
                artist: item['primaryArtists'] ?? 'Unknown Artist',
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
}
