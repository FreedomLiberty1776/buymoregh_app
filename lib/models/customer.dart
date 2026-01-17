/// Customer model for BuyMore Agent App

class Customer {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? address;
  final String? idType;
  final String? idNumber;
  final String? profilePhoto;
  final int? agentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Sync tracking
  final bool isSynced;
  final String? localUniqueId;

  Customer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.address,
    this.idType,
    this.idNumber,
    this.profilePhoto,
    this.agentId,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.localUniqueId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      address: json['address'],
      idType: json['id_type'],
      idNumber: json['id_number'],
      profilePhoto: json['profile_photo'],
      agentId: json['agent'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'id_type': idType,
      'id_number': idNumber,
      'profile_photo': profilePhoto,
      'agent': agentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'id_type': idType,
      'id_number': idNumber,
      'profile_photo': profilePhoto,
      'agent_id': agentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'local_unique_id': localUniqueId,
    };
  }

  factory Customer.fromLocalJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      address: json['address'],
      idType: json['id_type'],
      idNumber: json['id_number'],
      profilePhoto: json['profile_photo'],
      agentId: json['agent_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isSynced: json['is_synced'] == 1,
      localUniqueId: json['local_unique_id'],
    );
  }

  Customer copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? address,
    String? idType,
    String? idNumber,
    String? profilePhoto,
    int? agentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? localUniqueId,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      agentId: agentId ?? this.agentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      localUniqueId: localUniqueId ?? this.localUniqueId,
    );
  }
}
