import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';

class EncryptionService {
  // 1. Generate a random 32-byte key
  static String generateFileKey() {
    return enc.Key.fromSecureRandom(32).base64;
  }

  // 2. Encrypt Bytes (Compressed PDF -> Scrambled Bytes)
  static Uint8List encryptData(Uint8List data, String base64Key) {
    final key = enc.Key.fromBase64(base64Key);
    final iv = enc.IV.fromLength(16); // Random salt for security
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // We store the IV at the front of the bytes so we can use it to decrypt later
    return Uint8List.fromList(iv.bytes + encrypted.bytes);
  }

  // 3. Decrypt Bytes (Scrambled Bytes -> Readable PDF)
  static Uint8List decryptData(Uint8List encryptedData, String base64Key) {
    final key = enc.Key.fromBase64(base64Key);
    
    // Extract the IV from the first 16 bytes
    final iv = enc.IV(encryptedData.sublist(0, 16));
    final actualEncryptedData = encryptedData.sublist(16);
    
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(actualEncryptedData), 
      iv: iv
    );
    
    return Uint8List.fromList(decrypted);
  }

  // 1. ENCRYPT STRING (For Profile Details)
  static String encryptString(String plainText, String keyString) {
    final key = enc.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
    // Use allZerosOfLength to guarantee a match
    final iv = enc.IV.allZerosOfLength(16); 
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  static String decryptString(String encryptedBase64, String keyString) {
    try {
      final key = enc.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
      final iv = enc.IV.allZerosOfLength(16); // Must match encryption exactly
      final encrypter = enc.Encrypter(enc.AES(key));

      return encrypter.decrypt64(encryptedBase64.trim(), iv: iv);
    } catch (e) {
      debugPrint("Decryption Failed: $e");
      return "DECRYPTION_ERROR";
    }
  }
  static String generateRandomKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }
}