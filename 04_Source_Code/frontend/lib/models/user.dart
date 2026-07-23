class User {
  final String id;
  final String email;
  final String nickname;
  final String role;
  final String status;
  final int currentPoints;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final List<String> roles;
  final String businessApplicationStatus;
  final List<String> capabilities;
  final List<String> availableAppModes;
  final List<Map<String, dynamic>> businessMemberships;

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
    required this.status,
    this.currentPoints = 0,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.roles = const ['CUSTOMER'],
    this.businessApplicationStatus = 'NONE',
    this.capabilities = const [],
    this.availableAppModes = const ['CUSTOMER'],
    this.businessMemberships = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesList =
        (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        ['CUSTOMER'];
    final capsList =
        (json['capabilities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final modesList =
        (json['available_app_modes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['CUSTOMER'];
    final memsList =
        (json['business_memberships'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      currentPoints: json['current_points'] as int? ?? 0,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      roles: rolesList,
      businessApplicationStatus:
          json['business_application_status'] as String? ?? 'NONE',
      capabilities: capsList,
      availableAppModes: modesList,
      businessMemberships: memsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'role': role,
      'status': status,
      'current_points': currentPoints,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'roles': roles,
      'business_application_status': businessApplicationStatus,
      'capabilities': capabilities,
      'available_app_modes': availableAppModes,
      'business_memberships': businessMemberships,
    };
  }

  bool get isApprovedBusiness =>
      roles.contains('BUSINESS') && availableAppModes.contains('BUSINESS');

  bool get isAdmin => roles.contains('ADMIN') || role == 'admin';

  User copyWith({
    String? id,
    String? email,
    String? nickname,
    String? role,
    String? status,
    int? currentPoints,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    List<String>? roles,
    String? businessApplicationStatus,
    List<String>? capabilities,
    List<String>? availableAppModes,
    List<Map<String, dynamic>>? businessMemberships,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      status: status ?? this.status,
      currentPoints: currentPoints ?? this.currentPoints,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      roles: roles ?? this.roles,
      businessApplicationStatus:
          businessApplicationStatus ?? this.businessApplicationStatus,
      capabilities: capabilities ?? this.capabilities,
      availableAppModes: availableAppModes ?? this.availableAppModes,
      businessMemberships: businessMemberships ?? this.businessMemberships,
    );
  }
}
