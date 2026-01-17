import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/customer.dart';
import '../models/contract.dart';
import '../models/payment.dart';

/// Database helper for local SQLite storage
/// 
/// Implements offline-first pattern with sync tracking
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => _instance;
  
  DatabaseHelper._internal();
  
  static const int _version = 1;
  static const String _dbName = 'buymoregh_agent.db';
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE User (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT,
        first_name TEXT,
        last_name TEXT,
        phone_number TEXT,
        agent_code TEXT,
        is_agent INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        is_staff INTEGER DEFAULT 0,
        permissions TEXT,
        date_joined TEXT,
        last_login TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Customer table
    await db.execute('''
      CREATE TABLE Customer (
        id INTEGER PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        email TEXT,
        address TEXT,
        id_type TEXT,
        id_number TEXT,
        profile_photo TEXT,
        agent_id INTEGER,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 1,
        local_unique_id TEXT UNIQUE
      )
    ''');
    
    // Contract table
    await db.execute('''
      CREATE TABLE Contract (
        id INTEGER PRIMARY KEY,
        customer_id INTEGER NOT NULL,
        customer_name TEXT,
        product_id INTEGER NOT NULL,
        product_name TEXT,
        agent_id INTEGER,
        total_amount REAL NOT NULL,
        down_payment REAL DEFAULT 0,
        total_paid REAL DEFAULT 0,
        outstanding_balance REAL DEFAULT 0,
        payment_percentage REAL DEFAULT 0,
        duration_months INTEGER DEFAULT 12,
        interest_rate REAL DEFAULT 0,
        status TEXT DEFAULT 'ACTIVE',
        start_date TEXT,
        end_date TEXT,
        next_payment_date TEXT,
        monthly_installment REAL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 1,
        local_unique_id TEXT UNIQUE,
        FOREIGN KEY (customer_id) REFERENCES Customer (id)
      )
    ''');
    
    // Payment table
    await db.execute('''
      CREATE TABLE Payment (
        id INTEGER PRIMARY KEY,
        contract_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        customer_name TEXT,
        agent_id INTEGER,
        amount REAL NOT NULL,
        payment_method TEXT DEFAULT 'CASH',
        momo_phone TEXT,
        approval_status TEXT DEFAULT 'PENDING',
        rejection_reason TEXT,
        approved_at TEXT,
        approved_by INTEGER,
        client_reference TEXT UNIQUE,
        paystack_reference TEXT,
        paystack_status TEXT,
        payment_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        contract_outstanding_balance REAL,
        contract_total_paid REAL,
        contract_payment_percentage REAL,
        is_synced INTEGER DEFAULT 1,
        local_unique_id TEXT UNIQUE,
        FOREIGN KEY (contract_id) REFERENCES Contract (id),
        FOREIGN KEY (customer_id) REFERENCES Customer (id)
      )
    ''');
    
    // Offline Queue table for sync
    await db.execute('''
      CREATE TABLE OfflineQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        unique_field TEXT NOT NULL,
        unique_field_value TEXT NOT NULL,
        data TEXT,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Auth tokens table
    await db.execute('''
      CREATE TABLE AuthToken (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        access_token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        expires_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_customer_agent ON Customer(agent_id)');
    await db.execute('CREATE INDEX idx_contract_customer ON Contract(customer_id)');
    await db.execute('CREATE INDEX idx_contract_agent ON Contract(agent_id)');
    await db.execute('CREATE INDEX idx_contract_status ON Contract(status)');
    await db.execute('CREATE INDEX idx_payment_contract ON Payment(contract_id)');
    await db.execute('CREATE INDEX idx_payment_customer ON Payment(customer_id)');
    await db.execute('CREATE INDEX idx_payment_status ON Payment(approval_status)');
    await db.execute('CREATE INDEX idx_payment_date ON Payment(payment_date)');
    await db.execute('CREATE INDEX idx_offline_queue_status ON OfflineQueue(status)');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here for future versions
  }
  
  // ==================== USER OPERATIONS ====================
  
  Future<int> saveUser(User user) async {
    final db = await database;
    return await db.insert(
      'User',
      user.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<User?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('User', limit: 1);
    if (maps.isEmpty) return null;
    return User.fromLocalJson(maps.first);
  }
  
  Future<int> deleteUser() async {
    final db = await database;
    return await db.delete('User');
  }
  
  // ==================== CUSTOMER OPERATIONS ====================
  
  Future<int> saveCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(
      'Customer',
      customer.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> saveCustomers(List<Customer> customers) async {
    final db = await database;
    final batch = db.batch();
    for (var customer in customers) {
      batch.insert(
        'Customer',
        customer.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
  
  Future<List<Customer>> getCustomers({int? agentId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (agentId != null) {
      maps = await db.query('Customer', where: 'agent_id = ?', whereArgs: [agentId]);
    } else {
      maps = await db.query('Customer');
    }
    return maps.map((e) => Customer.fromLocalJson(e)).toList();
  }
  
  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query('Customer', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Customer.fromLocalJson(maps.first);
  }
  
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'Customer',
      where: 'full_name LIKE ? OR phone_number LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((e) => Customer.fromLocalJson(e)).toList();
  }
  
  // ==================== CONTRACT OPERATIONS ====================
  
  Future<int> saveContract(Contract contract) async {
    final db = await database;
    return await db.insert(
      'Contract',
      contract.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> saveContracts(List<Contract> contracts) async {
    final db = await database;
    final batch = db.batch();
    for (var contract in contracts) {
      batch.insert(
        'Contract',
        contract.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
  
  Future<List<Contract>> getContracts({int? agentId, ContractStatus? status}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;
    
    if (agentId != null && status != null) {
      where = 'agent_id = ? AND status = ?';
      whereArgs = [agentId, status.name.toUpperCase()];
    } else if (agentId != null) {
      where = 'agent_id = ?';
      whereArgs = [agentId];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status.name.toUpperCase()];
    }
    
    final maps = await db.query('Contract', where: where, whereArgs: whereArgs);
    return maps.map((e) => Contract.fromLocalJson(e)).toList();
  }
  
  Future<Contract?> getContractById(int id) async {
    final db = await database;
    final maps = await db.query('Contract', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Contract.fromLocalJson(maps.first);
  }
  
  Future<List<Contract>> getContractsByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query('Contract', where: 'customer_id = ?', whereArgs: [customerId]);
    return maps.map((e) => Contract.fromLocalJson(e)).toList();
  }
  
  Future<int> getCustomerCount({int? agentId}) async {
    final db = await database;
    String sql = 'SELECT COUNT(DISTINCT customer_id) as count FROM Contract';
    if (agentId != null) {
      sql += ' WHERE agent_id = $agentId';
    }
    final result = await db.rawQuery(sql);
    return result.first['count'] as int? ?? 0;
  }
  
  // ==================== PAYMENT OPERATIONS ====================
  
  Future<int> savePayment(Payment payment) async {
    final db = await database;
    return await db.insert(
      'Payment',
      payment.toLocalJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<void> savePayments(List<Payment> payments) async {
    final db = await database;
    final batch = db.batch();
    for (var payment in payments) {
      batch.insert(
        'Payment',
        payment.toLocalJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
  
  Future<List<Payment>> getPayments({
    int? agentId,
    PaymentApprovalStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> args = [];
    
    if (agentId != null) {
      conditions.add('agent_id = ?');
      args.add(agentId);
    }
    if (status != null) {
      conditions.add('approval_status = ?');
      args.add(status.name.toUpperCase());
    }
    if (fromDate != null) {
      conditions.add('payment_date >= ?');
      args.add(fromDate.toIso8601String().split('T')[0]);
    }
    if (toDate != null) {
      conditions.add('payment_date <= ?');
      args.add(toDate.toIso8601String().split('T')[0]);
    }
    
    final maps = await db.query(
      'Payment',
      where: conditions.isNotEmpty ? conditions.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'payment_date DESC',
    );
    return maps.map((e) => Payment.fromLocalJson(e)).toList();
  }
  
  Future<List<Payment>> getTodayPayments({int? agentId}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return getPayments(
      agentId: agentId,
      fromDate: DateTime.parse(today),
      toDate: DateTime.parse(today).add(const Duration(days: 1)),
    );
  }
  
  Future<double> getTodayCollections({int? agentId}) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    String sql = '''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM Payment 
      WHERE payment_date LIKE '$today%' 
      AND approval_status = 'APPROVED'
    ''';
    if (agentId != null) {
      sql += ' AND agent_id = $agentId';
    }
    final result = await db.rawQuery(sql);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  
  Future<double> getPendingApprovals({int? agentId}) async {
    final db = await database;
    String sql = '''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM Payment 
      WHERE approval_status = 'PENDING'
    ''';
    if (agentId != null) {
      sql += ' AND agent_id = $agentId';
    }
    final result = await db.rawQuery(sql);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  
  Future<Payment?> getPaymentByClientReference(String clientReference) async {
    final db = await database;
    final maps = await db.query(
      'Payment',
      where: 'client_reference = ?',
      whereArgs: [clientReference],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Payment.fromLocalJson(maps.first);
  }
  
  // ==================== OFFLINE QUEUE OPERATIONS ====================
  
  Future<int> addToOfflineQueue({
    required String tableName,
    required String operation,
    required String uniqueField,
    required String uniqueFieldValue,
    String? data,
  }) async {
    final db = await database;
    
    // Check if item already exists in queue
    final existing = await db.query(
      'OfflineQueue',
      where: 'table_name = ? AND unique_field_value = ? AND status = ?',
      whereArgs: [tableName, uniqueFieldValue, 'pending'],
    );
    
    if (existing.isNotEmpty) {
      // If delete operation, remove existing and add delete
      if (operation == 'delete') {
        await db.delete(
          'OfflineQueue',
          where: 'table_name = ? AND unique_field_value = ?',
          whereArgs: [tableName, uniqueFieldValue],
        );
      } else {
        return existing.first['id'] as int;
      }
    }
    
    return await db.insert('OfflineQueue', {
      'table_name': tableName,
      'operation': operation,
      'unique_field': uniqueField,
      'unique_field_value': uniqueFieldValue,
      'data': data,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<List<Map<String, dynamic>>> getPendingOfflineQueue() async {
    final db = await database;
    return await db.query(
      'OfflineQueue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }
  
  Future<int> markOfflineQueueItemComplete(int id) async {
    final db = await database;
    return await db.update(
      'OfflineQueue',
      {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> markOfflineQueueItemFailed(int id, String error) async {
    final db = await database;
    return await db.update(
      'OfflineQueue',
      {
        'status': 'failed',
        'error_message': error,
        'retry_count': 1,  // Simplified; could increment
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<bool> hasOfflineQueueItems() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM OfflineQueue WHERE status = 'pending'"
    );
    return (result.first['count'] as int) > 0;
  }
  
  // ==================== AUTH TOKEN OPERATIONS ====================
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final db = await database;
    await db.delete('AuthToken');  // Clear old tokens
    await db.insert('AuthToken', {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<Map<String, String>?> getTokens() async {
    final db = await database;
    final maps = await db.query('AuthToken', limit: 1);
    if (maps.isEmpty) return null;
    return {
      'access_token': maps.first['access_token'] as String,
      'refresh_token': maps.first['refresh_token'] as String,
    };
  }
  
  Future<void> clearTokens() async {
    final db = await database;
    await db.delete('AuthToken');
  }
  
  // ==================== UTILITY OPERATIONS ====================
  
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('Payment');
    await db.delete('Contract');
    await db.delete('Customer');
    await db.delete('User');
    await db.delete('OfflineQueue');
    await db.delete('AuthToken');
  }
}
