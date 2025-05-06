import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:just_audio/just_audio.dart';

class CotAudioService {
  // 1️⃣ Singleton boilerplate
  CotAudioService._();
  static final CotAudioService _instance = CotAudioService._();
  factory CotAudioService() => _instance;

  // 2️⃣ Core fields
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _sub;

  /// Call this once, as soon as you know the `pairId`.
  Future<void> init(String pairId) async {
    await _configureAudioSession();
    FirebaseMessaging.instance.subscribeToTopic('pair_$pairId');
    _sub = FirebaseFirestore.instance
        .collection('pairs')
        .doc(pairId)
        .collection('commands')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(_handleSnapshot);
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> _handleSnapshot(QuerySnapshot snap) async {
    if (snap.docs.isEmpty) return;
    final cmd = snap.docs.first.data() as Map<String, dynamic>;

    if (cmd['type'] == 'stop') {
      await _player.stop();
      return;
    }

    if (cmd['type'] != 'play') return;
    // … your existing play logic …

    final path =
        (cmd['downloadUrl'] as String?) ?? (cmd['assetPath'] as String?);
    if (path == null || path.isEmpty) return;

    try {
      await _player.stop();
      await _player.setVolume(1.0);

      if (path.startsWith('assets/')) {
        // local packaged asset
        print('🗂 Loading asset: $path');
        await _player.setAsset(path);
      } else {
        // remote HTTP URL
        print('🌐 Loading URL: $path');
        await _player.setUrl(path);
      }

      await _player.play();
    } catch (e) {
      print('❌ CotAudioService playback error: $e');
    }
  }

  /// Dispose if you ever need to shut down the app entirely
  Future<void> dispose() async {
    await _sub?.cancel();
    await _player.dispose();
  }
}
