import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ParentStreamViewScreen extends StatefulWidget {
  final RTCVideoRenderer remoteRenderer;
  final Future<void> Function() onToggleTalk;
  final bool isTalking;
  final Future<void> Function() onPlayLullaby;

  const ParentStreamViewScreen({
    super.key,
    required this.remoteRenderer,
    required this.onToggleTalk,
    required this.isTalking,
    required this.onPlayLullaby,
  });

  @override
  State<ParentStreamViewScreen> createState() =>
      _ParentStreamViewScreenState();
}

class _ParentStreamViewScreenState extends State<ParentStreamViewScreen> {
  bool _muted = false;
  double _volume = 100;

  void _toggleMute() {
    setState(() => _muted = !_muted);
    // simply disable incoming audio track when muted
    widget.remoteRenderer.srcObject
        ?.getAudioTracks()
        .forEach((t) => t.enabled = !_muted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Full-screen video
        Positioned.fill(
          child: RTCVideoView(
            widget.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),

        // Top bar with back button
        SafeArea(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // Bottom controls
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mute / Unmute speaker
                IconButton(
                  icon: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),

                // Talk
                IconButton(
                  icon: Icon(
                    widget.isTalking ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                  onPressed: widget.onToggleTalk,
                ),

                // Play a lullaby
                IconButton(
                  icon: const Icon(Icons.music_note, color: Colors.white),
                  onPressed: widget.onPlayLullaby,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
