import 'package:coocue/screens/app_library_screen.dart';
// added this to pick lullabies from the built-in app collection

import 'package:flutter/material.dart';
// added this for basic flutter UI components

import 'dart:math' as math;
// added this to shorten long error message strings nicely

import 'package:firebase_messaging/firebase_messaging.dart';
// added this to handle push notifications for pairing

import 'package:coocue/screens/pair_screen.dart';
// added this to navigate to the pairing setup page

import 'package:cloud_firestore/cloud_firestore.dart';
// added this to read and write data in firestore

import 'package:flutter_webrtc/flutter_webrtc.dart';
// added this to manage real-time video and audio streams

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// added this to securely store the paired device id

import 'package:coocue/screens/parent_stream_view_screen.dart';
// added this to show the live camera feed screen

import 'package:coocue/screens/lullaby_library_screen.dart';
// added this to navigate to the custom lullaby library

import 'package:coocue/models/lullaby.dart';
// added this to use the lullaby data model

import 'package:coocue/services/library_manager.dart';
// added this to manage the personal collection of lullabies

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});
  // added this to define a stateful widget for the parent home screen

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
  // added this to connect the widget with its mutable state
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  String? pairedId;
  // added this to hold the paired cot device id

  bool isLoading = true;
  // added this to show a loading indicator while initializing

  bool isViewingActive = false;
  // added this to track if live preview is currently active

  final _storage = FlutterSecureStorage();
  // added this to read and write secure storage values

  late final Stream<String> imageStream;
  // added this to listen for new camera frame URLs

  RTCPeerConnection? _peer;
  // added this to hold the webRTC peer connection

  MediaStream? _remoteStream;
  // added this to store the incoming media stream

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // added this to use a firestore instance in this class

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  // added this to render the video feed widget

  MediaStreamTrack? _talkTrack;
  // added this to hold the outgoing audio track for talk mode

  RTCRtpSender? _talkSender;
  // added this to send the talk track over webRTC

  RTCRtpTransceiver? _audioTransceiver;
  bool _isAudioMuted = true; // Track if cot audio is muted

  bool _isTalking = false;
  // added this to track whether the mic is unmuted

  @override
  void initState() {
    super.initState();
    // added this to initialize the video renderer then finish setup
    _remoteRenderer.initialize().then((_) {
      _initializeApp();
    });

    // added this to set up a stream of image URLs from firestore
    imageStream = _db
        .collection('cot_feed')
        .doc('current_frame')
        .snapshots()
        .map((snap) => snap.data()?['url'] as String? ?? '');
  }

  @override
  void dispose() {
    // added this to close connections and dispose the renderer
    _closeConnection();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // added this to load paired id and stop showing spinner
    await _loadPairedId();
    setState(() => isLoading = false);
  }

  Future<void> _setTransceiverDirection(TransceiverDirection direction) async {
    if (_audioTransceiver != null) {
      try {
        await _audioTransceiver!.setDirection(direction);
        debugPrint('Set transceiver direction to: $direction');
      } catch (e) {
        debugPrint('Error setting transceiver direction: $e');
      }
    }
  }

  // Update the talk toggle functions
  Future<void> _toggleTalk() async {
    if (_isTalking) {
      await _stopTalking();
    } else {
      await _startTalking();
    }
  }

  Future<void> _startTalking() async {
    if (_talkTrack == null) return;

    try {
      // Enable parent microphone
      _talkTrack!.enabled = true;

      // Change transceiver direction to send/receive
      await _setTransceiverDirection(TransceiverDirection.SendRecv);

      // Mute incoming audio to prevent echo while talking
      if (_remoteStream != null) {
        _remoteStream!.getAudioTracks().forEach((track) {
          track.enabled = false;
        });
        _isAudioMuted = true;
      }

      setState(() => _isTalking = true);
      debugPrint('Started talking mode');
    } catch (e) {
      debugPrint('Error starting talk: $e');
    }
  }

  Future<void> _stopTalking() async {
    if (_talkTrack == null) return;

    try {
      // Disable parent microphone
      _talkTrack!.enabled = false;

      // Change transceiver to receive only
      await _setTransceiverDirection(TransceiverDirection.RecvOnly);

      // Unmute incoming audio to hear the baby
      if (_remoteStream != null) {
        _remoteStream!.getAudioTracks().forEach((track) {
          track.enabled = true;
        });
        _isAudioMuted = false;
      }

      setState(() => _isTalking = false);
      debugPrint('Stopped talking mode');
    } catch (e) {
      debugPrint('Error stopping talk: $e');
    }
  }

  // Update the close connection function to clean up properly
  Future<void> _closeConnection() async {
    // Stop talking if active
    if (_isTalking) await _stopTalking();

    // Clean up remote stream
    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) {
        track.stop();
      });
      _remoteStream = null;
    }

    // Reset video renderer
    _remoteRenderer.srcObject = null;

    // Close peer connection
    try {
      _audioTransceiver = null;
      await _peer?.close();
      _peer = null;
    } catch (e) {
      debugPrint('Error closing peer connection: $e');
    }

    setState(() => isViewingActive = false);
  }

  // Also update this function to properly handle audio tracks
  void _setRemoteAudioEnabled(bool enabled) {
    // Mute or unmute the remote audio track
    if (_remoteStream != null) {
      _remoteStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  Future<void> _startViewing() async {
    if (pairedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3F51B5),
          content: Text('Please Pair With Cot Device First'),
        ),
      );
      return;
    }

    _closeConnection();
    setState(() => isLoading = true);

    try {
      final callRef = _db.collection('calls').doc(pairedId!);

      // Setup WebRTC peer connection with specific audio options
      _peer = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        // Add these critical echo cancellation configs
        'sdpSemantics': 'unified-plan',
        'enableDtlsSrtp': true,
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      // Get microphone stream but ENSURE it's muted initially
      final talkStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true, // Enable echo cancellation
          'noiseSuppression': true, // Enable noise suppression
          'autoGainControl': true, // Enable auto gain control
        },
        'video': false,
      });

      _talkTrack = talkStream.getAudioTracks().first;
      _talkTrack!.enabled = false; // Start MUTED

      // Use transceiver approach for better control of audio
      _audioTransceiver = await _peer!.addTransceiver(
        track: _talkTrack!,
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.SendRecv,
          streams: [talkStream],
        ),
      );

      // Make sure transceiver is properly configured
      await _setTransceiverDirection(TransceiverDirection.RecvOnly);

      _peer!.onTrack = (event) async {
        debugPrint('Track received: ${event.track.kind}');

        if (event.track.kind == 'video') {
          if (event.streams.isNotEmpty) {
            _remoteStream = event.streams[0];
            _remoteRenderer.srcObject = _remoteStream;
            setState(() => isViewingActive = true);
          }
        } else if (event.track.kind == 'audio') {
          // We received audio track from cot
          if (_remoteStream == null && event.streams.isNotEmpty) {
            _remoteStream = event.streams[0];
          }

          // Make sure the track's enabled state matches our tracking variable
          event.track.enabled = !_isAudioMuted;

          debugPrint('Audio track enabled: ${event.track.enabled}');
        }
      };

      // Handle the offer and answer exchange with Firebase
      final snap = await callRef.get();
      if (!snap.exists || !(snap.data()!.containsKey('offer'))) {
        throw Exception('No Active Broadcast Found');
      }

      final offer = snap.data()!['offer'];
      await _peer!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create answer with specific options
      final answer = await _peer!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await _peer!.setLocalDescription(answer);
      await callRef.update({'answer': answer.toMap()});

      // ICE candidate handling
      _peer!.onIceCandidate = (candidate) {
        callRef.collection('answerCandidates').add(candidate.toMap());
      };

      callRef.collection('offersCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            _peer!.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        }
      });

      _peer?.onConnectionState = (state) {
        debugPrint('WebRTC Connection State: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('WebRTC Connected');
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint('WebRTC Failed Or Disconnected');
          _closeConnection();
        }
      };

      debugPrint('WebRTC Setup Complete');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection Error: ${e.toString().substring(0, math.min(e.toString().length, 100))}',
          ),
        ),
      );
      _closeConnection();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPairedId() async {
    // added this to read the saved paired id from secure storage
    try {
      final id = await _storage.read(key: 'pair_id');
      setState(() => pairedId = id);
    } catch (e) {
      debugPrint('Error Loading Paired ID: $e');
    }
  }

  Future<void> _unpair() async {
    if (pairedId == null) return;
    setState(() => isLoading = true);

    try {
      final cmdRef = _db
          .collection('pairs')
          .doc(pairedId!)
          .collection('commands');

      // send the unpair command
      await cmdRef.add({
        'type': 'unpair',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // then unsubscribe & delete storage
      await FirebaseMessaging.instance.unsubscribeFromTopic('pair_$pairedId');
      await _storage.delete(key: 'pair_id');

      setState(() => pairedId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3F51B5),
          content: Text('Successfully Unpaired'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3F51B5),
          content: Text('Error Unpairing Device'),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _goToPairScreen() {
    // added this to navigate to the pairing screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PairScreen()),
    ).then((_) => _loadPairedId());
  }

  void _openStreamView() {
    // added this to start viewing then navigate to the stream viewer
    if (pairedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF3F51B5),
          content: Text('Please Pair With Cot Device First'),
        ),
      );
      return;
    }
    _startViewing().then((_) {
      _setRemoteAudioEnabled(true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ParentStreamViewScreen(
                remoteRenderer: _remoteRenderer,
                onToggleTalk: _toggleTalk,
                isTalking: _isTalking,
                onPlayLullaby: () async {
                  // added this to play the first lullaby in personal library
                  if (LibraryManager.I.personalLibrary.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF3F51B5),
                        content: Text('No Lullabies Available'),
                      ),
                    );
                    return;
                  }
                  final Lullaby lullaby =
                      LibraryManager.I.personalLibrary.first;
                  await _db
                      .collection('pairs')
                      .doc(pairedId)
                      .collection('commands')
                      .add({
                        'type': 'play',
                        'assetPath': lullaby.asset,
                        'title': lullaby.title,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Color(0xFF3F51B5),
                      content: Text('Playing "${lullaby.title}" On Cot'),
                    ),
                  );
                },
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // added this to build the main parent home UI
    final isPaired = pairedId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FC),
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/coocue_logo2.png', height: 40),
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Parent\nHome',
                          style: TextStyle(
                            fontSize: 40,
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3F51B5),
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Live Camera Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'LeagueSpartan',
                            ),
                          ),
                          Container(
                            // added this to show pairing status
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isPaired
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPaired ? 'Paired' : 'Not Paired',
                              style: TextStyle(
                                color:
                                    isPaired
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _openStreamView,
                        child: Container(
                          // added this as the video preview container
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child:
                              isViewingActive && _remoteStream != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: RTCVideoView(
                                      _remoteRenderer,
                                      objectFit:
                                          RTCVideoViewObjectFit
                                              .RTCVideoViewObjectFitCover,
                                    ),
                                  )
                                  : Center(
                                    // added this to show when no feed is active
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.videocam_off,
                                          size: 48,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Camera Feed Not Available',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'LeagueSpartan',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed:
                                              isPaired ? _startViewing : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF3F51B5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Connect To Cot',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  isPaired && isViewingActive
                                      ? _toggleTalk
                                      : null,
                              child: Container(
                                // added this to toggle talk mode
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color:
                                      isPaired
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      isPaired
                                          ? [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _isTalking ? Icons.mic_off : Icons.mic,
                                      color:
                                          isPaired
                                              ? const Color(0xffffb74d)
                                              : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isTalking ? 'Stop Talking' : 'Talk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'LeagueSpartan',
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isPaired
                                                ? Colors.black
                                                : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  isPaired
                                      ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const LullabyLibraryScreen(),
                                          ),
                                        );
                                      }
                                      : null,
                              child: Container(
                                // added this to open lullaby library
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color:
                                      isPaired
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      isPaired
                                          ? [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.music_note,
                                      color:
                                          isPaired
                                              ? const Color(0xffffb74d)
                                              : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Play Lullaby',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'LeagueSpartan',
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Center(
                        // added this for the pair/unpair button
                        child: ElevatedButton.icon(
                          onPressed: isPaired ? _unpair : _goToPairScreen,

                          label: Text(
                            isPaired ? 'Unpair' : 'Pair With Cot',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'LeagueSpartan',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F51B5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Tender Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        // added this to show a parenting tip
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF94ACFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Use Your Baby\'s Nap Times For Mini\nSelf-Care Breaks.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'LeagueSpartan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
