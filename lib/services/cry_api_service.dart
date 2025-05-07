import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class CryApiService {
  // singleton instance for cry api service
  static final CryApiService _instance = CryApiService._();
  factory CryApiService() => _instance;
  CryApiService._();

  // audio recorder for capturing sound
  final AudioRecorder _audioRecorder = AudioRecorder();
  // stream controller to broadcast cry detection results
  final _cryController = StreamController<bool>.broadcast();
  Stream<bool> get onCryDetected => _cryController.stream;

  // timer for periodic detection
  Timer? _timer;
  // flag to indicate if detection is running
  bool _running = false;
  // count consecutive errors
  int _consecutiveErrors = 0;
  // max errors before pausing detection
  static const int _maxConsecutiveErrors = 5;

  // start the cry detection loop
  Future<void> startDetection({
    required String apiUrl,
    int sampleSeconds = 2,
    Duration interval = const Duration(seconds: 3),
  }) async {
    if (_running) return;
    _running = true;
    _consecutiveErrors = 0;

    if (!await _audioRecorder.hasPermission()) {
      throw Exception('microphone permission not granted');
    }

    _timer = Timer.periodic(interval, (_) async {
      if (!_running) return;

      try {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/cry_buffer_${DateTime.now().millisecondsSinceEpoch}.wav';

        // record audio for the given window
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 16 * 1000,
            sampleRate: 16000,
          ),
          path: path,
        );

        await Future.delayed(Duration(seconds: sampleSeconds));

        if (!_running) return;

        final filePath = await _audioRecorder.stop();
        if (filePath == null) {
          debugPrint('failed to get recorded file path');
          return;
        }

        final file = File(filePath);
        if (!await file.exists()) {
          debugPrint('recorded file does not exist: $filePath');
          return;
        }

        final fileSize = await file.length();
        if (fileSize < 1000) {
          debugPrint('recorded file too small ($fileSize bytes), skipping');
          return;
        }

        if (!_running) return;

        final uri = Uri.parse('$apiUrl/predict');
        final fileBytes = await file.readAsBytes();
        final client = http.Client();

        try {
          final request = http.MultipartRequest('POST', uri);
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: 'audio.wav',
              contentType: MediaType('audio', 'wav'),
            ),
          );

          // send the request with timeout
          http.StreamedResponse resp;
          resp = await request.send().timeout(Duration(seconds: 10));

          if (resp.statusCode == 200) {
            final body = await resp.stream.bytesToString();
            final json = jsonDecode(body) as Map<String, dynamic>;
            final isCrying = (json['label'] as int) == 1;

            _cryController.add(isCrying);
            _consecutiveErrors = 0;
            debugPrint('cry detection result: ${isCrying ? 'crying' : 'not crying'}');
          } else {
            _handleApiError('http error: ${resp.statusCode}');
          }
        } on TimeoutException {
          _handleApiError('request timeout');
        } on SocketException catch (e) {
          _handleApiError('network error: $e');
        } catch (e, st) {
          _handleApiError('detection error: $e\n$st');
        } finally {
          client.close();
        }

        // remove the temp file
        try {
          await File(filePath).delete();
        } catch (e) {
          debugPrint('failed to delete temporary file: $e');
        }
      } catch (e, st) {
        _handleApiError('recording error: $e\n$st');
      }
    });
  }

  // handle api or recording errors
  void _handleApiError(String message) {
    debugPrint('cry api: $message');
    _consecutiveErrors++;
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      debugPrint('too many consecutive errors, pausing detection for 30 seconds');
      _pauseDetection(Duration(seconds: 30));
    }
  }

  // pause detection and resume after a delay
  void _pauseDetection(Duration duration) {
    final wasRunning = _running;
    _running = false;
    if (wasRunning) {
      Future.delayed(duration, () {
        if (!_running) {
          _running = true;
          _consecutiveErrors = 0;
          debugPrint('resuming cry detection after pause');
        }
      });
    }
  }

  // stop detection and clean up
  Future<void> stopDetection() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
  }

  // dispose the service and close streams
  Future<void> dispose() async {
    await stopDetection();
    await _cryController.close();
  }
}
