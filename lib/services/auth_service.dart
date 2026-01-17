import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'database_helper.dart';

/// Authentication Service
/// 
/// Handles login, logout, token management, and session validation
class AuthService {
  final ApiService _api = ApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  
  // ==================== TOKEN STORAGE ====================
  
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _db.saveTokens(accessToken, refreshToken);
  }
  
  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _db.clearTokens();
  }
  
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }
  
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }
  
  // ==================== AUTHENTICATION ====================
  
  /// Login with agent code and password
  Future<AuthResult> login(String agentCode, String password) async {
    final response = await _api.login(agentCode, password);
    
    if (response.success && response.data != null) {
      final result = response.data!;
      
      // Save tokens
      await _saveTokens(result.accessToken, result.refreshToken);
      
      // Save user to local DB
      if (result.user != null) {
        await _db.saveUser(result.user!);
      }
      
      return AuthResult(
        success: true,
        user: result.user,
      );
    } else {
      return AuthResult(
        success: false,
        error: response.error ?? 'Login failed',
        errorCode: response.code,
      );
    }
  }
  
  /// Logout and clear all local data
  Future<void> logout() async {
    await _clearTokens();
    await _db.clearAllData();
  }
  
  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Get current user from local database
  Future<User?> getCurrentUser() async {
    return await _db.getUser();
  }
  
  /// Validate session with backend (for forced logout check)
  /// 
  /// Returns AuthValidationResult with:
  /// - valid: true if session is valid
  /// - error: error message if invalid
  /// - requiresLogout: true if user should be forcefully logged out
  Future<AuthValidationResult> validateSession() async {
    final response = await _api.getMe();
    
    if (response.success && response.data != null) {
      // Update local user data
      await _db.saveUser(response.data!);
      
      return AuthValidationResult(
        valid: true,
        user: response.data,
      );
    } else {
      // Check for agent status errors
      if (response.code == 'AGENT_INACTIVE' || response.code == 'AGENT_STATUS_REVOKED') {
        return AuthValidationResult(
          valid: false,
          error: response.error,
          errorCode: response.code,
          requiresLogout: true,
        );
      }
      
      // For other auth errors, try to refresh token
      if (response.code == 'AUTH_FAILED') {
        final refreshResult = await _tryRefreshToken();
        if (refreshResult) {
          // Retry the request
          return await validateSession();
        }
      }
      
      return AuthValidationResult(
        valid: false,
        error: response.error,
        errorCode: response.code,
        requiresLogout: response.isAuthError,
      );
    }
  }
  
  /// Refresh access token using refresh token
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    
    final response = await _api.refreshToken(refreshToken);
    
    if (response.success && response.data != null) {
      await _saveTokens(response.data!.accessToken, response.data!.refreshToken);
      return true;
    }
    
    return false;
  }
}

// ==================== RESULT MODELS ====================

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String? errorCode;
  
  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.errorCode,
  });
}

class AuthValidationResult {
  final bool valid;
  final User? user;
  final String? error;
  final String? errorCode;
  final bool requiresLogout;
  
  AuthValidationResult({
    required this.valid,
    this.user,
    this.error,
    this.errorCode,
    this.requiresLogout = false,
  });
}
