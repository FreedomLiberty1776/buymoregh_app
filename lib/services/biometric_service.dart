import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'database_helper.dart';

/// Biometric Authentication Service
/// 
/// Handles fingerprint/face authentication and related settings
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DatabaseHelper _db = DatabaseHelper();
  
  factory BiometricService() => _instance;
  
  BiometricService._internal();
  
  // Settings keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _requireLoginEveryTimeKey = 'require_login_every_time';
  static const String _lastAuthTimestampKey = 'last_auth_timestamp';
  
  // ==================== BIOMETRIC CAPABILITIES ====================
  
  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }
  
  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }
  
  /// Check if fingerprint is available specifically
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
           biometrics.contains(BiometricType.strong);
  }
  
  /// Get human-readable name of available biometric type
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint) ||
               biometrics.contains(BiometricType.strong)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    }
    return 'Biometric';
  }
  
  // ==================== AUTHENTICATION ====================
  
  /// Authenticate using biometrics
  Future<BiometricResult> authenticate({
    String reason = 'Please authenticate to access BuyMore Agent',
    bool biometricOnly = false,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult(
          success: false,
          error: 'Biometric authentication is not available on this device',
          errorType: BiometricErrorType.notAvailable,
        );
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );
      
      if (authenticated) {
        // Update last auth timestamp
        await _updateLastAuthTimestamp();
        
        return BiometricResult(success: true);
      } else {
        return BiometricResult(
          success: false,
          error: 'Authentication failed',
          errorType: BiometricErrorType.failed,
        );
      }
    } on PlatformException catch (e) {
      BiometricErrorType errorType = BiometricErrorType.unknown;
      String errorMessage = 'Authentication error';
      
      switch (e.code) {
        case 'NotAvailable':
          errorType = BiometricErrorType.notAvailable;
          errorMessage = 'Biometric authentication is not set up on this device';
          break;
        case 'NotEnrolled':
          errorType = BiometricErrorType.notEnrolled;
          errorMessage = 'No biometrics enrolled on this device';
          break;
        case 'LockedOut':
          errorType = BiometricErrorType.lockedOut;
          errorMessage = 'Too many attempts. Biometric locked out temporarily';
          break;
        case 'PermanentlyLockedOut':
          errorType = BiometricErrorType.permanentlyLockedOut;
          errorMessage = 'Biometric authentication permanently locked. Use device passcode';
          break;
        default:
          errorMessage = e.message ?? 'Authentication error';
      }
      
      return BiometricResult(
        success: false,
        error: errorMessage,
        errorType: errorType,
      );
    }
  }
  
  /// Cancel any ongoing biometric authentication
  Future<void> cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }
  
  // ==================== SETTINGS ====================
  
  /// Check if biometric authentication is enabled by user
  Future<bool> isBiometricEnabled() async {
    return await _db.getSettingBool(_biometricEnabledKey, defaultValue: false);
  }
  
  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _db.saveSetting(_biometricEnabledKey, enabled.toString());
  }
  
  /// Check if user requires login every time app opens
  Future<bool> isRequireLoginEveryTime() async {
    return await _db.getSettingBool(_requireLoginEveryTimeKey, defaultValue: false);
  }
  
  /// Enable or disable require login every time
  Future<void> setRequireLoginEveryTime(bool required) async {
    await _db.saveSetting(_requireLoginEveryTimeKey, required.toString());
  }
  
  /// Update last authentication timestamp
  Future<void> _updateLastAuthTimestamp() async {
    await _db.saveSetting(
      _lastAuthTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// Get last authentication timestamp
  Future<DateTime?> getLastAuthTimestamp() async {
    final timestamp = await _db.getSetting(_lastAuthTimestampKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }
  
  /// Check if re-authentication is required based on settings
  /// Returns true if user needs to authenticate
  Future<bool> isReauthenticationRequired() async {
    final requireEveryTime = await isRequireLoginEveryTime();
    if (!requireEveryTime) {
      // User doesn't require login every time, no re-auth needed
      return false;
    }
    
    // If require login every time is ON, they need to authenticate
    // The caller will decide whether to use biometric or password
    return true;
  }
  
  /// Clear all biometric settings (called on logout)
  Future<void> clearSettings() async {
    await _db.deleteSetting(_biometricEnabledKey);
    await _db.deleteSetting(_requireLoginEveryTimeKey);
    await _db.deleteSetting(_lastAuthTimestampKey);
  }
}

// ==================== RESULT MODELS ====================

class BiometricResult {
  final bool success;
  final String? error;
  final BiometricErrorType? errorType;
  
  BiometricResult({
    required this.success,
    this.error,
    this.errorType,
  });
}

enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  failed,
  unknown,
}
