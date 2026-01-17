import 'local_db_migration.dart';
import 'migrations_data.dart';

/// Get SQLite type for field type
String getSQLiteType(String type) {
  switch (type) {
    case 'file':
      return 'BLOB';
    case 'string':
      return 'TEXT';
    case 'integer':
      return 'INTEGER';
    case 'double':
      return 'REAL';
    case 'boolean':
      return 'INTEGER';
    case 'date':
      return 'TEXT';
    case 'list':
      return 'TEXT';
    case 'map':
      return 'TEXT';
    default:
      return 'TEXT';
  }
}

/// Get default value for field type
String getDefaultValue(String type, dynamic defaultValue) {
  if (defaultValue != null) {
    if (type == 'string' || type == 'date') {
      return "'$defaultValue'";
    }
    return defaultValue.toString();
  }

  switch (type) {
    case 'string':
      return "''";
    case 'integer':
      return '0';
    case 'double':
      return '0.0';
    case 'boolean':
      return '0';
    case 'date':
      return "datetime('now')";
    case 'list':
      return "''";
    case 'map':
      return "''";
    default:
      return 'NULL';
  }
}

/// Generate SQL statements to modify a table based on migration
List<String> generateTableModificationSQL(
    TableMigration migration, List<String> existingColumns) {
  List<String> sqlStatements = [];
  String tableName = migration.table;

  for (var field in migration.fieldItems) {
    // Skip if column already exists for add operations
    if (field.action == 'add' && existingColumns.contains(field.fieldName)) {
      continue;
    }

    String fieldType = getSQLiteType(field.type);
    String defaultValueStr = '';

    if (field.defaultValue != null) {
      defaultValueStr =
          ' DEFAULT ${getDefaultValue(field.type, field.defaultValue)}';
    }

    switch (field.action) {
      case 'add':
        sqlStatements.add(
            'ALTER TABLE $tableName ADD COLUMN ${field.fieldName} $fieldType$defaultValueStr');
        break;

      case 'rename':
        if (field.oldName.isNotEmpty) {
          sqlStatements.add(
              'ALTER TABLE $tableName RENAME COLUMN ${field.oldName} TO ${field.fieldName}');
        }
        break;
    }
  }

  return sqlStatements;
}

/// Get the current schema for a table by applying all migrations
List<FieldItem> getCurrentTableSchema(String tableName) {
  Map<String, FieldItem> latestFields = {};

  // First check initial migration
  var initialTable = initialMigration.firstWhere(
    (table) => table.table == tableName,
    orElse: () =>
        TableMigration(table: tableName, migrationVersion: 0, fieldItems: []),
  );

  // Add initial fields
  for (var field in initialTable.fieldItems) {
    latestFields[field.fieldName] = field;
  }

  // Then apply all subsequent migrations in order
  for (var migrationList in migrations) {
    var migration = migrationList.firstWhere(
      (table) => table.table == tableName,
      orElse: () =>
          TableMigration(table: tableName, migrationVersion: 0, fieldItems: []),
    );

    // Apply each field modification
    for (var field in migration.fieldItems) {
      switch (field.action) {
        case 'add':
          latestFields[field.fieldName] = field;
          break;
        case 'remove':
          latestFields.remove(field.fieldName);
          break;
        case 'rename':
          if (field.oldName.isNotEmpty) {
            latestFields.remove(field.oldName);
            latestFields[field.fieldName] = field;
          }
          break;
        case 'modify':
          if (latestFields.containsKey(field.fieldName)) {
            latestFields[field.fieldName] = FieldItem(
              fieldName: field.fieldName,
              type: field.type,
              action: 'add',
              oldName: '',
              isPrimaryKey: latestFields[field.fieldName]!.isPrimaryKey,
              autoIncreasePrimaryKey:
                  latestFields[field.fieldName]!.autoIncreasePrimaryKey,
              defaultValue: field.defaultValue ??
                  latestFields[field.fieldName]!.defaultValue,
              isUnique: latestFields[field.fieldName]!.isUnique,
            );
          }
          break;
      }
    }
  }

  return latestFields.values.toList();
}
