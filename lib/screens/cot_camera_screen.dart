import 'package:coocue/services/cry_api_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:coocue/services/webrtc_service.dart';
import 'dart:async'; // Add this import for StreamSubscription

class CotCameraScreen extends StatefulWidget {
  final String pairId;
  const CotCameraScreen({Key? key, required this.pairId}) : super(key: key);

  @override
  _CotCameraScreenState createState() => _CotCameraScreenState();
}

class _CotCameraScreenState extends State<CotCameraScreen> {
  bool _streaming = false;
  bool _isLoading = false;

  final _player = AudioPlayer();
  bool _babyCrying = false;

  // Store the renderer to avoid recreating it
  RTCVideoRenderer? _renderer;

  // Store stream subscription for proper cleanup
  StreamSubscription? _crySubscription;

  // API endpoint for cry detection
  static const String _apiUrl =
      'https://coocuecrydetectorapi-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    _setupServices();
  }

  Future<void> _setupServices() async {
    // Subscribe to push notifications for this pair
    await FirebaseMessaging.instance.subscribeToTopic('pair_${widget.pairId}');

    // Initialize the cry detection service
    try {
      // Listen for cry events before starting detection
      _crySubscription = CryApiService().onCryDetected.listen((crying) {
        if (mounted) {
          setState(() => _babyCrying = crying);

          // Play alert sound when crying starts
          if (crying) {
            print('crying');
          }
        }
      });

      // Start the detection
      await CryApiService().startDetection(
        apiUrl: _apiUrl,
        sampleSeconds: 2,
        interval: const Duration(seconds: 3),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFF3F51B5),
            content: Text('Error starting cry detection: $e'),
          ),
        );
      }
    }

    // Initialize renderer
    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();
  }

  Future<void> _start() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await WebRTCService.instance.startOffering(widget.pairId);

      // Once the WebRTC service is initialized, update the renderer
      if (_renderer != null && WebRTCService.instance.localStream != null) {
        _renderer!.srcObject = WebRTCService.instance.localStream;
      }

      setState(() {
        _streaming = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFF3F51B5),
            content: Text('Error starting broadcast: $e'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stop() async {
    WebRTCService.instance.stopOffering();
    setState(() => _streaming = false);
  }

  // Assuming that Firestore listens for incoming commands

  // Play lullaby function
  Future<void> _playLullaby(String assetPath) async {
    // Make sure to play the audio from the given asset path
    final player = AudioPlayer();
    try {
      await player.setUrl(assetPath);
      await player.play();
      print('Playing Lullaby: $assetPath');
    } catch (e) {
      print('Error playing lullaby: $e');
    }
  }

  @override
  Future<void> dispose() async {
    // Cancel subscription first
    await _crySubscription?.cancel();
    _crySubscription = null;

    // Clean up resources
    await _player.dispose();
    await CryApiService().stopDetection();
    WebRTCService.instance.stopOffering();

    // Dispose the renderer
    if (_renderer != null) {
      _renderer!.dispose();
      _renderer = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cot Broadcast'),
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
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _start,
                      child:
                          _isLoading
                              ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Starting...'),
                                ],
                              )
                              : const Text('Start Broadcast'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start broadcasting to monitor your baby',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
                : _renderer != null
                ? Stack(
                  children: [
                    RTCVideoView(_renderer!),
                    if (_babyCrying)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xffFFB74D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.volume_up, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Baby Crying!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
                : const CircularProgressIndicator(),
      ),
      floatingActionButton:
          _streaming
              ? FloatingActionButton(
                onPressed: _stop,
                backgroundColor: Color(0xffFFB74D),
                child: const Icon(Icons.stop),
              )
              : null,
    );
  }
}
