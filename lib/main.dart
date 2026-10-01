import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

void main() => runApp(const MaterialApp(
      home: MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    ));

class Song {
  final String id;
  final String title;
  final String url;

  Song({
    required this.id,
    required this.title,
    required this.url,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // YOUR DIRECT INTERNET ARCHIVE MUSIC LINK
  final Song _currentSong = Song(
    id: "1",
    title: "ASTARR - Prem Dhillon",
    url: "https://archive.org/download/astarr-official-video-prem-dhillon-cheetah-4-da-gang-latest-punjabi-songs-2024-mp-3.mp-3-1-1/ASTARR%20%28OFFICIAL%20VIDEO%29%20PREM%20DHILLON%20%20CHEETAH%20%204%20Da%20Gang%20%20LATEST%20PUNJABI%20SONGS%202024_MP3.mp3%20%281%29%20%281%29.m4a",
  );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioSession();
    _listenToPlaybackState();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    try {
      await _audioPlayer.setUrl(_currentSong.url);
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  void _listenToPlaybackState() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.durationStream.listen((newDuration) {
      if (mounted && newDuration != null) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.positionStream.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("My Music App"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(
                Icons.music_note,
                size: 100,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _currentSong.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Slider(
              activeColor: Colors.deepPurpleAccent,
              inactiveColor: Colors.white24,
              min: 0.0,
              max: _duration.inSeconds.toDouble() > 0
                  ? _duration.inSeconds.toDouble()
                  : 1.0,
              value: _position.inSeconds
                  .toDouble()
                  .clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
              onChanged: (value) async {
                final newPosition = Duration(seconds: value.toInt());
                await _audioPlayer.seek(newPosition);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.deepPurpleAccent,
              child: IconButton(
                iconSize: 40,
                color: Colors.white,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _togglePlayPause,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
