/// Database migration classes for BuyMore Agent App
/// 
/// This file contains the classes used to define database table structures
/// and track schema changes across versions.

class TableMigration {
  final String table;
  final int migrationVersion;
  final List<FieldItem> fieldItems;

  TableMigration({
    required this.table,
    required this.migrationVersion,
    required this.fieldItems,
  });
}

class FieldItem {
  final String fieldName;
  final String action;
  final String oldName;
  final String type;
  final bool isPrimaryKey;
  final bool autoIncreasePrimaryKey;
  final dynamic defaultValue;
  final bool isUnique;

  FieldItem({
    required this.fieldName,
    required this.type,
    required this.action,
    required this.oldName,
    this.defaultValue,
    this.isPrimaryKey = false,
    this.autoIncreasePrimaryKey = true,
    this.isUnique = false,
  });

  /// Actions:
  /// - 'add': Add a new field
  /// - 'remove': Remove an existing field
  /// - 'rename': Rename a field (oldName is the field to be renamed, fieldName is the new name)
  /// - 'modify': Change field type or defaultValue

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'type': type,
      'action': action,
      'oldName': oldName,
      'defaultValue': defaultValue,
      'isPrimaryKey': isPrimaryKey,
      'autoIncreasePrimaryKey': autoIncreasePrimaryKey,
      'isUnique': isUnique,
    };
  }
}
