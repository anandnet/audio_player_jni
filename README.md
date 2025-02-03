# audio_player_jni

Audio Player Flutter plugin (Experimental) for android using JNI

## Getting Started

Add following to your app `pubspec.yaml` file

```yaml
dependencies:
  audio_player_jni:
    git:
      url: https://github.com/anandnet/audio_player_jni.git
      ref: main
```

## Uses:


```dart
import 'package:audio_player_jni/audio_player.dart';
AudioPlayer player = AudioPlayer();

// single file playback
player.setSingleAudioSource(AudioSource(you_audio_file_url));

// Multiple file playback
final urls = [] //list of urls
player.addAudioSourceList(urls.map((e) => AudioSource(e)).toList());

// Controls
player.play()
player.pause()
player.prev()
player.next()
player.playPause()
player.playWithIndex(int index)
player.seek(Duration position, {int? index})

// Playlist playback
player.addAudioSource(AudioSource source, {int? index})
player.addAudioSourceList(List<AudioSource> sources, {int? index})
player.removeAudioSource(int index)
player.removeAudioSourcewithIndexRange(int from, int to)
player.clearAllAudioSources()

// Stop and dispose player
player.stop()
player.dispose()

// Other apis
player.isPlaying;
player.isBuffering;
player.isCompleted;
player.duration;
player.position;
player.bufferedPosition;
player.playerError;
player.skipSilenceModeEnabled; // set,get
player.repeatMode; // set,get
player.playerState;
player.shuffleEnabled; // set,get
player.audioSessionId;
player.audioSources;  // provide current playlist 

```

## Streams (Experimental)

```dart
//Player State stream
player.playerStateStream.listen((event) {
     print("States:${event.position} ${event.duration} ${event.bufferedPosition} ${event.currentIndex}  ${event.audioProcessingState?.name} ${event.isPlaying}"); 
});

// Player error stream
player.errorStream.listen((event) {
  print("Error:${event.errorCode} ${event.message} \n ${event.stackTrace}");
});
```

### Add internet access permission into AndroidManifest.xml file
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```




