// lib/services/webrtc_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  WebRTCService._();
  static final WebRTCService instance = WebRTCService._();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String?      _currentPairId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call once at app startup:
  Future<void> init() async {
    // nothing here (but could create factory, etc)
  }

  /// Turn on camera+mic, create an offer, publish it under /calls/{pairId},
  /// then listen for answers + remote ICE candidates.
  Future<void> startOffering(String pairId) async {
    _currentPairId = pairId;

    // 1️⃣ get user media
    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'environment'},
    });

    // 2️⃣ make peer
    _pc?.close();
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    // add tracks
    _localStream!.getTracks().forEach((t) {
      _pc!.addTrack(t, _localStream!);
    });

    final callRef = _db.collection('calls').doc(pairId);

    // 3️⃣ ICE → Firestore
    _pc!.onIceCandidate = (cand) {
      callRef
        .collection('offersCandidates')
        .add(cand.toMap());
    };

    // 4️⃣ offer
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // 5️⃣ publish
    await callRef.set({'offer': offer.toMap()});

    // 6️⃣ listen for answer
    callRef.snapshots().listen((snap) async {
      final data = snap.data();
      if (data != null && data['answer'] != null) {
        final ans = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _pc!.setRemoteDescription(ans);
      }
    });

    // 7️⃣ listen for answer-side ICE
    callRef
      .collection('answersCandidates')
      .snapshots()
      .listen((snap) {
        for (var dc in snap.docChanges) {
          if (dc.type == DocumentChangeType.added) {
            final c = dc.doc.data()!;
            _pc!.addCandidate(RTCIceCandidate(
              c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
          }
        }
      });
  }

  /// Tear down call and delete the Firestore doc
  Future<void> stopOffering() async {
  try {
    if (_currentPairId != null) {
      await _db.collection('calls').doc(_currentPairId).delete();
      _currentPairId = null;
    }
    
    if (_pc != null) {
      _pc!.close();
      _pc = null;
    }
    
    if (_localStream != null) {
      _localStream!.getTracks().forEach((t) => t.stop());
      _localStream = null;
    }
  } catch (e) {
    print('Error in stopOffering: $e');
  }
}
  MediaStream? get localStream => _localStream;
}
