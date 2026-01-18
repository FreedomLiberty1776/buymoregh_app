import 'local_db_migration.dart';

/// Current database version
/// Increment this whenever you add a new migration
const int currentVersion = 4;

/// Initial database schema (version 1)
/// This represents the original table structures
List<TableMigration> initialMigration = [
  // User Table
  TableMigration(table: 'User', migrationVersion: 1, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: false),
    FieldItem(fieldName: 'username', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'email', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'first_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'last_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'phone_number', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'agent_code', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'is_agent', type: 'boolean', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'is_active', type: 'boolean', action: 'add', oldName: '', defaultValue: 1),
    FieldItem(fieldName: 'is_staff', type: 'boolean', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'permissions', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'date_joined', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'last_login', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'updated_at', type: 'string', action: 'add', oldName: ''),
  ]),

  // Customer Table - Original Schema
  TableMigration(table: 'Customer', migrationVersion: 1, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: false),
    FieldItem(fieldName: 'full_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'phone_number', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'email', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'address', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'id_type', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'id_number', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'profile_photo', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'agent_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'updated_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'is_synced', type: 'boolean', action: 'add', oldName: '', defaultValue: 1),
    FieldItem(fieldName: 'local_unique_id', type: 'string', action: 'add', oldName: '', isUnique: true),
  ]),

  // Contract Table
  TableMigration(table: 'Contract', migrationVersion: 1, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: false),
    FieldItem(fieldName: 'customer_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'customer_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'product_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'product_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'agent_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'total_amount', type: 'double', action: 'add', oldName: ''),
    FieldItem(fieldName: 'down_payment', type: 'double', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'total_paid', type: 'double', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'outstanding_balance', type: 'double', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'payment_percentage', type: 'double', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'duration_months', type: 'integer', action: 'add', oldName: '', defaultValue: 12),
    FieldItem(fieldName: 'interest_rate', type: 'double', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'status', type: 'string', action: 'add', oldName: '', defaultValue: 'ACTIVE'),
    FieldItem(fieldName: 'start_date', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'end_date', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'next_payment_date', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'monthly_installment', type: 'double', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'updated_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'is_synced', type: 'boolean', action: 'add', oldName: '', defaultValue: 1),
    FieldItem(fieldName: 'local_unique_id', type: 'string', action: 'add', oldName: '', isUnique: true),
  ]),

  // Payment Table
  TableMigration(table: 'Payment', migrationVersion: 1, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: false),
    FieldItem(fieldName: 'contract_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'customer_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'customer_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'agent_id', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'amount', type: 'double', action: 'add', oldName: ''),
    FieldItem(fieldName: 'payment_method', type: 'string', action: 'add', oldName: '', defaultValue: 'CASH'),
    FieldItem(fieldName: 'momo_phone', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'approval_status', type: 'string', action: 'add', oldName: '', defaultValue: 'PENDING'),
    FieldItem(fieldName: 'rejection_reason', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'approved_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'approved_by', type: 'integer', action: 'add', oldName: ''),
    FieldItem(fieldName: 'client_reference', type: 'string', action: 'add', oldName: '', isUnique: true),
    FieldItem(fieldName: 'paystack_reference', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'paystack_status', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'payment_date', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'updated_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'contract_outstanding_balance', type: 'double', action: 'add', oldName: ''),
    FieldItem(fieldName: 'contract_total_paid', type: 'double', action: 'add', oldName: ''),
    FieldItem(fieldName: 'contract_payment_percentage', type: 'double', action: 'add', oldName: ''),
    FieldItem(fieldName: 'is_synced', type: 'boolean', action: 'add', oldName: '', defaultValue: 1),
    FieldItem(fieldName: 'local_unique_id', type: 'string', action: 'add', oldName: '', isUnique: true),
  ]),

  // OfflineQueue Table
  TableMigration(table: 'OfflineQueue', migrationVersion: 1, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: true),
    FieldItem(fieldName: 'table_name', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'operation', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'unique_field', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'unique_field_value', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'data', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'status', type: 'string', action: 'add', oldName: '', defaultValue: 'pending'),
    FieldItem(fieldName: 'retry_count', type: 'integer', action: 'add', oldName: '', defaultValue: 0),
    FieldItem(fieldName: 'error_message', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'updated_at', type: 'string', action: 'add', oldName: ''),
  ]),

  // AuthToken Table
  TableMigration(table: 'AuthToken', migrationVersion: 1, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: true),
    FieldItem(fieldName: 'access_token', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'refresh_token', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'expires_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
  ]),
];

