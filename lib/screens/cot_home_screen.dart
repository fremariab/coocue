import 'package:coocue/screens/display_code_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:coocue/screens/cot_camera_screen.dart';

enum CotStatus { waitingToPair, idle }

class CotHomeScreen extends StatefulWidget {
  const CotHomeScreen({super.key});

  @override
  State<CotHomeScreen> createState() => _CotHomeScreenState();
}

class _CotHomeScreenState extends State<CotHomeScreen> {
  // storage & UUID (UUID not needed here, but kept for symmetry)
  final _storage = FlutterSecureStorage();
  final _uuid = Uuid();

  // keys must match DisplayCodeScreen
  static const _codeKey = 'pair_code';
  static const _idKey = 'pair_id';
  static const _expiryKey = 'pair_expiry';
  static const _isPairedKey = 'is_paired'; // Added for clarity
  
  CotStatus _status = CotStatus.waitingToPair;
  String? _pairId; // Store the pair ID in memory

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final pairedFlag = await _storage.read(key: _isPairedKey);
    _pairId = await _storage.read(key: _idKey);
    
    debugPrint("-----------------\n REFRESH STATUS\n---------------");
    debugPrint("Is paired: $pairedFlag");
    debugPrint("Pair ID: $_pairId");
    
    if (pairedFlag == 'true' && _pairId != null && _pairId!.isNotEmpty) {
      setState(() => _status = CotStatus.idle);
      return;
    }
    
    // If not properly paired, check if we have a code that can serve as ID
    if (_pairId == null || _pairId!.isEmpty) {
      // Try to read the code as backup (in DisplayCodeScreen, code is also stored as ID)
      final code = await _storage.read(key: _codeKey);
      if (code != null && code.isNotEmpty) {
        // Use the code as the pair ID if available
        await _storage.write(key: _idKey, value: code);
        _pairId = code;
        debugPrint("Using code as pair ID: $_pairId");
      }
    }
    
    setState(() => _status = CotStatus.waitingToPair);
  }

  Future<void> _ensurePairId() async {
    // If we still don't have a pair ID, generate one
    if (_pairId == null || _pairId!.isEmpty) {
      final code = (_uuid.v4().hashCode.abs() % 900000 + 100000).toString();
      await _storage.write(key: _idKey, value: code);
      _pairId = code;
      debugPrint("Generated new pair ID: $_pairId");
    }
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
              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    debugPrint("-----------------\n PUSHED BUTTON\n---------------");
                    
                    // Make sure we have a pair ID
                    if (_pairId == null || _pairId!.isEmpty) {
                      await _ensurePairId();
                    }
                    
                    debugPrint("-----------------\n pairid\n---------------");
                    debugPrint(_pairId);
                    
                    if (_pairId != null && _pairId!.isNotEmpty) {
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
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text(
                    'View Live Camera',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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
                      // Always refresh before showing code
                      await _refreshStatus();
                      if (_status == CotStatus.waitingToPair) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DisplayCodeScreen(),
                          ),
                        );
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
                // Add unpair button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Reset pairing status
                      await _storage.delete(key: _isPairedKey);
                      await _refreshStatus();
                    },
                    icon: const Icon(Icons.link_off, color: Colors.white),
                    label: const Text(
                      'Unpair',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
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