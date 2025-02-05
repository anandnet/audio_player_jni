// ignore_for_file: avoid_print

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
  String task = 'Welcome to the audio player example';
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
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3',
  ];

  List<AudioSource> _playlist = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _audioPlayer = AudioPlayer();
    _playerState = _audioPlayer.playerState;
    _audioPlayer.playerStateStream.listen((event) {
      setState(() {
        _playerState = event;
        final oldIndex = _currentIndex;
        _currentIndex = event.currentIndex;
        if (_currentIndex != oldIndex) {
          _scrollController.animateTo((50 * _currentIndex).toDouble(),
              duration: Duration(milliseconds: 200), curve: Curves.bounceIn);
        }
      });
    });

    _audioPlayer.errorStream.listen((event) {
      print("Error:${event.errorCode} ${event.message} \n ${event.stackTrace}");
    });

    _audioPlayer.queueStream.listen((updatedPlaylist) {
      setState(() {
        _playlist = updatedPlaylist;
      });
    });

    _audioPlayer.addAudioSourceList(_urls.map((e) => AudioSource(e)).toList());
  }

  void updateTask(String newTask) {
    setState(() {
      task = newTask;
    });
    print('\x1B[32m$task\x1B[0m');
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
            SizedBox(height: 30, child: Center(child: Text(task))),
            Expanded(
                child: ListView.builder(
              controller: _scrollController,
              itemCount: _playlist.length,
              itemBuilder: (context, index) {
                return ListTile(
                  tileColor: index == _currentIndex
                      ? Theme.of(context).colorScheme.primaryFixed
                      : null,
                  title: Text(_playlist[index].url.split('/').last),
                  onTap: () {
                    _audioPlayer.playWithIndex(index);
                    if (!_audioPlayer.isPlaying) {
                      _audioPlayer.play();
                    }
                  },
                );
              },
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                    onPressed: () {
                      _audioPlayer.shuffleEnabled = !_audioPlayer.shuffleEnabled;
                    },
                    icon: _playerState.shuffleModeEnabled
                        ? const Icon(Icons.shuffle_on)
                        : const Icon(Icons.shuffle)),
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
                IconButton(
                    onPressed: () {
                      _audioPlayer.repeatMode = RepeatMode.values[
                          (_audioPlayer.repeatMode.index + 1) %
                              RepeatMode.values.length];
                    },
                    icon: Icon(_playerState.repeatMode == RepeatMode.all
                        ? Icons.repeat
                        : _playerState.repeatMode == RepeatMode.one
                            ? Icons.repeat_one
                            : Icons.cancel)
                )
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
      floatingActionButton: FloatingActionButton.extended(
          label: const Text('Test all apis'),
          onPressed: () async {
            updateTask("Starting audio player tasks...");

            // Set a single audio source
            updateTask("Task: Set a single audio source");
            _audioPlayer.setSingleAudioSource(AudioSource(_urls[0]),
                autoPlay: false);
            await Future.delayed(const Duration(seconds: 4));

            // Add a single audio source
            updateTask("Task: Add a audio source in the queue");
            _audioPlayer.addAudioSource(AudioSource(_urls[1]));
            await Future.delayed(const Duration(seconds: 4));

            // Add a list of audio sources
            updateTask("Task: Add a list of audio sources in the queue");
            _audioPlayer
                .addAudioSourceList(_urls.map((e) => AudioSource(e)).toList());
            await Future.delayed(const Duration(seconds: 4));

            // Remove an audio source by index
            updateTask("Task: Remove an audio source by index 1");
            _audioPlayer.removeAudioSource(1);
            await Future.delayed(const Duration(seconds: 4));

            // Remove a range of audio sources by index
            updateTask("Task: Remove a range of audio sources by index 0 to 5");
            _audioPlayer.removeAudioSourcewithIndexRange(0, 5);
            await Future.delayed(const Duration(seconds: 4));

            // Clear all audio sources
            updateTask("Task: Clear all audio sources");
            _audioPlayer.clearAllAudioSources();
            await Future.delayed(const Duration(seconds: 4));

            // Add a list of audio sources again
            updateTask("Task: Add 1000 of audio sources in the queue");
            // generate list of 1000 urls from the same list of 17 urls
            final urls1000 = List.generate(1000, (index) {
              return AudioSource(_urls[index % _urls.length]);
            });
            _audioPlayer.addAudioSourceList(urls1000);
            print("current queue count: ${_audioPlayer.audioSources.length}");
            await Future.delayed(const Duration(seconds: 4));

            // Move an audio source from index 0 to 5
            updateTask("Task: Move an audio source from index 0 to 5");
            _audioPlayer.moveAudioSource(0, 5);
            await Future.delayed(const Duration(seconds: 4));

            // Play the audio
            updateTask("Task: Play the audio");
            _audioPlayer.play();
            await Future.delayed(const Duration(seconds: 4));

            // Pause the audio
            updateTask("Task: Pause the audio");
            _audioPlayer.pause();
            await Future.delayed(const Duration(seconds: 4));

            // Toggle play/pause
            updateTask("Task: Toggle play/pause");
            _audioPlayer.playPause();
            await Future.delayed(const Duration(seconds: 4));

            // Play audio at specific index
            updateTask("Task: Play audio at specific index (5)");
            _audioPlayer.playWithIndex(5);
            await Future.delayed(const Duration(seconds: 4));

            // Play previous audio
            updateTask("Task: Play previous audio");
            _audioPlayer.prev();
            await Future.delayed(const Duration(seconds: 4));

            // Play next audio
            updateTask("Task: Play next audio");
            _audioPlayer.next();
            await Future.delayed(const Duration(seconds: 4));

            // Seek to a specific duration
            updateTask("Task: Seek to a specific duration (100 seconds)");
            _audioPlayer.seek(const Duration(seconds: 100));
            await Future.delayed(const Duration(seconds: 4));

            // Print current audio sources
            updateTask("Task: Print current audio sources");
            print(
                "Current audio sources: ${_audioPlayer.audioSources.map((e) => e.url).toList()}");
            await Future.delayed(const Duration(seconds: 4));

            // Print player state
            updateTask("Task: Print player state");
            print("Player state: ${_audioPlayer.playerState.toJson()}");
            await Future.delayed(const Duration(seconds: 4));

            // Print shuffle enabled status
            updateTask("Task: Print shuffle enabled status");
            print("Shuffle enabled: ${_audioPlayer.shuffleEnabled}");
            await Future.delayed(const Duration(seconds: 4));

            //Enable shuffle
            updateTask("Task: Enable shuffle");
            _audioPlayer.shuffleEnabled = true;
            print("Shuffle enabled: ${_audioPlayer.shuffleEnabled}");
            _audioPlayer.next();
            await Future.delayed(const Duration(seconds: 6));
            _audioPlayer.next();
            await Future.delayed(const Duration(seconds: 6));
            _audioPlayer.next();
            await Future.delayed(const Duration(seconds: 4));

            // Print repeat mode
            updateTask("Task: Print repeat mode");
            print("Repeat mode: ${_audioPlayer.repeatMode}");
            await Future.delayed(const Duration(seconds: 8));

            // Set repeat mode to one
            updateTask("Task: Set repeat mode to one");
            _audioPlayer.repeatMode = RepeatMode.one;
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 4));
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 4));

            // Set repeat mode to all
            updateTask("Task: Set repeat mode to all");
            _audioPlayer.repeatMode = RepeatMode.all;
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 8));
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 8));
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 8));
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 8));
            _audioPlayer.seek(Duration(
                seconds: _audioPlayer.playerState.duration!.inSeconds - 2));
            await Future.delayed(const Duration(seconds: 4));

            // Print audio session ID
            updateTask("Task: Print audio session ID");
            print("Audio session ID: ${_audioPlayer.audioSessionId}");
            await Future.delayed(const Duration(seconds: 4));

            // Enable skip silence
            updateTask("Task: Enable skip silence");
            _audioPlayer.skipSilenceModeEnabled = true;
            print(
                "Skip silence mode enabled: ${_audioPlayer.skipSilenceModeEnabled}");
            await Future.delayed(const Duration(seconds: 4));

            // Stop the audio
            updateTask("Task: Stop the audio");
            _audioPlayer.stop();
            await Future.delayed(const Duration(seconds: 4));

            // Dispose the audio player
            updateTask("Task: Dispose the audio player");
            _audioPlayer.dispose();
            await Future.delayed(const Duration(seconds: 4));

            updateTask(
                "Restart to test again as audio player has been disposed");
          }),
    );
  }
}
