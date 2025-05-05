// lib/screens/cot_camera_screen.dart

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

  @override
  void initState() {
    super.initState();
    // subscribe to pairing topic
    FirebaseMessaging.instance.subscribeToTopic('pair_${widget.pairId}');
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
  renderer.muted = true;          // ← bool property, not a method
        // belt‑and‑suspenders
    return renderer;
  }

  @override
  void dispose() {
    WebRTCService.instance.stopOffering();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Cot Broadcast')),
      body: Center(
        child:
            !_streaming
                ? ElevatedButton(
                  onPressed: _start,
                  child: Text('Start Broadcast'),
                )
                : FutureBuilder<RTCVideoRenderer>(
                  future: _makeRenderer(),
                  
                  builder: (_, snap) {
                    if (!snap.hasData) return CircularProgressIndicator();
                    return RTCVideoView(snap.data!);
                  },
                ),
      ),
    );
  }
}
