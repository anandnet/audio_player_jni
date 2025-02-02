import 'dart:async';

abstract class AudioPlayerBase {
  Stream<PlayerState> get playerStateStream;
  Stream<PlayerError> get errorStream;
  bool get isPlaying;
  bool get isBuffering;
  bool get isCompleted;
  Duration? get duration;
  Duration get position;
  Duration get bufferedPosition;
  PlayerError? get playerError;
  bool get skipSilenceModeEnabled;
  RepeatMode get repeatMode;
  PlayerState get playerState;

  bool get shuffleEnabled;
  int? get audioSessionId;

  set skipSilenceEnabled(bool value) {}

  set shuffleEnabled(bool value) {}

  set repeatMode(RepeatMode mode) {}

  List<AudioSource> get audioSources;

  void setSingleAudioSource(AudioSource source, {bool autoPlay = true}) {}

  void addAudioSource(AudioSource source, {int? index}) {}

  void addAudioSourceList(List<AudioSource> sources, {int? index}) {}

  void removeAudioSource(int index) {}

  void removeAudioSourcewithIndexRange(int from, int to) {}

  void clearAllAudioSources() {}

  void play() {}

  void playPause() {}

  void playWithIndex(int index) {}

  void pause() {}

  void prev() {}

  void next() {}

  void seek(Duration position, {int? index}) {}

  void stop() {}

  void dispose() {}
}

class PlayerState {
  final Duration? duration;
  final Duration position;
  final Duration bufferedPosition;
  final bool isPlaying;
  final int currentIndex;
  final AudioProcessingState? audioProcessingState;

  PlayerState(
      {this.duration = Duration.zero,
      this.position = Duration.zero,
      this.bufferedPosition = Duration.zero,
      this.isPlaying = false,
      this.currentIndex = 0,
      this.audioProcessingState});

  PlayerState.fromJson(Map<String, dynamic> json)
      : duration = json['duration'] < 0
            ? null
            : Duration(milliseconds: json['duration']),
        bufferedPosition = Duration(milliseconds: json['bufferedPosition']),
        position = Duration(milliseconds: json['currentPosition']),
        isPlaying = json['isPlaying'],
        currentIndex = json['currentIndex'],
        audioProcessingState = _convertToAudioProcessingState(json['state']);

  PlayerState copyWith(
      {Duration? duration,
      Duration? position,
      Duration? bufferedPosition,
      AudioProcessingState? audioProcessingState,
      int? currentIndex,
      bool? isPlaying}) {
    return PlayerState(
      audioProcessingState: audioProcessingState ?? this.audioProcessingState,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'currentPosition': position,
      'bufferedPosition': bufferedPosition,
      'isPlaying': isPlaying,
      'state': audioProcessingState?.name,
      'currentIndex': currentIndex,
    };
  }

  static AudioProcessingState? _convertToAudioProcessingState(int state) {
    switch (state) {
      case 1:
        return AudioProcessingState.idle;
      case 2:
        return AudioProcessingState.buffering;
      case 3:
        return AudioProcessingState.ready;
      case 4:
        return AudioProcessingState.completed;
      default:
        return null;
    }
  }

  @override
  int get hashCode =>
      duration.hashCode ^
      position.hashCode ^
      bufferedPosition.hashCode ^
      isPlaying.hashCode ^
      audioProcessingState.hashCode ^
      currentIndex.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(hashCode, other.hashCode)) return true;
    return super == other;
  }
}

enum RepeatMode { off, one, all }

enum AudioProcessingState { idle, buffering, ready, completed }

class PlayerError {
  final String message;
  final int errorCode;
  final String stackTrace;

  PlayerError(this.message, this.errorCode, this.stackTrace);

  factory PlayerError.fromJson(Map<String, dynamic> json) {
    return PlayerError(json['message'], json['code'], json['stackTrace']);
  }

  @override
  int get hashCode => message.hashCode ^ errorCode.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(hashCode, other.hashCode)) return true;
    return super == other;
  }
}

class AudioSource {
  final String url;

  AudioSource(this.url);
}
