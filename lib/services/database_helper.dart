import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/customer.dart';
import '../models/contract.dart';
import '../models/payment.dart';
import 'local_db_migration.dart';
import 'db_migration_methods.dart';
import 'migrations_data.dart';

/// Database helper for local SQLite storage
/// 
/// Implements offline-first pattern with sync tracking
/// Uses a migration system for schema updates
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => _instance;
  
  DatabaseHelper._internal();
  
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
      version: currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  /// Generates SQL CREATE TABLE statement from TableMigration
  String _generateCreateTableSQL(TableMigration table) {
    List<String> columns = [];

    for (var field in table.fieldItems) {
      // Skip removed fields
      if (field.action == 'remove') continue;

      String fieldDef = '${field.fieldName} ${getSQLiteType(field.type)}';

      if (field.isPrimaryKey) {
        fieldDef += ' PRIMARY KEY';
        if (field.autoIncreasePrimaryKey) {
          fieldDef += ' AUTOINCREMENT';
        }
      }

      if (field.isUnique) {
        fieldDef += ' UNIQUE';
      }

      if (field.defaultValue != null) {
        fieldDef +=
            ' DEFAULT ${getDefaultValue(field.type, field.defaultValue)}';
      }

      columns.add(fieldDef);
    }

    return '''
      CREATE TABLE ${table.table} (
        ${columns.join(',\n        ')}
      )
    ''';
  }

  /// Updates initialMigration based on subsequent migrations
  List<TableMigration> _applyMigrationsToInitialSchema(
      List<TableMigration> initialSchema,
      List<List<TableMigration>> allMigrations) {
    List<TableMigration> updatedSchema =
        List<TableMigration>.from(initialSchema);

    for (List<TableMigration> migrationSet in allMigrations) {
      for (TableMigration migration in migrationSet) {
        // Find existing table or create new one
        int tableIndex =
            updatedSchema.indexWhere((t) => t.table == migration.table);

        if (tableIndex == -1) {
          // New table - add to schema
          updatedSchema.add(migration);
          continue;
        }

        // Update existing table
        TableMigration existingTable = updatedSchema[tableIndex];
        List<FieldItem> updatedFields =
            List<FieldItem>.from(existingTable.fieldItems);

        for (FieldItem field in migration.fieldItems) {
          switch (field.action) {
            case 'add':
              updatedFields.add(field);
              break;
            case 'remove':
              updatedFields.removeWhere((f) => f.fieldName == field.fieldName);
              break;
            case 'rename':
              int index =
                  updatedFields.indexWhere((f) => f.fieldName == field.oldName);
              if (index != -1) {
                updatedFields[index] = field;
              }
              break;
            case 'modify':
              int index = updatedFields
                  .indexWhere((f) => f.fieldName == field.fieldName);
              if (index != -1) {
                updatedFields[index] = field;
              }
              break;
          }
        }

        updatedSchema[tableIndex] = TableMigration(
          table: migration.table,
          migrationVersion: 1,
          fieldItems: updatedFields,
        );
      }
    }

    return updatedSchema;
  }
  
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Apply all migrations to initial schema
      List<TableMigration> finalSchema =
          _applyMigrationsToInitialSchema(initialMigration, migrations);

      // Create tables
      for (TableMigration table in finalSchema) {
        await db.execute(_generateCreateTableSQL(table));
      }
      
      // Create indexes for better performance
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_agent ON Customer(agent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_registered_by ON Customer(registered_by_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_contract_customer ON Contract(customer_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_contract_agent ON Contract(agent_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_contract_status ON Contract(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_contract ON Payment(contract_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_customer ON Payment(customer_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_status ON Payment(approval_status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payment_date ON Payment(payment_date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_offline_queue_status ON OfflineQueue(status)');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // Apply upgrades version by version
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        if (version - 2 >= 0 && version - 2 < migrations.length) {
          List<TableMigration> migrationSet = migrations[version - 2];

          for (TableMigration migration in migrationSet) {
            // Check if this is a new table
            bool tableExists = await _checkIfTableExists(db, migration.table);

            if (!tableExists) {
              // Create new table
              await db.execute(_generateCreateTableSQL(migration));
            } else if (!deletedTables.contains(migration.table)) {
              // Handle modifications to existing table
              await _handleTableMigration(db, migration);
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if a table exists in the database
  Future<bool> _checkIfTableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]);
    return result.isNotEmpty;
  }

  /// Handles migration for a single table
  Future<void> _handleTableMigration(
      Database db, TableMigration migration) async {
    // Skip if table is marked for deletion
    if (deletedTables.contains(migration.table)) {
      return;
    }

    // Check if there are any actual changes to make
    bool hasChanges = migration.fieldItems.any((field) =>
        field.action == 'add' ||
        field.action == 'remove' ||
        field.action == 'rename' ||
        field.action == 'modify');

    if (!hasChanges) {
      return;
    }

    List<String> sqlStatements = generateTableModificationSQL(migration, []);

    if (sqlStatements.isEmpty) {
      return;
    }

    for (String sql in sqlStatements) {
      try {
        await db.execute(sql);
      } catch (e) {
        // Column might already exist, continue
        print('Migration warning: $e');
      }
    }
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
      maps = await db.query('Customer', 
        where: 'agent_id = ? OR registered_by_id = ?', 
        whereArgs: [agentId, agentId]);
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
      where: 'full_name LIKE ? OR phone_number LIKE ? OR customer_number LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
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
  
  Future<List<Payment>> getPaymentsByContract(int contractId) async {
    final db = await database;
    final maps = await db.query(
      'Payment',
      where: 'contract_id = ?',
      whereArgs: [contractId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((e) => Payment.fromLocalJson(e)).toList();
  }
  
  Future<List<Payment>> getPaymentsByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'Payment',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'payment_date DESC',
      limit: 10,
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
  
  /// Force database reset - useful for development
  /// WARNING: This deletes all data!
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    await deleteDatabase(path);
    _database = null;
    await database; // Recreate database
  }
}
