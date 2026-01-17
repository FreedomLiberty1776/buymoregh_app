/// User/Agent model for BuyMore Agent App

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? agentCode;
  final String? assignedRegion;
  final bool isAgent;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool isActive;
  final bool isStaff;
  final Map<String, bool> permissions;
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.agentCode,
    this.assignedRegion,
    required this.isAgent,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    required this.isActive,
    required this.isStaff,
    required this.permissions,
    this.dateJoined,
    this.lastLogin,
  });

  String get fullName => '$firstName $lastName'.trim();
  
  String get displayName => fullName.isNotEmpty ? fullName : username;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      agentCode: json['agent_code'],
      assignedRegion: json['assigned_region'],
      isAgent: json['is_agent'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isSuperAdmin: json['is_super_admin'] ?? false,
      isActive: json['is_active'] ?? true,
      isStaff: json['is_staff'] ?? false,
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
      dateJoined: json['date_joined'] != null 
          ? DateTime.parse(json['date_joined']) 
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'agent_code': agentCode,
      'assigned_region': assignedRegion,
      'is_agent': isAgent,
      'is_admin': isAdmin,
      'is_super_admin': isSuperAdmin,
      'is_active': isActive,
      'is_staff': isStaff,
      'permissions': permissions,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  /// For local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'agent_code': agentCode,
      'assigned_region': assignedRegion,
      'is_agent': isAgent ? 1 : 0,
      'is_admin': isAdmin ? 1 : 0,
      'is_super_admin': isSuperAdmin ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_staff': isStaff ? 1 : 0,
      'permissions': permissions.toString(),
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromLocalJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      agentCode: json['agent_code'],
      assignedRegion: json['assigned_region'],
      isAgent: json['is_agent'] == 1,
      isAdmin: json['is_admin'] == 1,
      isSuperAdmin: json['is_super_admin'] == 1,
      isActive: json['is_active'] == 1,
      isStaff: json['is_staff'] == 1,
      permissions: {},  // Parse from string if needed
      dateJoined: json['date_joined'] != null 
          ? DateTime.parse(json['date_joined']) 
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? agentCode,
    String? assignedRegion,
    bool? isAgent,
    bool? isAdmin,
    bool? isSuperAdmin,
    bool? isActive,
    bool? isStaff,
    Map<String, bool>? permissions,
    DateTime? dateJoined,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      agentCode: agentCode ?? this.agentCode,
      assignedRegion: assignedRegion ?? this.assignedRegion,
      isAgent: isAgent ?? this.isAgent,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isActive: isActive ?? this.isActive,
      isStaff: isStaff ?? this.isStaff,
      permissions: permissions ?? this.permissions,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
