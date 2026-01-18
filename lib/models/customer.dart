/// Customer model for BuyMore Agent App
/// Matches Django Customer model fields

class Customer {
  final int id;
  final String? customerNumber;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? nationalId;
  final String? address;
  final String? city;
  final String? region;
  // Next of Kin
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;
  // Employment
  final String? occupation;
  final String? workplace;
  final double? monthlyIncome;
  // Photos
  final String? passportPhoto;
  final String? idPhoto;
  // Agent
  final int? registeredById;
  final String? registeredByName;
  // Status
  final bool isActive;
  final int contractCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Sync tracking
  final bool isSynced;
  final String? localUniqueId;

  Customer({
    required this.id,
    this.customerNumber,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.nationalId,
    this.address,
    this.city,
    this.region,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelationship,
    this.occupation,
    this.workplace,
    this.monthlyIncome,
    this.passportPhoto,
    this.idPhoto,
    this.registeredById,
    this.registeredByName,
    this.isActive = true,
    this.contractCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.localUniqueId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      customerNumber: json['customer_number'],
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      nationalId: json['national_id'],
      address: json['address'],
      city: json['city'],
      region: json['region'],
      nextOfKinName: json['next_of_kin_name'],
      nextOfKinPhone: json['next_of_kin_phone'],
      nextOfKinRelationship: json['next_of_kin_relationship'],
      occupation: json['occupation'],
      workplace: json['workplace'],
      monthlyIncome: _parseDouble(json['monthly_income']),
      passportPhoto: json['passport_photo'],
      idPhoto: json['id_photo'],
      registeredById: json['registered_by'],
      registeredByName: json['registered_by_name'],
      isActive: json['is_active'] ?? true,
      contractCount: json['contract_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_number': customerNumber,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'national_id': nationalId,
      'address': address,
      'city': city,
      'region': region,
      'next_of_kin_name': nextOfKinName,
      'next_of_kin_phone': nextOfKinPhone,
      'next_of_kin_relationship': nextOfKinRelationship,
      'occupation': occupation,
      'workplace': workplace,
      'monthly_income': monthlyIncome?.toString(),
      'passport_photo': passportPhoto,
      'id_photo': idPhoto,
      'registered_by': registeredById,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For API submission (create customer)
  Map<String, dynamic> toCreateJson() {
    final json = <String, dynamic>{
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
    };
    
    if (email != null && email!.isNotEmpty) json['email'] = email;
    if (nationalId != null && nationalId!.isNotEmpty) json['national_id'] = nationalId;
    if (city != null && city!.isNotEmpty) json['city'] = city;
    if (region != null && region!.isNotEmpty) json['region'] = region;
    if (nextOfKinName != null && nextOfKinName!.isNotEmpty) json['next_of_kin_name'] = nextOfKinName;
    if (nextOfKinPhone != null && nextOfKinPhone!.isNotEmpty) json['next_of_kin_phone'] = nextOfKinPhone;
    if (nextOfKinRelationship != null && nextOfKinRelationship!.isNotEmpty) json['next_of_kin_relationship'] = nextOfKinRelationship;
    if (occupation != null && occupation!.isNotEmpty) json['occupation'] = occupation;
    if (workplace != null && workplace!.isNotEmpty) json['workplace'] = workplace;
    if (monthlyIncome != null) json['monthly_income'] = monthlyIncome.toString();
    if (passportPhoto != null && passportPhoto!.isNotEmpty) json['passport_photo'] = passportPhoto;
    if (idPhoto != null && idPhoto!.isNotEmpty) json['id_photo'] = idPhoto;
    if (localUniqueId != null) json['client_reference'] = localUniqueId;
    
    return json;
  }

  /// For local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'customer_number': customerNumber ?? '',
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email ?? '',
      'national_id': nationalId ?? '',
      'address': address ?? '',
      'city': city ?? '',
      'region': region ?? '',
      'next_of_kin_name': nextOfKinName ?? '',
      'next_of_kin_phone': nextOfKinPhone ?? '',
      'next_of_kin_relationship': nextOfKinRelationship ?? '',
      'occupation': occupation ?? '',
      'workplace': workplace ?? '',
      'monthly_income': monthlyIncome,
      'passport_photo': passportPhoto,
      'id_photo': idPhoto,
      // Store in both old and new columns for compatibility
      'agent_id': registeredById,
      'registered_by_id': registeredById,
      'registered_by_name': registeredByName ?? '',
      'is_active': isActive ? 1 : 0,
      'contract_count': contractCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'local_unique_id': localUniqueId,
    };
  }

  factory Customer.fromLocalJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      customerNumber: json['customer_number'],
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      // Handle both old (id_number) and new (national_id) column names
      nationalId: json['national_id'] ?? json['id_number'],
      address: json['address'],
      city: json['city'],
      region: json['region'],
      nextOfKinName: json['next_of_kin_name'],
      nextOfKinPhone: json['next_of_kin_phone'],
      nextOfKinRelationship: json['next_of_kin_relationship'],
      occupation: json['occupation'],
      workplace: json['workplace'],
      monthlyIncome: _parseDouble(json['monthly_income']),
      passportPhoto: json['passport_photo'] ?? json['profile_photo'],
      idPhoto: json['id_photo'],
      // Handle both old (agent_id) and new (registered_by_id) column names
      registeredById: json['registered_by_id'] ?? json['agent_id'],
      registeredByName: json['registered_by_name'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      contractCount: json['contract_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
      localUniqueId: json['local_unique_id'],
    );
  }

  Customer copyWith({
    int? id,
    String? customerNumber,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? nationalId,
    String? address,
    String? city,
    String? region,
    String? nextOfKinName,
    String? nextOfKinPhone,
    String? nextOfKinRelationship,
    String? occupation,
    String? workplace,
    double? monthlyIncome,
    String? passportPhoto,
    String? idPhoto,
    int? registeredById,
    String? registeredByName,
    bool? isActive,
    int? contractCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? localUniqueId,
  }) {
    return Customer(
      id: id ?? this.id,
      customerNumber: customerNumber ?? this.customerNumber,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      nextOfKinName: nextOfKinName ?? this.nextOfKinName,
      nextOfKinPhone: nextOfKinPhone ?? this.nextOfKinPhone,
      nextOfKinRelationship: nextOfKinRelationship ?? this.nextOfKinRelationship,
      occupation: occupation ?? this.occupation,
      workplace: workplace ?? this.workplace,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      passportPhoto: passportPhoto ?? this.passportPhoto,
      idPhoto: idPhoto ?? this.idPhoto,
      registeredById: registeredById ?? this.registeredById,
      registeredByName: registeredByName ?? this.registeredByName,
      isActive: isActive ?? this.isActive,
      contractCount: contractCount ?? this.contractCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      localUniqueId: localUniqueId ?? this.localUniqueId,
    );
  }
}

/// Ghana regions list for dropdown
const List<String> ghanaRegions = [
  'Greater Accra',
  'Ashanti',
  'Western',
  'Eastern',
  'Central',
  'Northern',
  'Volta',
  'Bono',
  'Bono East',
  'Ahafo',
  'Upper East',
  'Upper West',
  'North East',
  'Savannah',
  'Oti',
  'Western North',
];

/// Relationship options for next of kin
const List<String> nokRelationships = [
  'Spouse',
  'Parent',
  'Sibling',
  'Child',
  'Friend',
  'Colleague',
  'Other',
];
