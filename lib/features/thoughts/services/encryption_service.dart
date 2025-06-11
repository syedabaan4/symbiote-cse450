import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final encrypt.Encrypter _encrypter;
  bool _isInitialized = false;

  Future<void> initialize(User user) async {
    if (_isInitialized) return; 
    
    // key derived from uid and email
    final keyMaterial = '${user.uid}${user.email}';
    final keyBytes = sha256.convert(utf8.encode(keyMaterial)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyBytes));
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    _isInitialized = true;
  }

  Map<String, String> encryptText(String text) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(text, iv: iv);
    return {
      'encryptedContent': encrypted.base64,
      'iv': iv.base64,
    };
  }

  String decryptText(String encryptedText, String ivBase64) {
    final iv = encrypt.IV.fromBase64(ivBase64);
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: iv);
  }
} 