import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Encode(bytes);
  }

  static const currentIterations = 210000;
  static const legacyIterations = 10000;

  static String hashPassword(
    String password,
    String salt, {
    int iterations = currentIterations,
  }) {
    if (iterations < 1 || iterations > 1000000) {
      throw ArgumentError.value(iterations, 'iterations');
    }

    if (iterations == legacyIterations) {
      List<int> legacyHash = utf8.encode(password + salt);
      for (var iteration = 0; iteration < iterations; iteration++) {
        legacyHash = sha256.convert(legacyHash).bytes;
      }
      return base64Encode(legacyHash);
    }

    final saltBytes = base64Decode(salt);
    final hmac = Hmac(sha256, utf8.encode(password));
    var block = hmac.convert([...saltBytes, 0, 0, 0, 1]).bytes;
    final derivedKey = List<int>.from(block);
    for (var iteration = 1; iteration < iterations; iteration++) {
      block = hmac.convert(block).bytes;
      for (var byteIndex = 0; byteIndex < derivedKey.length; byteIndex++) {
        derivedKey[byteIndex] ^= block[byteIndex];
      }
    }
    return base64Encode(derivedKey);
  }

  static bool verifyPassword(
    String password,
    String salt,
    String expectedHash, {
    int iterations = currentIterations,
  }) {
    final computedHash = hashPassword(password, salt, iterations: iterations);
    if (computedHash.length != expectedHash.length) return false;
    var difference = 0;
    for (var index = 0; index < computedHash.length; index++) {
      difference |=
          computedHash.codeUnitAt(index) ^ expectedHash.codeUnitAt(index);
    }
    return difference == 0;
  }
}
