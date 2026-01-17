import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Auth Provider for managing authentication state
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
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
      await _authService.logout();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Validate session and check if user should be logged out
  Future<bool> validateSession() async {
    try {
      final result = await _authService.validateSession();
      
      if (!result.valid && result.requiresLogout) {
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
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
