import 'package:just_audio/just_audio.dart';

// made this class a singleton so only one LULLABYSERVICE exists
class LullabyService {
  LullabyService._private();

  // setting up the single instance
  static final LullabyService _instance = LullabyService._private();
  static LullabyService get I => _instance;

  // created this so we can control audio from anywhere
  final _player = AudioPlayer();
  AudioPlayer get player => _player;

  // used this to play any lullaby file
  // stops anything that's already playing first
  Future<void> playAsset(String assetPath) async {
    await _player.stop();
    await _player.setAsset(assetPath);
    await _player.play();
  }

  // added this to stop audio manually
  Future<void> stop() => _player.stop();

  // just to check if anything is playing
  bool get isPlaying => _player.playing;
}
