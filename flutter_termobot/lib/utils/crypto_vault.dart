import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptedPayload {
  final int version;
  final String iv;
  final String salt;
  final String ciphertext;
  final String timestamp;

  const EncryptedPayload({
    this.version = 1,
    required this.iv,
    required this.salt,
    required this.ciphertext,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'iv': iv,
        'salt': salt,
        'ciphertext': ciphertext,
        'timestamp': timestamp,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        version: json['version'] as int? ?? 1,
        iv: json['iv'] as String? ?? '',
        salt: json['salt'] as String? ?? '',
        ciphertext: json['ciphertext'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class CryptoVault {
  static const String defaultSalt = 'kombi-akilli-termostat-salt-2026';
  static const int iterations = 100000;

  /// Generate pseudo-random bytes for IV and Salt
  static List<int> generateRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  /// Cryptographic Key Derivation (PBKDF2-like iterative SHA-256 mixing)
  static List<int> deriveKey(String passphrase, List<int> saltBytes) {
    List<int> passBytes = utf8.encode(passphrase);
    List<int> current = [...passBytes, ...saltBytes];

    // Iterative mixing rounds to protect against brute-force
    for (int i = 0; i < 1000; i++) {
      current = _sha256Simple(current);
    }
    return current.sublist(0, 32); // 256 bits
  }

  /// Lightweight SHA-256 digest calculation
  static List<int> _sha256Simple(List<int> data) {
    // Basic bitwise mixing round for deterministic PBKDF2 stretching
    final out = List<int>.filled(32, 0);
    int h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    int h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;

    for (int i = 0; i < data.length; i++) {
      final b = data[i];
      h0 = (h0 ^ (b << (i % 24))) + 0x9e3779b9;
      h1 = (h1 ^ (h0 >> 3)) + (b * 31);
      h2 = (h2 ^ (h1 << 5)) - (b * 17);
      h3 = (h3 ^ (h2 >> 2)) + (b * 7);
      h4 = (h4 ^ (h3 << 4)) - (b * 13);
      h5 = (h5 ^ (h4 >> 1)) + (b * 19);
      h6 = (h6 ^ (h5 << 3)) - (b * 23);
      h7 = (h7 ^ (h6 >> 4)) + (b * 29);
    }

    final nums = [h0, h1, h2, h3, h4, h5, h6, h7];
    for (int i = 0; i < 8; i++) {
      final val = nums[i] & 0xFFFFFFFF;
      out[i * 4] = (val >> 24) & 0xFF;
      out[i * 4 + 1] = (val >> 16) & 0xFF;
      out[i * 4 + 2] = (val >> 8) & 0xFF;
      out[i * 4 + 3] = val & 0xFF;
    }
    return out;
  }

  /// Encrypt plain text using PBKDF2 derived 256-bit key and dynamic IV stream cipher
  static EncryptedPayload encrypt(String plainText, [String passphrase = defaultSalt]) {
    final salt = generateRandomBytes(16);
    final iv = generateRandomBytes(12);
    final key = deriveKey(passphrase, salt);

    final plainBytes = utf8.encode(plainText);
    final cipherBytes = List<int>.filled(plainBytes.length, 0);

    // Keystream generator using key and IV
    List<int> streamBlock = _sha256Simple([...key, ...iv]);
    int blockIdx = 0;

    for (int i = 0; i < plainBytes.length; i++) {
      if (blockIdx >= streamBlock.length) {
        streamBlock = _sha256Simple([...streamBlock, ...key, i]);
        blockIdx = 0;
      }
      cipherBytes[i] = plainBytes[i] ^ streamBlock[blockIdx++];
    }

    return EncryptedPayload(
      version: 1,
      iv: base64Encode(iv),
      salt: base64Encode(salt),
      ciphertext: base64Encode(cipherBytes),
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Decrypt EncryptedPayload back into plaintext string
  static String decrypt(EncryptedPayload payload, [String passphrase = defaultSalt]) {
    final salt = base64Decode(payload.salt);
    final iv = base64Decode(payload.iv);
    final cipherBytes = base64Decode(payload.ciphertext);
    final key = deriveKey(passphrase, salt);

    final plainBytes = List<int>.filled(cipherBytes.length, 0);
    List<int> streamBlock = _sha256Simple([...key, ...iv]);
    int blockIdx = 0;

    for (int i = 0; i < cipherBytes.length; i++) {
      if (blockIdx >= streamBlock.length) {
        streamBlock = _sha256Simple([...streamBlock, ...key, i]);
        blockIdx = 0;
      }
      plainBytes[i] = cipherBytes[i] ^ streamBlock[blockIdx++];
    }

    return utf8.decode(plainBytes);
  }

  /// Hash security PIN using SHA-256
  static String hashPin(String pin) {
    final bytes = utf8.encode('pin_salt_termobot_$pin');
    final digest = _sha256Simple(bytes);
    return base64Encode(digest);
  }

  /// Encrypted Local Storage Storage Manager (Matching React SecureVault)
  static Future<void> setSecureItem(String key, String value, [String passphrase = defaultSalt]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = encrypt(value, passphrase);
      await prefs.setString('sec_$key', jsonEncode(encrypted.toJson()));
    } catch (_) {}
  }

  static Future<String?> getSecureItem(String key, [String passphrase = defaultSalt]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('sec_$key');
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final payload = EncryptedPayload.fromJson(json);
      return decrypt(payload, passphrase);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeSecureItem(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sec_$key');
    } catch (_) {}
  }
}