/// List of migrations (starting from version 2)
/// Each migration list corresponds to a version upgrade
List<List<TableMigration>> migrations = [
  migration2,
  migration3,
  migration4,
];

/// Migration 2: Add extended customer fields
/// This adds the new fields needed for the enhanced customer form
List<TableMigration> migration2 = [
  TableMigration(table: 'Customer', migrationVersion: 2, fieldItems: [
    // Customer number
    FieldItem(
        fieldName: 'customer_number',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    // Rename id_number to national_id
    FieldItem(
        fieldName: 'national_id',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    // Location fields
    FieldItem(
        fieldName: 'city',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'region',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    // Next of kin fields
    FieldItem(
        fieldName: 'next_of_kin_name',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'next_of_kin_phone',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'next_of_kin_relationship',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    // Employment fields
    FieldItem(
        fieldName: 'occupation',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'workplace',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'monthly_income',
        type: 'double',
        action: 'add',
        oldName: ''),
    // Photo fields
    FieldItem(
        fieldName: 'passport_photo',
        type: 'string',
        action: 'add',
        oldName: ''),
    FieldItem(
        fieldName: 'id_photo',
        type: 'string',
        action: 'add',
        oldName: ''),
    // Agent/registered by fields
    FieldItem(
        fieldName: 'registered_by_id',
        type: 'integer',
        action: 'add',
        oldName: ''),
    FieldItem(
        fieldName: 'registered_by_name',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    // Status fields
    FieldItem(
        fieldName: 'is_active',
        type: 'boolean',
        action: 'add',
        oldName: '',
        defaultValue: 1),
    FieldItem(
        fieldName: 'contract_count',
        type: 'integer',
        action: 'add',
        oldName: '',
        defaultValue: 0),
  ]),
];

/// Migration 3: Add User fields and AppSettings table
List<TableMigration> migration3 = [
  // Add new User fields
  TableMigration(table: 'User', migrationVersion: 3, fieldItems: [
    FieldItem(
        fieldName: 'assigned_region',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'is_admin',
        type: 'boolean',
        action: 'add',
        oldName: '',
        defaultValue: 0),
    FieldItem(
        fieldName: 'is_super_admin',
        type: 'boolean',
        action: 'add',
        oldName: '',
        defaultValue: 0),
  ]),
  // Add Payment fields
  TableMigration(table: 'Payment', migrationVersion: 3, fieldItems: [
    FieldItem(
        fieldName: 'customer_phone',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'agent_name',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'notes',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'product_name',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
    FieldItem(
        fieldName: 'product_id',
        type: 'integer',
        action: 'add',
        oldName: ''),
    FieldItem(
        fieldName: 'contract_total_amount',
        type: 'double',
        action: 'add',
        oldName: '',
        defaultValue: 0),
    FieldItem(
        fieldName: 'balance_before',
        type: 'double',
        action: 'add',
        oldName: '',
        defaultValue: 0),
    FieldItem(
        fieldName: 'balance_after',
        type: 'double',
        action: 'add',
        oldName: '',
        defaultValue: 0),
  ]),
  // Add AppSettings table
  TableMigration(table: 'AppSettings', migrationVersion: 3, fieldItems: [
    FieldItem(
        fieldName: 'id',
        type: 'integer',
        action: 'add',
        oldName: '',
        isPrimaryKey: true,
        autoIncreasePrimaryKey: true),
    FieldItem(
        fieldName: 'key',
        type: 'string',
        action: 'add',
        oldName: '',
        isUnique: true),
    FieldItem(fieldName: 'value', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'created_at', type: 'string', action: 'add', oldName: ''),
    FieldItem(fieldName: 'updated_at', type: 'string', action: 'add', oldName: ''),
  ]),
];

/// Migration 4: Add missing customer_number field to Payment table
List<TableMigration> migration4 = [
  TableMigration(table: 'Payment', migrationVersion: 4, fieldItems: [
    FieldItem(
        fieldName: 'customer_number',
        type: 'string',
        action: 'add',
        oldName: '',
        defaultValue: ''),
  ]),
];

/// Tables that have been deleted and should be skipped during migration
List<String> deletedTables = [];
