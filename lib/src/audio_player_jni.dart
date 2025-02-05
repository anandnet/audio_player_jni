import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jni/jni.dart';

import 'native_bindings/exo_player.dart';
import 'audio_player_base.dart';

class AudioPlayer extends AudioPlayerBase {
  AudioPlayerJni? _audioPlayer;
  final StreamController<PlayerState> _stateStreamController =
      StreamController<PlayerState>.broadcast();
  final StreamController<PlayerError> _errorStreamController =
      StreamController<PlayerError>.broadcast();
  PlayerState _playerState = PlayerState();
  final StreamController<List<AudioSource>> _queueStreamController =
      StreamController<List<AudioSource>>.broadcast();
  PlayerError? _playerLastError;

  Timer? _timer;

  @override
  Stream<PlayerState> get playerStateStream => _stateStreamController.stream;

  @override
  Stream<PlayerError> get errorStream => _errorStreamController.stream;

  @override
  Stream<List<AudioSource>> get queueStream => _queueStreamController.stream;

  @override
  bool get isPlaying => _playerState.isPlaying;
  @override
  bool get isBuffering =>
      _playerState.audioProcessingState == AudioProcessingState.buffering;
  @override
  bool get isCompleted =>
      _playerState.audioProcessingState == AudioProcessingState.completed;
  @override
  Duration? get duration => _playerState.duration;
  @override
  Duration get position => _playerState.position;
  @override
  Duration get bufferedPosition => _playerState.bufferedPosition;
  @override
  PlayerState get playerState => _playerState;
  @override
  PlayerError? get playerError => _playerLastError;
  @override
  bool get skipSilenceModeEnabled =>
      _audioPlayer?.isSkipSilenceEnabled() ?? false;
  @override
  RepeatMode get repeatMode {
    final repeatMode = _audioPlayer?.getRepeatMode();
    switch (repeatMode) {
      case 0:
        return RepeatMode.off;
      case 1:
        return RepeatMode.one;
      case 2:
        return RepeatMode.all;
      default:
        return RepeatMode.off;
    }
  }

  @override
  bool get shuffleEnabled => _audioPlayer?.isShuffleModeEnabled() ?? false;
  @override
  int? get audioSessionId => _audioPlayer?.getPlayerSessionId();

  @override
  set skipSilenceModeEnabled(bool value) {
    _audioPlayer?.toggleSkipSilence(value);
  }

  @override
  set shuffleEnabled(bool value) {
    _audioPlayer?.toggleShuffleMode(value);
  }

  @override
  set repeatMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        _audioPlayer?.toggleRepeatMode(0);
        break;
      case RepeatMode.one:
        _audioPlayer?.toggleRepeatMode(1);
        break;
      case RepeatMode.all:
        _audioPlayer?.toggleRepeatMode(2);
        break;
    }
  }

  @override
  List<AudioSource> get audioSources {
    final jsources = _audioPlayer?.getPlayList();
    final sources =
        jsonDecode(jsources?.toDartString(releaseOriginal: true) ?? "[]")
            as List;
    final sourceList = sources.map((e) {
      return AudioSource(e);
    }).toList();
    return List.unmodifiable(sourceList);
  }

  AudioPlayer() {
    _init();
  }

  void _init() {
    if (!Platform.isAndroid) {
      throw Exception("This plugin only supports Android");
    }
    JObject context = JObject.fromReference(Jni.getCurrentActivity());
    _audioPlayer = AudioPlayerJni(context);
    context.release();
    _startStateLoop();
  }

  Future<void> _startStateLoop() async {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final nativeState = _audioPlayer?.getAllStates();
      final dartState = jsonDecode(nativeState.toString());
      nativeState?.release();

      // Check for errors
      if (dartState['error'] != null) {
        final PlayerError? copy = _playerLastError;
        _playerLastError = PlayerError.fromJson(dartState['error']);
        if (_playerLastError == copy) return;
        _errorStreamController.add(PlayerError.fromJson(dartState['error']));
      } else {
        _playerLastError = null;
      }

      // Check for state changes
      final PlayerState copy = _playerState;
      _playerState = PlayerState.fromJson(dartState);
      if (copy != _playerState) {
        _stateStreamController.add(_playerState);
      }
    });
  }

  @override
  void setSingleAudioSource(AudioSource source, {bool autoPlay = true}) {
    if (_audioPlayer == null) {
      _init();
    }
    final jurl = JString.fromString(source.url);
    _audioPlayer?.setUrl(jurl, autoPlay);
    jurl.release();
    _queueStreamController.add(audioSources);
  }

  @override
  void addAudioSource(AudioSource source, {int? index}) {
    if (_audioPlayer == null) {
      _init();
    }
    final jurl = JString.fromString(source.url);
    final jindex = index == null ? null : JInteger(index);
    _audioPlayer?.addMediaItem(jurl, jindex);
    jurl.release();
    jindex?.release();
    _queueStreamController.add(audioSources);
  }

  @override
  void addAudioSourceList(List<AudioSource> sources,
      {int? index, bool autoPlay = true}) {
    if (_audioPlayer == null) {
      _init();
    }
    final jindex = index == null ? null : JInteger(index);
    final sourcesJson = jsonEncode(sources.map((e) {
      return e.url;
    }).toList());
    final jSources = JString.fromString(sourcesJson);
    _audioPlayer?.addMediaItems(jSources, jindex);
    jindex?.release();
    jSources.release();
    _queueStreamController.add(audioSources);
  }

  @override
  void removeAudioSource(int index) {
    _audioPlayer?.removeMediaItem(index);
    _queueStreamController.add(audioSources);
  }

  @override
  void moveAudioSource(int currentIndex, int newIndex) {
    _audioPlayer?.moveMediaItem(currentIndex, newIndex);
    _queueStreamController.add(audioSources);
  }

  @override
  void removeAudioSourcewithIndexRange(int from, int to) {
    _audioPlayer?.removeMediaItemRange(from, to);
    _queueStreamController.add(audioSources);
  }

  @override
  void clearAllAudioSources() {
    _audioPlayer?.removeAllMediaItems();
    _queueStreamController.add(audioSources);
  }

  @override
  void play() {
    if (_playerLastError != null) {
      _audioPlayer?.retryPlay();
    }
    _audioPlayer?.play();
  }

  void retryPlay() {
    _audioPlayer?.retryPlay();
  }

  @override
  void playPause() {
    _audioPlayer?.playPause();
  }

  @override
  void playWithIndex(int index) {
    final jindex = JInteger(index);
    _audioPlayer?.seekTo(0, jindex);
    jindex.release();
  }

  @override
  void pause() {
    _audioPlayer?.pause();
  }

  @override
  void prev() {
    _audioPlayer?.skipToPrevious();
    if (_playerLastError != null) {
      _audioPlayer?.retryPlay();
    }
  }

  @override
  void next() {
    _audioPlayer?.skipToNext();
    if (_playerLastError != null) {
      _audioPlayer?.retryPlay();
    }
  }

  @override
  void seek(Duration position, {int? index}) {
    final jindex = index == null ? null : JInteger(index);
    _audioPlayer?.seekTo(position.inMilliseconds, jindex);
    jindex?.release();
  }

  @override
  void stop() {
    _audioPlayer?.stop();
  }

  @override
  void dispose() {
    _audioPlayer?.release$1();
    _timer?.cancel();
    _stateStreamController.close();
    _errorStreamController.close();
    _queueStreamController.close();
    _audioPlayer?.release();
  }
}
