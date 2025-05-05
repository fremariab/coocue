import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CotCameraScreen extends StatefulWidget {
  final String pairId;

  const CotCameraScreen({super.key, required this.pairId});

  @override
  State<CotCameraScreen> createState() => _CotCameraScreenState();
}

class _CotCameraScreenState extends State<CotCameraScreen> {
  late RTCPeerConnection _peer;
  MediaStream? _localStream;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late CameraController _cameraController;
  Timer? _timer;
  bool _isCameraReady = false;
  final _storage = FlutterSecureStorage(); // Keep this if you use it elsewhere

  @override
  void initState() {
    super.initState();
    _initCamera(); // Directly initialize camera, no need for separate loading
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(camera, ResolutionPreset.low);
    await _cameraController.initialize(); // Removed null check operator
    debugPrint("-----------------\nCamera initialized\n---------------");
    setState(() {
      _isCameraReady = true;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _captureAndUploadFrame(),
    );
  }

  Future<void> _startBroadcast() async {
    if (widget.pairId.isEmpty) {
      // Check for empty instead of null
      debugPrint('❌ Cannot broadcast: no pairId yet');
      return;
    }

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'environment'},
    });

    _peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    _peer.onIceCandidate = (cand) {
      _db
          .collection('calls')
          .doc(widget.pairId) // Use widget.pairId directly
          .collection('offersCandidates')
          .add(cand.toMap());
    };

    final offer = await _peer.createOffer();
    await _peer.setLocalDescription(offer);
    await _db.collection('calls').doc(widget.pairId).set({
      'offer': offer.toMap(),
    });

    // Listen for answer
    _db.collection('calls').doc(widget.pairId).snapshots().listen((snap) async {
      final data = snap.data();
      if (data != null && data['answer'] != null) {
        final ans = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _peer.setRemoteDescription(ans);
      }
    });

    // Listen for remote ICE
    _db
        .collection('calls')
        .doc(widget.pairId)
        .collection('answersCandidates')
        .snapshots()
        .listen((snap) {
          for (var doc in snap.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final c = RTCIceCandidate(
                doc.doc['candidate'],
                doc.doc['sdpMid'],
                doc.doc['sdpMLineIndex'],
              );
              _peer.addCandidate(c);
            }
          }
        });

    setState(() {});
  }

  Future<void> _captureAndUploadFrame() async {
    try {
      final image = await _cameraController.takePicture();
      final file = File(image.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('cot_feed')
          .child('latest_frame.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update URL in Firestore
      await FirebaseFirestore.instance
          .collection('cot_feed')
          .doc('current_frame')
          .set({'url': downloadUrl, 'timestamp': DateTime.now()});
    } catch (e) {
      debugPrint('Camera upload error: $e');
    }
  }

  Future<RTCVideoRenderer> _createRenderer() async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    renderer.srcObject = _localStream;
    return renderer;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pairId.isEmpty || !_isCameraReady) {
      // Check widget.pairId directly
      return const Scaffold(body: Center(child: Text('Waiting to pair…')));
    }

    return Scaffold(
      body: Center(
        child:
            _localStream == null
                ? ElevatedButton(
                  onPressed: _startBroadcast,
                  child: const Text('Start Broadcast'),
                )
                : FutureBuilder<RTCVideoRenderer>(
                  future: _createRenderer(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return RTCVideoView(snapshot.data!, mirror: false);
                  },
                ),
      ),
    );
  }
}
