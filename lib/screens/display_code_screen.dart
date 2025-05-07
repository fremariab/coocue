import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisplayCodeScreen extends StatefulWidget {
  const DisplayCodeScreen({super.key});

  @override
  State<DisplayCodeScreen> createState() => _DisplayCodeScreenState();
}

class _DisplayCodeScreenState extends State<DisplayCodeScreen> {
  Duration remainingTime = const Duration(minutes: 1);
  Timer? timer;

  // used to store values safely
  final _storage = FlutterSecureStorage();

  // to generate random unique codes
  final _uuid = Uuid();

  // keys to save and retrieve stuff from storage
  static const _codeKey = 'pair_code';
  static const _idKey = 'pair_id';
  static const _expiryKey = 'pair_expiry';
  static const _isPairedKey = 'is_paired';

  // this will hold the pairing code
  String? pairingCode;

  // this will store when the code will expire
  DateTime? expiry;

  // timer to update the countdown
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    // setting up the listener for firebase messages
    _setupFirebaseListener();
    // either load an existing code or generate new one
    _loadOrGenerate();
  }

  // setting up what to do when a firebase message comes
  void _setupFirebaseListener() {
    FirebaseMessaging.onMessage.listen((msg) async {
      debugPrint("-----------------\nPair message received\n---------------");
      debugPrint("Message data: ${msg.data}");

      if (msg.data['type'] == 'PAIRED') {
        String pairId;

        // checking if we got a pairId from the server
        if (msg.data['pairId'] != null &&
            msg.data['pairId'].toString().isNotEmpty) {
          pairId = msg.data['pairId'].toString();
          debugPrint("Using server-provided pairId: $pairId");
        } else {
          // if not, using the local one
          pairId = pairingCode ?? '';
          debugPrint("Using local code as pairId: $pairId");
        }

        // storing that pairing is done
        await _storage.write(key: _isPairedKey, value: 'true');
        await _storage.write(key: _idKey, value: pairId);

        // just printing what got stored
        final storedPairId = await _storage.read(key: _idKey);
        final isPaired = await _storage.read(key: _isPairedKey);
        debugPrint(
          "Stored values - isPaired: $isPaired, pairId: $storedPairId",
        );

        // if screen is still there then close it
        if (mounted)
          Navigator.pop(context, true);
      }
    });
  }

  // either loading a saved code or making a new one if expired
  Future<void> _loadOrGenerate() async {
    final storedExpiry = await _storage.read(key: _expiryKey);
    if (storedExpiry == null ||
        DateTime.parse(storedExpiry).isBefore(DateTime.now())) {
      await _generatePairing();
    } else {
      pairingCode = await _storage.read(key: _codeKey);
      expiry = DateTime.parse(storedExpiry);
    }
    // starting the countdown
    _startCountdown();
  }

  // generating a new 6-digit code
  Future<void> _generatePairing() async {
    final code = (_uuid.v4().hashCode.abs() % 900000 + 100000).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 1));
    final expIso = expiry.toIso8601String();

    // saving all the pairing info
    await _storage.write(key: _codeKey, value: code);
    await _storage.write(key: _expiryKey, value: expIso);
    await _storage.write(key: _idKey, value: code);

    debugPrint("-----------------\nGenerated new code\n---------------");
    debugPrint("Code: $code");
    debugPrint("Stored as pair_id: $code");

    // saving code details to firestore
    await FirebaseFirestore.instance.collection('pairingCodes').doc(code).set({
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiry,
      'used': false,
    });

    // subscribing to firebase topic for this code
    await FirebaseMessaging.instance.subscribeToTopic('pair_$code');

    // updating state with new values
    setState(() {
      pairingCode = code;
      this.expiry = expiry;
    });
  }

  // starting the countdown timer
  void _startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (expiry == null) return;
      final left = expiry!.difference(DateTime.now());
      if (left.isNegative) {
        countdownTimer?.cancel();
        setState(() => pairingCode = null);
      } else {
        setState(() {});  
      }
    });
  }

  // formatting time into mm:ss
  String _formatDuration() {
    if (expiry == null) return '00:00';
    final left = expiry!.difference(DateTime.now());
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    // stopping the timer if screen is closed
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // splitting code into individual digits or dashes
    final digits = (pairingCode ?? '------').split('');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.asset('assets/images/coocue_logo2.png', height: 40),

              const SizedBox(height: 30),

              const Text(
                'Pairing Code',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),

              const SizedBox(height: 60),

              const Text(
                'Enter this 6-digit code\nshowing on the parent phone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF656565),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 65),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    digits.map((d) {
                      return Text(
                        d,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LeagueSpartan',
                          color: Color(0xff3F51B5),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 32),

              Text(
                pairingCode != null
                    ? 'Expires in ${_formatDuration()}'
                    : 'Code expired',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF656565),
                  fontFamily: 'LeagueSpartan',
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _generatePairing,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Regenerate Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'LeagueSpartan',
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
