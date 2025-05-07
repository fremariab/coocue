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
    debugPrint('startOffering() – writing offer for pairId=$pairId');

    // getting the user's mic and camera
    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': {'facingMode': 'user'},
    });

    // closing old connection if there is one
    _pc?.close();

    // creating new peer connection
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    // handling when the other person sends audio
    _pc!.onTrack = (RTCTrackEvent event) async {
      if (event.track.kind == 'audio') {
        final hiddenRenderer = RTCVideoRenderer();
        await hiddenRenderer.initialize();

        // connecting the incoming audio to the renderer
        hiddenRenderer.srcObject = event.streams.first;

        // muting speaker initially
        Helper.setSpeakerphoneOn(false);
      }
    };

    // adding all tracks (audio and video) to the connection
    _localStream!.getTracks().forEach((t) {
      _pc!.addTrack(t, _localStream!);
    });

    // getting reference to firebase call doc
    final callRef = _db.collection('calls').doc(pairId);

    // sending ice candidates as they come
    _pc!.onIceCandidate = (cand) {
      callRef.collection('offersCandidates').add(cand.toMap());
    };

    // creating offer to send to the other user
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    try {
      // saving the offer to firebase
      await callRef.set({'offer': offer.toMap()});
      print('offer written to calls/$pairId');
    } catch (e) {
      print('failed to write offer: $e');
    }

    // listening for answer from other user
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

    // listening for ice candidates from the other user
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
      // removing the call doc from firebase if it exists
      if (_currentPairId != null) {
        await _db.collection('calls').doc(_currentPairId).delete();
        _currentPairId = null;
      }

      // closing and cleaning up peer connection
      if (_pc != null) {
        _pc!.close();
        _pc = null;
      }

      // stopping the local media stream
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
