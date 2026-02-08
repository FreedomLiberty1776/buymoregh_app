import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/contract.dart';
import '../models/payment.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

/// App Provider for managing application state
class AppProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ApiService _api = ApiService();
  final SyncService _syncService = SyncService();
  
  // Connection state
  bool _isOnline = false;
  bool _isSyncing = false;
  bool _hasPendingSync = false;
  
  // Dashboard data
  int _customerCount = 0;
  double _pendingApprovals = 0;
  double _todayCollections = 0;
  List<Payment> _recentPayments = [];
  
  // Lists
  List<Customer> _customers = [];
  List<Contract> _contracts = [];
  List<Payment> _payments = [];
  List<Payment> _unsyncedPayments = [];

  int? _lastAgentId;

  // Loading states
  bool _isLoadingDashboard = false;
  bool _isLoadingCustomers = false;
  bool _isLoadingContracts = false;
  bool _isLoadingPayments = false;
  bool _isSyncingPending = false;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _hasPendingSync;
  bool get isSyncingPending => _isSyncingPending;
  List<Payment> get unsyncedPayments => _unsyncedPayments;
  
  int get customerCount => _customerCount;
  double get pendingApprovals => _pendingApprovals;
  double get todayCollections => _todayCollections;
  List<Payment> get recentPayments => _recentPayments;
  
  List<Customer> get customers => _customers;
  List<Contract> get contracts => _contracts;
  List<Payment> get payments => _payments;
  
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingCustomers => _isLoadingCustomers;
  bool get isLoadingContracts => _isLoadingContracts;
  bool get isLoadingPayments => _isLoadingPayments;
  
  /// Initialize connectivity monitoring
  void initConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);

      // When coming back online: short delay so connection is stable, then sync (including offline queue POSTs)
      if (_isOnline && !wasOnline) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          syncData(agentId: _lastAgentId);
        });
      }

      notifyListeners();
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }
  
  /// Check for pending sync items
  Future<void> checkPendingSync() async {
    _hasPendingSync = await _syncService.hasPendingSync();
    notifyListeners();
  }
  
  /// Sync data with server
  Future<void> syncData({int? agentId}) async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      await _syncService.fullSync(agentId: agentId);
      await checkPendingSync();
      await loadAllData(agentId: agentId);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Load all data (from local DB, then refresh from server if online)
  /// Set [forceRefresh] to true to always try to fetch from server
  Future<void> loadAllData({int? agentId, bool forceRefresh = false}) async {
    _lastAgentId = agentId;
    // Check connectivity before loading
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    notifyListeners();

    await Future.wait([
      loadDashboard(agentId: agentId, forceRefresh: forceRefresh),
      loadCustomers(agentId: agentId, forceRefresh: forceRefresh),
      loadContracts(agentId: agentId, forceRefresh: forceRefresh),
      loadPayments(agentId: agentId, forceRefresh: forceRefresh),
    ]);
    await loadUnsyncedPayments(agentId: agentId);
  }
  
  /// Load dashboard data
  Future<void> loadDashboard({int? agentId, bool forceRefresh = false}) async {
    _isLoadingDashboard = true;
    notifyListeners();
    
    try {
      // Load from local DB first (unless force refresh)
      if (!forceRefresh) {
        _customerCount = await _db.getCustomerCount(agentId: agentId);
        _pendingApprovals = await _db.getPendingApprovals(agentId: agentId);
        _todayCollections = await _db.getTodayCollections(agentId: agentId);
        _recentPayments = await _db.getPayments(agentId: agentId);
        _recentPayments = _recentPayments.take(5).toList();
        notifyListeners();
      }
      
      // Then try to fetch from server if online
      if (_isOnline) {
        final response = await _api.getDashboard();
        if (response.success && response.data != null) {
          await _db.savePayments(response.data!.recentPayments);
          _customerCount = response.data!.customerCount;
          _pendingApprovals = response.data!.pendingApprovals;
          _todayCollections = response.data!.todayCollections;
          // Re-load from DB so unsynced (local-only) payments stay in the list
          _recentPayments = await _db.getPayments(agentId: agentId);
          _recentPayments = _recentPayments.take(5).toList();
          notifyListeners();
        }
      }
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }
  
  /// Load customers
  Future<void> loadCustomers({int? agentId, bool forceRefresh = false}) async {
    _isLoadingCustomers = true;
    notifyListeners();
    
    try {
      // Load from local DB first (unless force refresh)
      if (!forceRefresh) {
        _customers = await _db.getCustomers(agentId: agentId);
        notifyListeners();
      }
      
      // Fetch from server if online
      if (_isOnline) {
        final response = await _api.getCustomers(agentId: agentId);
        if (response.success && response.data != null) {
          await _db.saveCustomers(response.data!);
          _customers = response.data!;
          notifyListeners();
        }
      } else if (forceRefresh) {
        // If forcing refresh but offline, load from local DB
        _customers = await _db.getCustomers(agentId: agentId);
        notifyListeners();
      }
    } finally {
      _isLoadingCustomers = false;
      notifyListeners();
    }
  }
  
  /// Load contracts
  Future<void> loadContracts({int? agentId, ContractStatus? status, bool forceRefresh = false}) async {
    _isLoadingContracts = true;
    notifyListeners();
    
    try {
      // Load from local DB first (unless force refresh)
      if (!forceRefresh) {
        _contracts = await _db.getContracts(agentId: agentId, status: status);
        notifyListeners();
      }
      
      // Fetch from server if online
      if (_isOnline) {
        final response = await _api.getContracts(
          agentId: agentId,
          status: status?.name.toUpperCase(),
        );
        if (response.success && response.data != null) {
          await _db.saveContracts(response.data!);
          _contracts = response.data!;
          notifyListeners();
        }
      } else if (forceRefresh) {
        // If forcing refresh but offline, load from local DB
        _contracts = await _db.getContracts(agentId: agentId, status: status);
        notifyListeners();
      }
    } finally {
      _isLoadingContracts = false;
      notifyListeners();
    }
  }
  
  /// Load payments
  Future<void> loadPayments({
    int? agentId,
    PaymentApprovalStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    bool forceRefresh = false,
  }) async {
    _isLoadingPayments = true;
    notifyListeners();
    
    try {
      // Load from local DB first (unless force refresh)
      if (!forceRefresh) {
        _payments = await _db.getPayments(
          agentId: agentId,
          status: status,
          fromDate: fromDate,
          toDate: toDate,
        );
        notifyListeners();
      }
      
      // Fetch from server if online
      if (_isOnline) {
        final response = await _api.getPayments(
          agentId: agentId,
          status: status?.name.toUpperCase(),
          fromDate: fromDate?.toIso8601String().split('T')[0],
          toDate: toDate?.toIso8601String().split('T')[0],
        );
        if (response.success && response.data != null) {
          await _db.savePayments(response.data!);
          // Re-load from DB so unsynced (local-only) payments stay in the list
          _payments = await _db.getPayments(
            agentId: agentId,
            status: status,
            fromDate: fromDate,
            toDate: toDate,
          );
          notifyListeners();
        }
      } else if (forceRefresh) {
        // If forcing refresh but offline, load from local DB
        _payments = await _db.getPayments(
          agentId: agentId,
          status: status,
          fromDate: fromDate,
          toDate: toDate,
        );
        notifyListeners();
      }
    } finally {
      _isLoadingPayments = false;
      notifyListeners();
    }
  }
  
  /// Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) return _customers;
    return await _db.searchCustomers(query);
  }

  /// Create a new customer (offline-first: when online submits to server, when offline queues for sync).
  Future<bool> createCustomer(Customer customer) async {
    try {
      if (_isOnline) {
        // Submit to server when online
        final response = await _api.createCustomer(customer);
        if (response.success && response.data != null) {
          await _db.saveCustomer(response.data!);
          _customers = [..._customers, response.data!];
          notifyListeners();
          return true;
        }
        return false;
      }
      // Offline: save locally and add to queue for later sync
      await _db.saveCustomer(customer);
      await _db.addToOfflineQueue(
        tableName: 'Customer',
        operation: 'create',
        uniqueField: 'local_unique_id',
        uniqueFieldValue: customer.localUniqueId ?? '',
        data: jsonEncode(customer.toCreateJson()),
      );
      await checkPendingSync();
      _customers = [..._customers, customer];
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get customer by ID
  Customer? getCustomerById(int customerId) {
    try {
      return _customers.firstWhere((c) => c.id == customerId);
    } catch (e) {
      return null;
    }
  }

  /// Create payment (offline-first). Saves locally first, then syncs to server when online.
  /// Uses client_reference for idempotency so the same payment is never submitted twice.
  Future<bool> createPayment({
    required Contract contract,
    required double amount,
    required String paymentMethod,
    String? momoPhone,
    String? notes,
  }) async {
    final ref = const Uuid().v4();
    final localId = -(ref.hashCode & 0x7FFFFFFF);

    final payment = Payment(
      id: localId,
      contractId: contract.id,
      customerId: contract.customerId,
      customerName: contract.customerName,
      amount: amount,
      paymentMethod: PaymentMethod.fromString(paymentMethod),
      momoPhone: momoPhone,
      approvalStatus: PaymentApprovalStatus.pending,
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: notes,
      isSynced: false,
      localUniqueId: ref,
      clientReference: ref,
      productName: contract.productName,
      productId: contract.productId,
      agentId: contract.agentId,
      contractNumber: contract.contractNumber,
      contractTotalAmount: contract.totalAmount,
      contractOutstandingBalance: contract.outstandingBalance,
      contractTotalPaid: contract.totalPaid,
      contractPaymentPercentage: contract.paymentPercentage,
    );

    await _db.savePayment(payment);

    final payload = {
      'contract_id': contract.id,
      'amount': amount,
      'payment_method': paymentMethod,
      'client_reference': ref,
      'momo_phone': momoPhone,
      'notes': notes,
    };
    await _db.addToOfflineQueue(
      tableName: 'Payment',
      operation: 'create',
      uniqueField: 'client_reference',
      uniqueFieldValue: ref,
      data: jsonEncode(payload),
    );
    await checkPendingSync();
    await loadUnsyncedPayments(agentId: contract.agentId);

    _payments.insert(0, payment);
    _recentPayments.insert(0, payment);
    if (_recentPayments.length > 5) _recentPayments = _recentPayments.take(5).toList();
    notifyListeners();

    if (_isOnline) {
      final response = await _api.createPayment(
        contractId: contract.id,
        amount: amount,
        paymentMethod: paymentMethod,
        clientReference: ref,
        momoPhone: momoPhone,
        notes: notes,
      );
      if (response.success && response.data != null) {
        await _db.savePayment(response.data!);
        final pending = await _db.getPendingOfflineQueue();
        for (final item in pending) {
          if (item['unique_field_value'] == ref) {
            await _db.markOfflineQueueItemComplete(item['id'] as int);
            break;
          }
        }
        await checkPendingSync();
        final agentId = contract.agentId;
        if (agentId != null) {
          _payments = await _db.getPayments(agentId: agentId);
          _recentPayments = await _db.getPayments(agentId: agentId);
          _recentPayments = _recentPayments.take(5).toList();
        }
        notifyListeners();
      }
    }
    return true;
  }

  /// Get contracts for a specific customer
  List<Contract> getContractsForCustomer(int customerId) {
    return _contracts.where((c) => c.customerId == customerId).toList();
  }

  /// Get payments for a specific customer
  List<Payment> getPaymentsForCustomer(int customerId) {
    return _payments.where((p) => p.customerId == customerId).toList();
  }
  
  /// Filter contracts by status
  List<Contract> getContractsByStatus(ContractStatus? status) {
    if (status == null) return _contracts;
    return _contracts.where((c) => c.status == status).toList();
  }
  
  /// Get overdue contracts
  List<Contract> get overdueContracts {
    return _contracts.where((c) => c.isOverdue).toList();
  }
  
  /// Load list of payments that are not yet synced to server
  Future<void> loadUnsyncedPayments({int? agentId}) async {
    _unsyncedPayments = await _db.getUnsyncedPayments(agentId: agentId);
    notifyListeners();
  }

  /// Run offline queue sync only (POST pending payments), then refresh data
  Future<void> triggerSync({int? agentId}) async {
    if (_isSyncingPending || _isSyncing) return;
    if (!await _syncService.hasConnectivity()) return;

    _isSyncingPending = true;
    notifyListeners();

    try {
      final result = await _syncService.processOfflineQueue();
      await checkPendingSync();
      await loadUnsyncedPayments(agentId: agentId ?? _lastAgentId);
      if (result.processedCount > 0 || result.failedCount > 0) {
        await loadAllData(agentId: agentId ?? _lastAgentId);
      }
    } finally {
      _isSyncingPending = false;
      notifyListeners();
    }
  }

  /// Clear all data
  Future<void> clearData() async {
    await _db.clearAllData();
    _customers = [];
    _contracts = [];
    _payments = [];
    _recentPayments = [];
    _unsyncedPayments = [];
    _customerCount = 0;
    _pendingApprovals = 0;
    _todayCollections = 0;
    notifyListeners();
  }
}
