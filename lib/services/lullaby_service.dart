import 'package:just_audio/just_audio.dart';

/// A singleton wrapper around `just_audio` so every screen
/// shares the same player instance (and only one lullaby
/// plays at a time).
class LullabyService {
  LullabyService._private();

  static final LullabyService _instance = LullabyService._private();
  static LullabyService get I => _instance;

  final _player = AudioPlayer();
  AudioPlayer get player => _player;

  /// Call this to play an asset.  
  /// If something is already playing it stops first.
  Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.setAsset(assetPath);
    await _player.play();
  }

  Future<void> stop() => _player.stop();

  bool get isPlaying => _player.playing;
}
