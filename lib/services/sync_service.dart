import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/customer.dart';
import 'api_service.dart';
import 'database_helper.dart';

/// Sync Service for offline-first data synchronization
/// 
/// Handles:
/// - Syncing local changes to server when online
/// - Fetching server data and storing locally
/// - Offline queue management
class SyncService {
  final ApiService _api = ApiService();
  final DatabaseHelper _db = DatabaseHelper();
  
  bool _isSyncing = false;
  
  /// Check if device has internet connectivity
  Future<bool> hasConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }
  
  /// Process offline queue - sync pending items to server
  Future<SyncResult> processOfflineQueue() async {
    if (_isSyncing) return SyncResult(success: false, message: 'Sync already in progress');
    if (!await hasConnectivity()) return SyncResult(success: false, message: 'No internet connection');
    
    _isSyncing = true;
    int processed = 0;
    int failed = 0;
    
    try {
      final pendingItems = await _db.getPendingOfflineQueue();
      
      for (var item in pendingItems) {
        final id = item['id'] as int;
        final tableName = item['table_name'] as String;
        final operation = item['operation'] as String;
        final data = item['data'] as String?;
        
        try {
          bool success = await _processQueueItem(tableName, operation, data);
          
          if (success) {
            await _db.markOfflineQueueItemComplete(id);
            processed++;
          } else {
            await _db.markOfflineQueueItemFailed(id, 'API request failed');
            failed++;
          }
        } catch (e) {
          await _db.markOfflineQueueItemFailed(id, e.toString());
          failed++;
        }
      }
      
      return SyncResult(
        success: true,
        message: 'Processed $processed items, $failed failed',
        processedCount: processed,
        failedCount: failed,
      );
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<bool> _processQueueItem(String tableName, String operation, String? data) async {
    switch (tableName) {
      case 'Payment':
        return await _syncPayment(operation, data);
      case 'Customer':
        return await _syncCustomer(operation, data);
      default:
        return false;
    }
  }
  
  Future<bool> _syncPayment(String operation, String? data) async {
    if (data == null) return false;
    
    final paymentData = jsonDecode(data) as Map<String, dynamic>;
    
    if (operation == 'create') {
      final response = await _api.createPayment(
        contractId: paymentData['contract_id'],
        amount: (paymentData['amount'] as num).toDouble(),
        paymentMethod: paymentData['payment_method'],
        clientReference: paymentData['client_reference'],
        momoPhone: paymentData['momo_phone'],
      );
      
      if (response.success && response.data != null) {
        // Update local record with server ID
        await _db.savePayment(response.data!);
        return true;
      }
    }
    
    return false;
  }
  
  Future<bool> _syncCustomer(String operation, String? data) async {
    if (data == null) return false;
    
    final customerData = jsonDecode(data) as Map<String, dynamic>;
    
    if (operation == 'create') {
      final customer = Customer.fromLocalJson(customerData);
      final response = await _api.createCustomer(customer);
      
      if (response.success && response.data != null) {
        await _db.saveCustomer(response.data!);
        return true;
      }
    }
    
    return false;
  }
  
  /// Full sync - fetch all data from server and store locally
  Future<SyncResult> fullSync({int? agentId}) async {
    if (_isSyncing) return SyncResult(success: false, message: 'Sync already in progress');
    if (!await hasConnectivity()) return SyncResult(success: false, message: 'No internet connection');
    
    _isSyncing = true;
    
    try {
      // First, process any pending offline items
      await processOfflineQueue();
      
      // Fetch customers
      final customersResponse = await _api.getCustomers(agentId: agentId);
      if (customersResponse.success && customersResponse.data != null) {
        await _db.saveCustomers(customersResponse.data!);
      }
      
      // Fetch contracts
      final contractsResponse = await _api.getContracts(agentId: agentId);
      if (contractsResponse.success && contractsResponse.data != null) {
        await _db.saveContracts(contractsResponse.data!);
      }
      
      // Fetch recent payments
      final paymentsResponse = await _api.getPayments(agentId: agentId);
      if (paymentsResponse.success && paymentsResponse.data != null) {
        await _db.savePayments(paymentsResponse.data!);
      }
      
      return SyncResult(success: true, message: 'Sync completed successfully');
    } catch (e) {
      return SyncResult(success: false, message: 'Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Check if there are pending items in offline queue
  Future<bool> hasPendingSync() async {
    return await _db.hasOfflineQueueItems();
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int processedCount;
  final int failedCount;
  
  SyncResult({
    required this.success,
    required this.message,
    this.processedCount = 0,
    this.failedCount = 0,
  });
}
