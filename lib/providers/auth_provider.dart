import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

/// Auth Provider for managing authentication state
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _needsReauthentication = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  bool get needsReauthentication => _needsReauthentication;
  String? get error => _error;
  
  /// Initialize auth state on app start
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _authService.getCurrentUser();
        
        // Check if re-authentication is required
        if (_user != null) {
          _needsReauthentication = await _biometricService.isReauthenticationRequired();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Login with agent code and password
  Future<bool> login(String agentCode, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.login(agentCode, password);
      
      if (result.success) {
        _user = result.user;
        _needsReauthentication = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Logout and clear all data
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Clear biometric settings on logout
      await _biometricService.clearSettings();
      await _authService.logout();
      _user = null;
      _needsReauthentication = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Validate session. Only logout when backend explicitly requires it (e.g. agent inactive).
  /// On network errors we stay logged in using local session (offline-first).
  Future<bool> validateSession() async {
    try {
      final result = await _authService.validateSession();

      if (result.requiresLogout) {
        await logout();
        _error = result.error;
        notifyListeners();
        return false;
      }

      if (result.valid && result.user != null) {
        _user = result.user;
        notifyListeners();
      }

      return result.valid;
    } catch (e) {
      // On any exception (e.g. timeout), keep user logged in if we have local session
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn && _user == null) {
        _user = await _authService.getCurrentUser();
        notifyListeners();
      }
      _error = e.toString();
      notifyListeners();
      return _user != null;
    }
  }
  
  // ==================== BIOMETRIC AUTHENTICATION ====================
  
  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }
  
  /// Check if biometric is enabled by user
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }
  
  /// Enable or disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      // Verify biometric is available
      final available = await _biometricService.isBiometricAvailable();
      if (!available) {
        _error = 'Biometric authentication is not available on this device';
        notifyListeners();
        return false;
      }
      
      // Authenticate to confirm setup
      final result = await _biometricService.authenticate(
        reason: 'Authenticate to enable fingerprint login',
      );
      
      if (!result.success) {
        _error = result.error ?? 'Failed to enable biometric authentication';
        notifyListeners();
        return false;
      }
    }
    
    await _biometricService.setBiometricEnabled(enabled);
    notifyListeners();
    return true;
  }
  
  /// Check if "require login every time" is enabled
  Future<bool> isRequireLoginEveryTime() async {
    return await _biometricService.isRequireLoginEveryTime();
  }
  
  /// Set "require login every time" preference
  Future<void> setRequireLoginEveryTime(bool required) async {
    await _biometricService.setRequireLoginEveryTime(required);
    notifyListeners();
  }
  
  /// Get the name of available biometric type
  Future<String> getBiometricTypeName() async {
    return await _biometricService.getBiometricTypeName();
  }
  
  /// Authenticate with biometrics (for app unlock)
  Future<bool> authenticateWithBiometric() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _biometricService.authenticate(
        reason: 'Authenticate to unlock BuyMore Agent',
        biometricOnly: true,
      );
      
      if (result.success) {
        _needsReauthentication = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Re-authenticate with password (for app unlock)
  Future<bool> reauthenticateWithPassword(String password) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Login again with stored agent code
      final result = await _authService.login(
        _user!.agentCode ?? _user!.username,
        password,
      );
      
      if (result.success) {
        _needsReauthentication = false;
        notifyListeners();
        return true;
      } else {
        _error = result.error ?? 'Invalid password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Mark that re-authentication is required (called when app resumes)
  Future<void> checkReauthenticationRequired() async {
    if (_user != null) {
      final requireLogin = await _biometricService.isRequireLoginEveryTime();
      if (requireLogin) {
        _needsReauthentication = true;
        notifyListeners();
      }
    }
  }
  
  /// Clear the re-authentication requirement
  void clearReauthentication() {
    _needsReauthentication = false;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
