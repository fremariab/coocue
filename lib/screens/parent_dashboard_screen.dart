import 'package:flutter/material.dart';
import 'dart:math' as math; // Import dart:math library
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:coocue/screens/pair_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  String? pairedId;
  bool isLoading = true; // Add loading state
  bool isViewingActive = false; // Track if viewing is active
  final _storage = FlutterSecureStorage();

  late final Stream<String> imageStream;
  RTCPeerConnection? _peer;
  MediaStream? _remoteStream;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _remoteRenderer.initialize().then((_) {
      _initializeApp();
    });

    // Remove the PeerConnectionFactory code as it's not needed in flutter_webrtc
    // flutter_webrtc handles this internally

    imageStream = FirebaseFirestore.instance
        .collection('cot_feed')
        .doc('current_frame')
        .snapshots()
        .map((snap) => snap.data()?['url'] as String? ?? '');
  }

  @override
  void dispose() {
    _closeConnection();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _remoteRenderer.initialize();
    await _loadPairedId();
    setState(() => isLoading = false);
  }

  Future<void> _startViewing() async {
    if (pairedId == null) {
      debugPrint("❌ Cannot start viewing: not paired");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pair with a Cot device first')),
      );
      return;
    }

    // Make sure we close any existing connection first
    _closeConnection();

    setState(() => isLoading = true);

    try {
      final callRef = _db.collection('calls').doc(pairedId!);

      // Create new peer connection
      _peer = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });

      // Set up track handler
      _peer?.onTrack = (ev) {
        if (ev.streams.isNotEmpty && mounted) {
          setState(() {
            _remoteStream = ev.streams[0];
            _remoteRenderer.srcObject = _remoteStream;
            isViewingActive = true;
          });
        }
      };

      // Check if offer exists in Firestore
      final snap = await callRef.get();
      if (!snap.exists || !snap.data()!.containsKey('offer')) {
        throw Exception("No active broadcast found for this device");
      }

      final offer = snap.data()!['offer'];
      await _peer?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create and set answer
      final answer = await _peer?.createAnswer();
      if (answer != null) {
        await _peer?.setLocalDescription(answer);
        await callRef.update({'answer': answer.toMap()});
      }

      // Listen for ICE candidates
      callRef.collection('offersCandidates').snapshots().listen((ch) {
        for (var dc in ch.docChanges) {
          if (dc.type == DocumentChangeType.added) {
            final d = dc.doc.data()!;
            _peer?.addCandidate(
              RTCIceCandidate(d['candidate'], d['sdpMid'], d['sdpMLineIndex']),
            );
          }
        }
      });

      // Add connection state change listener
      _peer?.onConnectionState = (state) {
        debugPrint("📡 WebRTC connection state changed: $state");
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint("✅ WebRTC connection established");
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint("❌ WebRTC connection failed or disconnected");
          _closeConnection();
        }
      };

      debugPrint("✅ WebRTC connection setup complete");
    } catch (e) {
      debugPrint("❌ WebRTC error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection error: ${e.toString().substring(0, math.min(e.toString().length, 100))}',
          ),
        ),
      );
      _closeConnection();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _closeConnection() {
    // Safely close remote stream
    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) => track.stop());
      _remoteStream!.dispose();
      _remoteStream = null;
    }

    // Clear renderer
    _remoteRenderer.srcObject = null;

    // Safely close peer connection
    try {
      if (_peer != null) {
        _peer?.close();
      }
    } catch (e) {
      debugPrint("⚠️ Error closing peer connection: $e");
    }

    if (mounted) {
      setState(() => isViewingActive = false);
    }
  }

  Future<void> _loadPairedId() async {
    try {
      final id = await _storage.read(key: 'pair_id');
      setState(() => pairedId = id);
      debugPrint("✅ Loaded paired ID: $id");
    } catch (e) {
      debugPrint("❌ Error loading paired ID: $e");
    }
  }

  Future<void> _unpair() async {
    if (pairedId == null) return;

    setState(() => isLoading = true);

    try {
      _closeConnection();
      await FirebaseMessaging.instance.unsubscribeFromTopic('pair_$pairedId');
      await _storage.delete(key: 'pair_id');
      setState(() => pairedId = null);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Successfully unpaired')));

      debugPrint("✅ Device unpaired");
    } catch (e) {
      debugPrint("❌ Error unpairing: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error unpairing device')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _goToPairScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PairScreen()),
    ).then((_) {
      // refresh when returning
      _loadPairedId();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3F51B5),
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
                          // Status indicator
                          Container(
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

                      // Video container
                      Container(
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam_off,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Camera feed not available',
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Connect to Cot',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
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
                                  isPaired
                                      ? () {
                                        // TODO: Implement Talk functionality
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Talk feature coming soon!',
                                            ),
                                          ),
                                        );
                                      }
                                      : null,
                              child: Container(
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
                                      Icons.mic,
                                      color:
                                          isPaired
                                              ? const Color(0xFFFF9800)
                                              : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Talk',
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
                                        // TODO: Implement Play Lullaby functionality
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Lullaby feature coming soon!',
                                            ),
                                          ),
                                        );
                                      }
                                      : null,
                              child: Container(
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
                                              ? const Color(0xFFFFA726)
                                              : Colors.grey,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Play Lullaby',
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
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Pair / Unpair toggle button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: isPaired ? _unpair : _goToPairScreen,
                          icon: Icon(
                            isPaired ? Icons.link_off : Icons.link,
                            color: Colors.white,
                          ),
                          label: Text(
                            isPaired ? 'Unpair' : 'Pair with Cot',
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
                          "Use your baby's nap times for mini\nself-care breaks.",
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