import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coocue/screens/display_code_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:coocue/screens/cot_camera_screen.dart';

// just a status enum to check if paired or not
enum CotStatus { waitingToPair, idle }

class CotHomeScreen extends StatefulWidget {
  const CotHomeScreen({super.key});

  @override
  State<CotHomeScreen> createState() => _CotHomeScreenState();
}

class _CotHomeScreenState extends State<CotHomeScreen>
    with WidgetsBindingObserver {
  // added this to store secure data like pair code and id
  final _storage = FlutterSecureStorage();

  // keeping these keys same as in displaycodescreen
  static const _codeKey = 'pair_code';
  static const _idKey = 'pair_id';
  static const _isPairedKey =
      'is_paired'; // added this for easier status checks
  StreamSubscription? _cmdSub;

  // starting off with waiting status
  CotStatus _status = CotStatus.waitingToPair;

  // going to store the pair id here after fetching from storage
  String? _pairId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _refreshStatus().then((_) {
      // calling this first to load pairing status
      if (_pairId != null) {
        _listenForCommands();
      }
    });
  }

  void _listenForCommands() {
    // only listen once we have a pairId
    if (_pairId == null) return;

    _cmdSub = FirebaseFirestore.instance
        .collection('pairs')
        .doc(_pairId)
        .collection('commands')
        .snapshots()
        .listen((snap) async {
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              if (data['type'] == 'unpair') {
                // clear cot’s storage
                await _storage.delete(key: _isPairedKey);
                await _storage.delete(key: _idKey);
                setState(() => _status = CotStatus.waitingToPair);

                // show a warning
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF3F51B5),
                    content: Text('Parent has unpaired. Please pair again.'),
                  ),
                );
              }
              // delete the command doc so it doesn’t re-fire:
              await change.doc.reference.delete();
            }
          }
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _cmdSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // whenever the resumes from background, re‐check pairing status automatically
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  // this checks if device is already paired or not
  Future<void> _refreshStatus() async {
    final pairedFlag = await _storage.read(key: _isPairedKey);
    _pairId = await _storage.read(key: _idKey);

    debugPrint("-----------------\n REFRESH STATUS\n---------------");
    debugPrint("Is paired: $pairedFlag");
    debugPrint("Pair ID: $_pairId");

    if (pairedFlag == 'true' && _pairId != null && _pairId!.isNotEmpty) {
      setState(() => _status = CotStatus.idle);
      // restart listener with the fresh _pairId
      _cmdSub?.cancel();
      _listenForCommands();
      return;
    }

    // if not paired then maybe we can fallback to code
    if (_pairId == null || _pairId!.isEmpty) {
      final code = await _storage.read(key: _codeKey);
      if (code != null && code.isNotEmpty) {
        await _storage.write(key: _idKey, value: code);
        _pairId = code;
        debugPrint("Using code as pair ID: $_pairId");
      }
    }

    // still unpaired so keep status as waiting
    setState(() => _status = CotStatus.waitingToPair);
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = _status == CotStatus.waitingToPair;

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
                'Cot Home',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF94ACFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'LeagueSpartan',
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isWaiting ? 'Waiting to pair...' : 'Idle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'LeagueSpartan',
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  // when user clicks view live camera
                  onPressed: () async {
                    await _refreshStatus(); // just refreshing first

                    // if everything is ok then go to camera screen
                    if (_status == CotStatus.idle &&
                        _pairId != null &&
                        _pairId!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CotCameraScreen(pairId: _pairId!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete pairing first'),
                          backgroundColor: Color(0xFF3F51B5),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text(
                    'Start Monitoring',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
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
              const SizedBox(height: 40),

              Text(
                isWaiting
                    ? 'Place this phone in the crib\nand tap the button below\nto pair with the Parent Phone.'
                    : 'Paired! Monitoring session ready.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF3F51B5),
                  fontFamily: 'LeagueSpartan',
                ),
              ),
              const SizedBox(height: 40),
              if (isWaiting) ...[
                Image.asset('assets/images/img1.png', height: 100),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      // open the code screen and wait for result
                      final paired = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DisplayCodeScreen(),
                        ),
                      );

                      // if user paired then reload status
                      if (paired == true) {
                        await _refreshStatus();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3F51B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Pair',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'LeagueSpartan',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Image.asset('assets/images/img3.png', height: 200),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // just removing the pair flag
                      await _storage.delete(key: _isPairedKey);
                      await _refreshStatus(); // refresh again after unpairing
                    },
                    icon: const Icon(Icons.link_off, color: Colors.white),
                    label: const Text(
                      'Unpair',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFffb74d),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
