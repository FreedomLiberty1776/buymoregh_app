import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/customer.dart';
import '../models/contract.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'database_helper.dart';

/// API Service for communicating with BuyMore backend
///
/// Handles authentication, data fetching, and error handling
class ApiService {
  final DatabaseHelper _db = DatabaseHelper();

  // ==================== HTTP HELPERS ====================

  Future<Map<String, String>> _getHeaders({bool authenticated = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final tokens = await _db.getTokens();
      if (tokens != null) {
        headers['Authorization'] = 'Bearer ${tokens['access_token']}';
      }
    }

    return headers;
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) parser,
  ) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(parser(data));
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Authentication failed', code: 'AUTH_FAILED');
      } else if (response.statusCode == 403) {
        // Check for specific agent status errors
        try {
          final data = jsonDecode(response.body);
          final code = data['code'] ?? 'PERMISSION_DENIED';
          final message = data['message'] ?? 'Permission denied';
          return ApiResponse.error(message, code: code);
        } catch (_) {
          return ApiResponse.error(
            'Permission denied',
            code: 'PERMISSION_DENIED',
          );
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          final message = data['message'] ?? data['detail'] ?? 'Request failed';
          final code = data['code'] ?? 'ERROR';
          return ApiResponse.error(message, code: code);
        } catch (_) {
          return ApiResponse.error('Request failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  // ==================== AUTHENTICATION ====================

  Future<ApiResponse<LoginResult>> login(
    String agentCode,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authLogin),
            headers: await _getHeaders(authenticated: false),
            body: jsonEncode({'agent_code': agentCode, 'password': password}),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        return LoginResult(
          accessToken: data['access'],
          refreshToken: data['refresh'],
          user: User.fromJson(data['user'] ?? {}),
        );
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<LoginResult>> refreshToken(String refreshToken) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authRefresh),
            headers: await _getHeaders(authenticated: false),
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        return LoginResult(
          accessToken: data['access'],
          refreshToken: refreshToken,
        );
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<User>> getMe() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.authMe), headers: await _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) => User.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Request a password reset code to be sent via SMS
  Future<ApiResponse<PasswordResetResponse>> requestPasswordReset(
    String identifier,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.passwordResetRequest),
            headers: await _getHeaders(authenticated: false),
            body: jsonEncode({'identifier': identifier}),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(
        response,
        (data) => PasswordResetResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Verify a password reset code
  Future<ApiResponse<PasswordResetResponse>> verifyResetCode(
    String identifier,
    String code,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.passwordResetVerify),
            headers: await _getHeaders(authenticated: false),
            body: jsonEncode({'identifier': identifier, 'code': code}),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(
        response,
        (data) => PasswordResetResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Reset password with verified code
  Future<ApiResponse<PasswordResetResponse>> resetPassword(
    String identifier,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.passwordResetConfirm),
            headers: await _getHeaders(authenticated: false),
            body: jsonEncode({
              'identifier': identifier,
              'code': code,
              'new_password': newPassword,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(
        response,
        (data) => PasswordResetResponse.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== CUSTOMERS ====================

  Future<ApiResponse<List<Customer>>> getCustomers({int? agentId}) async {
    try {
      final queryParams = <String, String>{};
      if (agentId != null) queryParams['agent'] = '$agentId';

      final baseUri = Uri.parse(ApiConfig.customers);
      final initialUrl = queryParams.isEmpty
          ? ApiConfig.customers
          : baseUri.replace(queryParameters: queryParams).toString();

      final headers = await _getHeaders();
      String? pageUrl = initialUrl;
      final customers = <Customer>[];
      int pageGuard = 0;

      while (pageUrl != null && pageGuard < 100) {
        final response = await http
            .get(Uri.parse(pageUrl), headers: headers)
            .timeout(ApiConfig.connectionTimeout);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          return _handleResponse(response, (_) => <Customer>[]);
        }

        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          final List<dynamic> results = data['results'] ?? [];
          customers.addAll(results.map((e) => Customer.fromJson(e)));
          final dynamic nextValue = data['next'];
          String? nextUrl = nextValue is String && nextValue.isNotEmpty ? nextValue : null;
          if (nextUrl != null && nextUrl.startsWith('/')) {
            nextUrl = '${ApiConfig.baseUrl}$nextUrl';
          }
          if (nextUrl == pageUrl) break;
          pageUrl = nextUrl;
        } else if (data is List) {
          customers.addAll(data.map((e) => Customer.fromJson(e)));
          pageUrl = null;
        } else {
          return ApiResponse.error('Unexpected customers response format.');
        }

        pageGuard += 1;
      }

      return ApiResponse.success(customers);
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<Customer>> createCustomer(
    Customer customer, {
    File? passportPhotoFile,
    File? idPhotoFile,
  }) async {
    try {
      if (passportPhotoFile != null || idPhotoFile != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.customers),
        );
        final headers = await _getHeaders();
        headers.remove('Content-Type');
        request.headers.addAll(headers);

        customer.toCreateJson().forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        if (passportPhotoFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'passport_photo',
              passportPhotoFile.path,
            ),
          );
        }
        if (idPhotoFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('id_photo', idPhotoFile.path),
          );
        }

        final streamed = await request.send().timeout(
          ApiConfig.connectionTimeout,
        );
        final response = await http.Response.fromStream(streamed);
        return _handleResponse(response, (data) => Customer.fromJson(data));
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.customers),
            headers: await _getHeaders(),
            body: jsonEncode(customer.toCreateJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) => Customer.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Get a single customer by ID
  Future<ApiResponse<Customer>> getCustomer(int customerId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.customers}$customerId/'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) => Customer.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Update an existing customer
  Future<ApiResponse<Customer>> updateCustomer(
    int customerId,
    Customer customer, {
    File? passportPhotoFile,
    File? idPhotoFile,
  }) async {
    try {
      if (passportPhotoFile != null || idPhotoFile != null) {
        final request = http.MultipartRequest(
          'PATCH',
          Uri.parse('${ApiConfig.customers}$customerId/'),
        );
        final headers = await _getHeaders();
        headers.remove('Content-Type');
        request.headers.addAll(headers);

        customer.toUpdateJson().forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        if (passportPhotoFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'passport_photo',
              passportPhotoFile.path,
            ),
          );
        }
        if (idPhotoFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('id_photo', idPhotoFile.path),
          );
        }

        final streamed = await request.send().timeout(
          ApiConfig.connectionTimeout,
        );
        final response = await http.Response.fromStream(streamed);
        return _handleResponse(response, (data) => Customer.fromJson(data));
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.customers}$customerId/'),
            headers: await _getHeaders(),
            body: jsonEncode(customer.toUpdateJson()),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) => Customer.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Get contracts for a specific customer
  Future<ApiResponse<List<Contract>>> getContractsForCustomer(
    int customerId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.contracts}?customer=$customerId'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        final List<dynamic> results = data['results'] ?? data;
        return results.map((e) => Contract.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Get payments for a specific customer
  Future<ApiResponse<List<Payment>>> getPaymentsForCustomer(
    int customerId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.payments}?customer=$customerId'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        final List<dynamic> results = data['results'] ?? data;
        return results.map((e) => Payment.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Get payments for a specific contract
  Future<ApiResponse<List<Payment>>> getPaymentsForContract(
    int contractId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.payments}?contract=$contractId'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        final List<dynamic> results = data['results'] ?? data;
        return results.map((e) => Payment.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Get a single contract by ID
  Future<ApiResponse<Contract>> getContract(int contractId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.contracts}$contractId/'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) => Contract.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== CONTRACTS ====================

  Future<ApiResponse<List<Contract>>> getContracts({
    int? agentId,
    String? status,
  }) async {
    try {
      String url = ApiConfig.contracts;
      List<String> params = [];
      if (agentId != null) params.add('agent=$agentId');
      if (status != null) params.add('status=$status');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        final List<dynamic> results = data['results'] ?? data;
        return results.map((e) => Contract.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== PAYMENTS ====================

  Future<ApiResponse<List<Payment>>> getPayments({
    int? agentId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String url = ApiConfig.payments;
      List<String> params = [];
      if (agentId != null) params.add('agent=$agentId');
      if (status != null) params.add('approval_status=$status');
      if (fromDate != null) params.add('from_date=$fromDate');
      if (toDate != null) params.add('to_date=$toDate');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        final List<dynamic> results = data['results'] ?? data;
        return results.map((e) => Payment.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<Payment>> createPayment({
    required int contractId,
    required double amount,
    required String paymentMethod,
    String? clientReference,
    String? momoPhone,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'contract': contractId,
        'amount': amount, // Send as number, not string
        'payment_method': paymentMethod,
      };

      if (clientReference != null) body['client_reference'] = clientReference;
      if (momoPhone != null && momoPhone.isNotEmpty)
        body['momo_phone'] = momoPhone;
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;

      final response = await http
          .post(
            Uri.parse(ApiConfig.payments),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) {
        // Handle idempotent response
        if (data is Map && data.containsKey('data')) {
          return Payment.fromJson(data['data']);
        }
        return Payment.fromJson(data);
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<PaystackInitResult>> initiatePaystackPayment({
    required int contractId,
    required double amount,
    required String momoPhone,
    String? clientReference,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.paymentInitiate),
            headers: await _getHeaders(),
            body: jsonEncode({
              'contract_id': contractId,
              'amount': amount.toString(),
              'momo_phone': momoPhone,
              'client_reference': clientReference,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(
        response,
        (data) => PaystackInitResult.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<PaymentStatusResult>> getPaymentStatus(
    String reference,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.paymentStatus(reference)),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(
        response,
        (data) => PaymentStatusResult.fromJson(data),
      );
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== PRODUCTS & CATEGORIES ====================

  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.categories), headers: await _getHeaders())
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response, (data) {
        final List<dynamic> results = data['results'] ?? data;
        return results.map((e) => Category.fromJson(e)).toList();
      });
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<List<Product>>> getProducts({
    String? search,
    int? categoryId,
    int? subcategoryId,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category_id'] = '$categoryId';
      if (subcategoryId != null) queryParams['subcategory_id'] = '$subcategoryId';
      if (isActive != null) queryParams['is_active'] = '$isActive';

      final baseUri = Uri.parse(ApiConfig.products);
      final initialUrl = queryParams.isEmpty
          ? ApiConfig.products
          : baseUri.replace(queryParameters: queryParams).toString();

      final headers = await _getHeaders();
      String? pageUrl = initialUrl;
      final products = <Product>[];
      int pageGuard = 0;

      while (pageUrl != null && pageGuard < 100) {
        final response = await http
            .get(Uri.parse(pageUrl), headers: headers)
            .timeout(ApiConfig.connectionTimeout);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          return _handleResponse(response, (_) => <Product>[]);
        }

        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          final List<dynamic> results = data['results'] ?? [];
          products.addAll(results.map((e) => Product.fromJson(e)));
          final dynamic nextValue = data['next'];
          String? nextUrl = nextValue is String && nextValue.isNotEmpty ? nextValue : null;
          if (nextUrl != null && nextUrl.startsWith('/')) {
            nextUrl = '${ApiConfig.baseUrl}$nextUrl';
          }
          if (nextUrl == pageUrl) break;
          pageUrl = nextUrl;
        } else if (data is List) {
          products.addAll(data.map((e) => Product.fromJson(e)));
          pageUrl = null;
        } else {
          return ApiResponse.error('Unexpected products response format.');
        }

        pageGuard += 1;
      }

      return ApiResponse.success(products);
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  Future<ApiResponse<Product>> getProduct(int productId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.products}$productId/'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response, (data) => Product.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== CONTRACT CREATE ====================

  Future<ApiResponse<Contract>> createContract({
    required int customerId,
    required int productId,
    required double totalPrice,
    required String paymentFrequency,
    required String expectedStartDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'customer': customerId,
        'product': productId,
        'total_price': totalPrice,
        'payment_frequency': paymentFrequency,
        'expected_start_date': expectedStartDate,
      };
      // expected_end_date is computed on backend as start_date + 3 months
      final response = await http
          .post(
            Uri.parse(ApiConfig.contracts),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);
      return _handleResponse(response, (data) => Contract.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }

  // ==================== DASHBOARD ====================

  Future<ApiResponse<DashboardData>> getDashboard() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.agentDashboard),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response, (data) => DashboardData.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', code: 'NETWORK_ERROR');
    }
  }
}

// ==================== RESPONSE MODELS ====================

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? code;

  ApiResponse._({required this.success, this.data, this.error, this.code});

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error, {String? code}) {
    return ApiResponse._(success: false, error: error, code: code);
  }

  bool get isAuthError =>
      code == 'AUTH_FAILED' ||
      code == 'AGENT_INACTIVE' ||
      code == 'AGENT_STATUS_REVOKED';
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final User? user;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });
}

class PaystackInitResult {
  final String reference;
  final String status;
  final String? displayText;

  PaystackInitResult({
    required this.reference,
    required this.status,
    this.displayText,
  });

  factory PaystackInitResult.fromJson(Map<String, dynamic> json) {
    return PaystackInitResult(
      reference: json['reference'] ?? '',
      status: json['status'] ?? '',
      displayText: json['display_text'],
    );
  }
}

class PaymentStatusResult {
  final String reference;
  final String status;
  final String? paystackStatus;
  final double? amount;

  PaymentStatusResult({
    required this.reference,
    required this.status,
    this.paystackStatus,
    this.amount,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      reference: json['reference'] ?? '',
      status: json['status'] ?? '',
      paystackStatus: json['paystack_status'],
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class DashboardData {
  final int customerCount;
  final double pendingApprovals;
  final double todayCollections;
  final List<Payment> recentPayments;

  DashboardData({
    required this.customerCount,
    required this.pendingApprovals,
    required this.todayCollections,
    required this.recentPayments,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      customerCount: json['customer_count'] ?? 0,
      pendingApprovals: (json['pending_approvals'] as num?)?.toDouble() ?? 0.0,
      todayCollections: (json['today_collections'] as num?)?.toDouble() ?? 0.0,
      recentPayments:
          (json['recent_payments'] as List?)
              ?.map((e) => Payment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PasswordResetResponse {
  final String code;
  final String message;
  final String? maskedPhone;

  PasswordResetResponse({
    required this.code,
    required this.message,
    this.maskedPhone,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      maskedPhone: json['masked_phone'],
    );
  }
}
