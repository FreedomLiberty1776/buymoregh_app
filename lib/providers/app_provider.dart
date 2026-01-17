import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  
  // Loading states
  bool _isLoadingDashboard = false;
  bool _isLoadingCustomers = false;
  bool _isLoadingContracts = false;
  bool _isLoadingPayments = false;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get hasPendingSync => _hasPendingSync;
  
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
      
      // Trigger sync when coming back online
      if (_isOnline && !wasOnline) {
        syncData();
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
  Future<void> loadAllData({int? agentId}) async {
    await Future.wait([
      loadDashboard(agentId: agentId),
      loadCustomers(agentId: agentId),
      loadContracts(agentId: agentId),
      loadPayments(agentId: agentId),
    ]);
  }
  
  /// Load dashboard data
  Future<void> loadDashboard({int? agentId}) async {
    _isLoadingDashboard = true;
    notifyListeners();
    
    try {
      // Load from local DB first
      _customerCount = await _db.getCustomerCount(agentId: agentId);
      _pendingApprovals = await _db.getPendingApprovals(agentId: agentId);
      _todayCollections = await _db.getTodayCollections(agentId: agentId);
      _recentPayments = await _db.getPayments(agentId: agentId);
      _recentPayments = _recentPayments.take(5).toList();
      
      notifyListeners();
      
      // Then try to fetch from server if online
      if (_isOnline) {
        final response = await _api.getDashboard();
        if (response.success && response.data != null) {
          _customerCount = response.data!.customerCount;
          _pendingApprovals = response.data!.pendingApprovals;
          _todayCollections = response.data!.todayCollections;
          _recentPayments = response.data!.recentPayments;
          notifyListeners();
        }
      }
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }
  
  /// Load customers
  Future<void> loadCustomers({int? agentId}) async {
    _isLoadingCustomers = true;
    notifyListeners();
    
    try {
      _customers = await _db.getCustomers(agentId: agentId);
      notifyListeners();
      
      if (_isOnline) {
        final response = await _api.getCustomers(agentId: agentId);
        if (response.success && response.data != null) {
          await _db.saveCustomers(response.data!);
          _customers = response.data!;
          notifyListeners();
        }
      }
    } finally {
      _isLoadingCustomers = false;
      notifyListeners();
    }
  }
  
  /// Load contracts
  Future<void> loadContracts({int? agentId, ContractStatus? status}) async {
    _isLoadingContracts = true;
    notifyListeners();
    
    try {
      _contracts = await _db.getContracts(agentId: agentId, status: status);
      notifyListeners();
      
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
  }) async {
    _isLoadingPayments = true;
    notifyListeners();
    
    try {
      _payments = await _db.getPayments(
        agentId: agentId,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );
      notifyListeners();
      
      if (_isOnline) {
        final response = await _api.getPayments(
          agentId: agentId,
          status: status?.name.toUpperCase(),
          fromDate: fromDate?.toIso8601String().split('T')[0],
          toDate: toDate?.toIso8601String().split('T')[0],
        );
        if (response.success && response.data != null) {
          await _db.savePayments(response.data!);
          _payments = response.data!;
          notifyListeners();
        }
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
  
  /// Filter contracts by status
  List<Contract> getContractsByStatus(ContractStatus? status) {
    if (status == null) return _contracts;
    return _contracts.where((c) => c.status == status).toList();
  }
  
  /// Get overdue contracts
  List<Contract> get overdueContracts {
    return _contracts.where((c) => c.isOverdue).toList();
  }
  
  /// Clear all data
  Future<void> clearData() async {
    await _db.clearAllData();
    _customers = [];
    _contracts = [];
    _payments = [];
    _recentPayments = [];
    _customerCount = 0;
    _pendingApprovals = 0;
    _todayCollections = 0;
    notifyListeners();
  }
}
