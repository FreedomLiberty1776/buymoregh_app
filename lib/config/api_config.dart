/// API Configuration for BuyMore Agent App
/// 
/// Switch between development and production by changing [environment]

class ApiConfig {
  // Environment: 'development' or 'production'
  static const String environment = 'development';
  
  // Base URLs
  static const String _devBaseUrl = 'http://10.0.2.2:8000';  // Android emulator localhost
  static const String _prodBaseUrl = 'https://api.buymoregh.com';
  
  static String get baseUrl => environment == 'development' ? _devBaseUrl : _prodBaseUrl;
  
  // API Endpoints
  static String get authLogin => '$baseUrl/api/auth/agent/login/';
  static String get authRefresh => '$baseUrl/api/auth/token/refresh/';
  static String get authMe => '$baseUrl/api/auth/users/me/';
  
  // Password Reset
  static String get passwordResetRequest => '$baseUrl/api/auth/agent/password-reset/request/';
  static String get passwordResetVerify => '$baseUrl/api/auth/agent/password-reset/verify/';
  static String get passwordResetConfirm => '$baseUrl/api/auth/agent/password-reset/confirm/';
  
  // Core API
  static String get customers => '$baseUrl/api/customers/';
  static String get contracts => '$baseUrl/api/contracts/';
  static String get payments => '$baseUrl/api/payments/';
  static String get products => '$baseUrl/api/products/';
  static String get categories => '$baseUrl/api/categories/';
  
  // Agent-specific endpoints
  static String get agentDashboard => '$baseUrl/api/auth/agents/dashboard/';
  static String get agentCustomers => '$baseUrl/api/customers/';
  
  // Payment endpoints (Paystack integration)
  static String get paymentInitiate => '$baseUrl/api/payments/initiate/';
  static String get paymentOtp => '$baseUrl/api/payments/otp/';
  static String paymentStatus(String reference) => '$baseUrl/api/payments/$reference/status/';
  
  // Sync endpoints
  static String get syncData => '$baseUrl/api/sync/';
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
