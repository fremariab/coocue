// lib/services/cry_detection_service.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tflite_audio/tflite_audio.dart';

class CryDetectionService {
  static final _instance = CryDetectionService._();
  factory CryDetectionService() => _instance;
  CryDetectionService._();

  final _cryController = StreamController<bool>.broadcast();
  Stream<bool> get onCryDetected => _cryController.stream;

  Stream<Map<dynamic, dynamic>>? _resultStream;
  List<String>? _labelList;

  /// Call this once (e.g. in initState of your first screen)
  Future<void> init() async {
    // 1) Load your TFLite model and labels
    await TfliteAudio.loadModel(
      model: 'assets/models/cry_detector.tflite',
      label: 'assets/models/cry_labels.txt',
      inputType: 'rawAudio',   // because we're streaming PCM
      isAsset: true,
    );

    // 2) Read your labels file so we can map index→string
    final rawLabels = await rootBundle.loadString('assets/models/cry_labels.txt');
    _labelList = rawLabels.trim().split('\n');

    // 3) Start the continuous recognition stream
    _resultStream = TfliteAudio.startAudioRecognition(
      sampleRate: 16000,   // matches your model training
      bufferSize: 16000,   // 1s worth of samples
      numOfInferences: 5,  // smooth over 5 windows
    );

    // 4) Listen and convert to a bool
    _resultStream?.listen((event) {
      final String recog = event['recognitionResult'] as String;
      // recog will be one of your labels, e.g. "cry" or "no_cry"
      final isCry = (recog == 'cry');
      _cryController.add(isCry);
    });
  }

  /// Call this when you no longer need detection (e.g. dispose)
  Future<void> dispose() async {
    await TfliteAudio.stopAudioRecognition();
    await _cryController.close();
  }
}
