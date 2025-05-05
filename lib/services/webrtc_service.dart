// lib/services/webrtc_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  WebRTCService._();
  static final WebRTCService instance = WebRTCService._();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String? _currentPairId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {}

  Future<void> startOffering(String pairId) async {
    _currentPairId = pairId;
    debugPrint('🚀 startOffering() – writing offer for pairId=$pairId');

    // 1️⃣ get user media
    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {'facingMode': 'user'},
    });

    _pc?.close();
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    _pc!.onTrack = (RTCTrackEvent event) async {
      // Parent adds exactly one audio track; ignore video here
      if (event.track.kind == 'audio') {
        final hiddenRenderer = RTCVideoRenderer();
        await hiddenRenderer.initialize();

        hiddenRenderer.srcObject = event.streams.first; // attaches audio
        Helper.setSpeakerphoneOn(true); // plays through speaker
      }
    };

    _localStream!.getTracks().forEach((t) {
      _pc!.addTrack(t, _localStream!);
    });

    final callRef = _db.collection('calls').doc(pairId);

    _pc!.onIceCandidate = (cand) {
      callRef.collection('offersCandidates').add(cand.toMap());
    };

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // **DEBUG** confirm this runs without throwing
    try {
      await callRef.set({'offer': offer.toMap()});
      print('✅ offer written to calls/$pairId');
    } catch (e) {
      print('❌ failed to write offer: $e');
    }
    await callRef.set({'offer': offer.toMap()});

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

    callRef.collection('answersCandidates').snapshots().listen((snap) {
      for (var dc in snap.docChanges) {
        if (dc.type == DocumentChangeType.added) {
          final c = dc.doc.data()!;
          _pc!.addCandidate(
            RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
          );
        }
      }
    });
  }

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
