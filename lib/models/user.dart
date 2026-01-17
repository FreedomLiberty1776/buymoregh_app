/// User/Agent model for BuyMore Agent App

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? agentCode;
  final bool isAgent;
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
    required this.isAgent,
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
      isAgent: json['is_agent'] ?? false,
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
      'is_agent': isAgent,
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
      'is_agent': isAgent ? 1 : 0,
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
      isAgent: json['is_agent'] == 1,
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
    bool? isAgent,
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
      isAgent: isAgent ?? this.isAgent,
      isActive: isActive ?? this.isActive,
      isStaff: isStaff ?? this.isStaff,
      permissions: permissions ?? this.permissions,
      dateJoined: dateJoined ?? this.dateJoined,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
