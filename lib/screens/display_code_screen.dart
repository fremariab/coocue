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
  // persistent storage + UUID generator
  final _storage = FlutterSecureStorage();
  final _uuid = Uuid();

  // keys for secure storage
  static const _codeKey = 'pair_code';
  static const _idKey = 'pair_id';
  static const _expiryKey = 'pair_expiry';

  String? pairingCode; // six-digit string
  DateTime? expiry; // when it expires
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListener();
    _loadOrGenerate();
  }

  void _setupFirebaseListener() {
    FirebaseMessaging.onMessage.listen((msg) async {
      if (msg.data['type'] == 'PAIRED') {
        await _storage.write(key: 'is_paired', value: 'true');
        // Also store the pair ID that comes from the server
        if (msg.data['pairId'] != null) {
          await _storage.write(key: 'pair_id', value: msg.data['pairId']);
        }
        if (mounted) Navigator.pop(context);
      }
    });
  }

  Future<void> _loadOrGenerate() async {
    final storedExpiry = await _storage.read(key: _expiryKey);
    if (storedExpiry == null ||
        DateTime.parse(storedExpiry).isBefore(DateTime.now())) {
      await _generatePairing();
    } else {
      pairingCode = await _storage.read(key: _codeKey);
      expiry = DateTime.parse(storedExpiry);
    }
    _startCountdown();
  }

  Future<void> _generatePairing() async {
    final code = (_uuid.v4().hashCode.abs() % 900000 + 100000).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 1));
    final expIso = expiry.toIso8601String();

    // 1️⃣ Store locally for your UI
    await _storage.write(key: _codeKey, value: code);
    await _storage.write(key: _expiryKey, value: expIso);
    await _storage.write(key: _idKey, value: code);

    // 2️⃣ Also write to Firestore for server-side verification
    await FirebaseFirestore.instance.collection('pairingCodes').doc(code).set({
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiry, // as a Timestamp
      'used': false, // mark unused initially
    });

    // 3️⃣ Subscribe locally for FCM
    await FirebaseMessaging.instance.subscribeToTopic('pair_$code');

    setState(() {
      pairingCode = code;
      this.expiry = expiry;
    });
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (expiry == null) return;
      final left = expiry!.difference(DateTime.now());
      if (left.isNegative) {
        countdownTimer?.cancel();
        setState(() => pairingCode = null);
      } else {
        setState(() {}); // to refresh the timer display
      }
    });
  }

  String _formatDuration() {
    if (expiry == null) return '00:00';
    final left = expiry!.difference(DateTime.now());
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digits = (pairingCode ?? '------').split('');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
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

              // Code Display
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

              // Expiry Time
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

              // Regenerate Code Button
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
