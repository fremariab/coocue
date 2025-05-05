import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:coocue/screens/pair_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  String? pairedId;
  late final Stream<String> imageStream;
  late RTCPeerConnection _peer;
  MediaStream? _remoteStream;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPairedId();

    imageStream = FirebaseFirestore.instance
        .collection('cot_feed')
        .doc('current_frame')
        .snapshots()
        .map((snap) => snap.data()?['url'] as String);
  }

  Future<void> _startViewing() async {
    if (pairedId == null) {
      debugPrint("❌ Cannot start viewing: not paired yet");
      return;
    }
    final callDocRef = _db.collection('calls').doc(pairedId!);

    _peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });
    // 1️⃣ Remote tracks → collect in remoteStream
    _peer.onTrack = (RTCTrackEvent ev) {
      if (ev.streams.isNotEmpty) {
        setState(() => _remoteStream = ev.streams[0]);
      }
    };
    // 2️⃣ ICE → Firestore
    _peer.onIceCandidate = (cand) {
      callDocRef.collection('answersCandidates').add(cand.toMap());
    };
    // 3️⃣ Read offer
    final snap = await callDocRef.get();
    final offer = snap.data()!['offer'];
    await _peer.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    // 4️⃣ Create answer
    final answer = await _peer.createAnswer();
    await _peer.setLocalDescription(answer);
    await callDocRef.update({'answer': answer.toMap()});
    // 5️⃣ Listen for remote ICE
    callDocRef.collection('offersCandidates').snapshots().listen((change) {
      for (var dc in change.docChanges) {
        if (dc.type == DocumentChangeType.added) {
          final c = RTCIceCandidate(
            dc.doc['candidate'],
            dc.doc['sdpMid'],
            dc.doc['sdpMLineIndex'],
          );
          _peer.addCandidate(c);
        }
      }
    });
  }

  Future<void> _loadPairedId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pairedId = prefs.getString('paired_id');
    });
  }

  Future<void> _unpair() async {
    if (pairedId == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Unsubscribe from FCM topic
    await FirebaseMessaging.instance.unsubscribeFromTopic('pair_$pairedId');
    await prefs.remove('paired_id');
    setState(() {
      pairedId = null;
    });
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
      body: SafeArea(
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
              const Text(
                'Live Camera Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'LeagueSpartan',
                ),
              ),
              const SizedBox(height: 12),
              // ← New live preview
              ElevatedButton(
                onPressed: _startViewing,
                child: Text('Connect to Cot'),
              ),
              if (_remoteStream != null)
                Expanded(
                  child: RTCVideoView(
                    RTCVideoRenderer()..srcObject = _remoteStream!,
                  ),
                )
              else
                const CircularProgressIndicator(),
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
                      onTap: () {
                        // TODO: Implement Talk functionality
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.mic, color: Color(0xFFFF9800), size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Talk',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'LeagueSpartan',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement Play Lullaby functionality
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.music_note,
                              color: Color(0xFFFFA726),
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Play Lullaby',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'LeagueSpartan',
                                fontWeight: FontWeight.w500,
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
                    style: TextStyle(
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
                  'Use your baby’s nap times for mini\nself-care breaks.',
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
