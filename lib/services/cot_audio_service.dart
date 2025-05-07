import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:just_audio/just_audio.dart';

// made this a singleton so only one COTAUDIOSERVICE runs at a time
class CotAudioService {
  CotAudioService._();
  static final CotAudioService _instance = CotAudioService._();
  factory CotAudioService() => _instance;

  // created the AUDIOPLAYER instance and firebase subscription
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _sub;

  // call this once when you have the PAIRID to set everything up
  Future<void> init(String pairId) async {
    await _configureAudioSession();

    // subscribing to the topic for the pair to receive messages
    FirebaseMessaging.instance.subscribeToTopic('pair_$pairId');

    // listening for audio commands in the pair's command collection
    _sub = FirebaseFirestore.instance
        .collection('pairs')
        .doc(pairId)
        .collection('commands')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(_handleSnapshot);
  }

  // sets up the audio session for music playback
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // handles what to do when a new command is received
  Future<void> _handleSnapshot(QuerySnapshot snap) async {
    if (snap.docs.isEmpty) return;
    final cmd = snap.docs.first.data() as Map<String, dynamic>;

    // if the command is to stop, then stop the player
    if (cmd['type'] == 'stop') {
      await _player.stop();
      return;
    }

    // if the command isn't play, just skip it
    if (cmd['type'] != 'play') return;

    // figuring out the path to the audio file
    final path =
        (cmd['downloadUrl'] as String?) ?? (cmd['assetPath'] as String?);
    if (path == null || path.isEmpty) return;

    try {
      // stop anything currently playing
      await _player.stop();
      await _player.setVolume(1.0);

      if (path.startsWith('assets/')) {
        // if it's a local asset file
        print('loading asset: $path');
        await _player.setAsset(path);
      } else {
        // if it's an online file
        print('loading url: $path');
        await _player.setUrl(path);
      }

      // play the track
      await _player.play();
    } catch (e) {
      print('COTAUDIOSERVICE playback error: $e');
    }
  }

  // use this if you want to clean everything up completely
  Future<void> dispose() async {
    await _sub?.cancel();
    await _player.dispose();
  }
}
