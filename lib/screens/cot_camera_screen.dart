// lib/screens/cot_camera_screen.dart
import 'package:coocue/services/cry_detection_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:coocue/services/webrtc_service.dart';

class CotCameraScreen extends StatefulWidget {
  final String pairId;
  const CotCameraScreen({Key? key, required this.pairId}) : super(key: key);

  @override
  _CotCameraScreenState createState() => _CotCameraScreenState();
}

class _CotCameraScreenState extends State<CotCameraScreen> {
  bool _streaming = false;

  final _player = AudioPlayer();
  bool _babyCrying = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.subscribeToTopic('pair_${widget.pairId}');
    CryDetectionService().init().then((_) {
      CryDetectionService().onCryDetected.listen((cry) {
        setState(() => _babyCrying = cry);
      });
    });
  }

  Future<void> _start() async {
    setState(() => _streaming = true);
    await WebRTCService.instance.startOffering(widget.pairId);
    setState(() {}); // rebuild to show preview
  }

  Future<RTCVideoRenderer> _makeRenderer() async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();

    renderer.srcObject = WebRTCService.instance.localStream;

    return renderer;
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    WebRTCService.instance.stopOffering();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cot Broadcast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Toggle Cry Overlay',
            onPressed: () => setState(() => _babyCrying = !_babyCrying),
          ),
        ],
      ),
      body: Center(
        child:
            !_streaming
                ? ElevatedButton(
                  onPressed: _start,
                  child: const Text('Start Broadcast'),
                )
                : FutureBuilder<RTCVideoRenderer>(
                  future: _makeRenderer(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();
                    return Stack(
                      children: [
                        RTCVideoView(snap.data!),
                        if (_babyCrying)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.redAccent,
                              child: const Text(
                                '🚨 Baby Crying!',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}
