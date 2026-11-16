import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants/app_constants.dart';

enum AudioState {
  idle,
  loading,
  playing,
  error,
}

enum AudioEvent {
  slowNetwork,
  error,
}

/// Service handling streaming male pronunciation audio playback.
///
/// Follows constraint:
/// - Male voice ONLY (`?gender=male`)
/// - Diacritics preserved, URL-encoded
/// - Streaming playback only (no local disk caching)
class AudioPlayerService extends ChangeNotifier {
  static AudioPlayerService _instance = AudioPlayerService();
  static AudioPlayerService get instance => _instance;

  @visibleForTesting
  static set instance(AudioPlayerService newInstance) {
    _instance = newInstance;
  }

  AudioPlayerService({
    AudioPlayer? player,
    this.slowThreshold = const Duration(seconds: 4),
    this.timeoutThreshold = const Duration(seconds: 12),
    @visibleForTesting this.customLoader,
  }) : _player = player ?? AudioPlayer() {
    _initListener();
  }

  final AudioPlayer _player;
  final Duration slowThreshold;
  final Duration timeoutThreshold;

  @visibleForTesting
  Future<void> Function(String url)? customLoader;

  final StreamController<AudioEvent> _eventController =
      StreamController<AudioEvent>.broadcast();
  Stream<AudioEvent> get eventStream => _eventController.stream;

  Timer? _slowTimer;
  AudioState _state = AudioState.idle;
  String? _currentLemma;
  String? _errorMessage;

  AudioState get state => _state;
  String? get currentLemma => _currentLemma;
  String? get errorMessage => _errorMessage;

  void _initListener() {
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _slowTimer?.cancel();
        _slowTimer = null;
        _state = AudioState.idle;
        _currentLemma = null;
        notifyListeners();
      } else if (playerState.playing) {
        _slowTimer?.cancel();
        _slowTimer = null;
        if (_state != AudioState.playing) {
          _state = AudioState.playing;
          notifyListeners();
        }
      } else if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        if (_currentLemma != null && _state != AudioState.loading) {
          _state = AudioState.loading;
          notifyListeners();
        }
      }
    }, onError: (Object e) {
      _slowTimer?.cancel();
      _slowTimer = null;
      _state = AudioState.idle;
      _errorMessage = e.toString();
      _currentLemma = null;
      notifyListeners();
      _eventController.add(AudioEvent.error);
    });
  }

  @protected
  @visibleForTesting
  Future<void> loadAndPlay(String url) async {
    final custom = customLoader;
    if (custom != null) {
      await custom(url);
      return;
    }
    await _player.setUrl(url);
    await _player.play();
  }

  /// Plays audio for the given clean lemma string.
  Future<void> playAudio(String lemmaClean) async {
    final clean = lemmaClean.trim();
    if (clean.isEmpty) return;

    if (_state == AudioState.playing && _currentLemma == clean) {
      await stop();
      return;
    }

    if (_state == AudioState.loading && _currentLemma == clean) {
      return;
    }

    _slowTimer?.cancel();
    _slowTimer = null;
    try {
      await _player.stop();
    } catch (_) {}

    _currentLemma = clean;
    _state = AudioState.loading;
    _errorMessage = null;
    notifyListeners();

    _slowTimer = Timer(slowThreshold, () {
      if (_state == AudioState.loading && _currentLemma == clean) {
        _eventController.add(AudioEvent.slowNetwork);
      }
    });

    final url = AppConstants.getAudioUrl(clean);

    try {
      await loadAndPlay(url).timeout(timeoutThreshold);
      _slowTimer?.cancel();
      _slowTimer = null;
      if (_state == AudioState.loading && _currentLemma == clean) {
        _state = AudioState.playing;
        notifyListeners();
      }
    } catch (e) {
      _slowTimer?.cancel();
      _slowTimer = null;
      try {
        await _player.stop();
      } catch (_) {}
      _state = AudioState.idle;
      _errorMessage = e.toString();
      _currentLemma = null;
      notifyListeners();
      _eventController.add(AudioEvent.error);
    }
  }

  Future<void> stop() async {
    _slowTimer?.cancel();
    _slowTimer = null;
    try {
      await _player.stop();
    } catch (_) {}
    _state = AudioState.idle;
    _currentLemma = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _slowTimer = null;
    _eventController.close();
    _player.dispose();
    super.dispose();
  }
}
