import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _pinKey = 'user_pin_hash';
  static const String _localAuthEnabledKey = 'local_auth_enabled';

  /// Check if the device supports local authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are available on the device
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if local authentication is enabled by user
  Future<bool> isLocalAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localAuthEnabledKey) ?? false;
  }

  /// Enable/disable local authentication
  Future<void> setLocalAuthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localAuthEnabledKey, enabled);
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  /// Set PIN (hashed for security)
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    await prefs.setString(_pinKey, digest.toString());
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    
    if (storedHash == null) return false;
    
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString() == storedHash;
  }

  /// Remove PIN
  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Please authenticate to access the app',
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with PIN or biometrics
  Future<LocalAuthResult> authenticate({
    String localizedReason = 'Please authenticate to access the app',
    bool preferBiometrics = true,
  }) async {
    try {
      // Check if device supports authentication
      if (!await isDeviceSupported()) {
        return LocalAuthResult(
          success: false,
          error: 'Device does not support authentication',
          requiresPin: await isPinSet(),
        );
      }

      // If biometrics are preferred and available, try biometrics first
      if (preferBiometrics && await canCheckBiometrics()) {
        final availableBiometrics = await getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          try {
            final success = await authenticateWithBiometrics(
              localizedReason: localizedReason,
            );
            if (success) {
              return LocalAuthResult(success: true);
            }
          } catch (e) {
            // Fall back to PIN if biometrics fail
          }
        }
      }

      // Fall back to PIN authentication
      return LocalAuthResult(
        success: false,
        requiresPin: await isPinSet(),
        error: 'Biometric authentication failed or not available',
      );
    } catch (e) {
      return LocalAuthResult(
        success: false,
        error: e.toString(),
        requiresPin: await isPinSet(),
      );
    }
  }
}

class LocalAuthResult {
  final bool success;
  final String? error;
  final bool requiresPin;

  LocalAuthResult({
    required this.success,
    this.error,
    this.requiresPin = false,
  });
} 