import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class Security {
  static final _storage = FlutterSecureStorage();
  static final _uuid    = Uuid();

  /// Generates a random UUID to use as salt
  static String generateSalt() => _uuid.v4();

  /// Hashes pin+salt with SHA-256
  static Future<String> hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return Future.value(sha256.convert(bytes).toString());
  }

  /// Persist the salt
  static Future<void> storeSalt(String salt) =>
      _storage.write(key: 'pin_salt', value: salt);

  /// Read the salt back
  static Future<String?> readSalt() =>
      _storage.read(key: 'pin_salt');

  /// Persist the hashed PIN
  static Future<void> storePinHash(String hash) =>
      _storage.write(key: 'pin_hash', value: hash);

  /// Read the hashed PIN
  static Future<String?> readPinHash() =>
      _storage.read(key: 'pin_hash');
}
