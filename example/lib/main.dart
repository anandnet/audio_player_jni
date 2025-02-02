import 'package:audio_player_jni/audio_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late AudioPlayer _audioPlayer;
  late PlayerState _playerState;
  int _currentIndex = 0;
  final List<String> _urls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playerState = _audioPlayer.playerState;
    _audioPlayer.playerStateStream.listen((event) {
      setState(() {
        _playerState = event;
        _currentIndex = event.currentIndex;
      });
    });

    _audioPlayer.errorStream.listen((event) {
      print("Error:${event.errorCode} ${event.message} \n ${event.stackTrace}");
    });
    _audioPlayer.addAudioSourceList(_urls.map((e) => AudioSource(e)).toList());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
              itemCount: _urls.length,
              itemBuilder: (context, index) {
                return ListTile(
                  tileColor: index == _currentIndex
                      ? Theme.of(context).colorScheme.primaryFixed
                      : null,
                  title: Text('Song ${index + 1}'),
                  onTap: () {
                    _audioPlayer.playWithIndex(index);
                  },
                );
              },
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                    onPressed: () {
                      _audioPlayer.prev();
                    },
                    icon: const Icon(Icons.skip_previous)),
                IconButton(
                    onPressed: () {
                      _playerState.isPlaying
                          ? _audioPlayer.pause()
                          : _audioPlayer.play();
                    },
                    icon: _playerState.audioProcessingState ==
                            AudioProcessingState.buffering
                        ? const SizedBox.square(
                            dimension: 15, child: CircularProgressIndicator())
                        : Icon(_playerState.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow)),
                IconButton(
                    onPressed: () {
                      _audioPlayer.next();
                      //print(_audioPlayer.audioSources);
                    },
                    icon: const Icon(Icons.skip_next)),
              ],
            ),
            SizedBox(
              width: 200,
              child: StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final durationState = snapshot.data;
                  final progress = durationState?.position ?? Duration.zero;
                  final buffered =
                      durationState?.bufferedPosition ?? Duration.zero;
                  final total = durationState?.duration ?? Duration.zero;
                  return ProgressBar(
                    progress: progress,
                    buffered: buffered,
                    total: total,
                    thumbRadius: 7,
                    barHeight: 4,
                    onSeek: (duration) {
                      _audioPlayer.seek(duration);
                    },
                  );
                },
              ),
            ),
            const SizedBox(
              height: 80,
            ),
          ],
        ),
      ),
    );
  }
}
