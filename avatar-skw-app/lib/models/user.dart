/// User model representing the authenticated user
/// Maps to the backend User entity
class User {
  final String id;
  final String name;
  final String phone;
  final String? alternativePhone;
  final String? email;
  final String? companyName;
  final String? gstVat;
  final String role; // 'consumer', 'dealer', 'admin', 'super_admin'
  final String status; // 'pending', 'approved', 'rejected', 'active', 'inactive'
  final double discountPercentage;
  final Map<String, dynamic>? address;
  final String? avatar; // Added avatar field
  final Map<String, List<dynamic>>? permissions; // Admin permissions

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.alternativePhone,
    this.email,
    this.companyName,
    this.gstVat,
    required this.role,
    required this.status,
    this.discountPercentage = 0.0,
    this.address,
    this.avatar,
    this.permissions,
  });

  /// Create User from JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      companyName: json['companyName'] as String?,
      gstVat: json['gstVat'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      discountPercentage: double.tryParse(json['discountPercentage']?.toString() ?? '0') ?? 0.0,
      address: json['address'] as Map<String, dynamic>?,
      avatar: json['avatar'] as String?,
      alternativePhone: json['alternativePhone'] as String?,
      permissions: json['permissions'] != null 
          ? (json['permissions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<dynamic>.from(value)))
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'alternativePhone': alternativePhone,
      'email': email,
      'companyName': companyName,
      'gstVat': gstVat,
      'role': role,
      'status': status,
      'discountPercentage': discountPercentage,
      'address': address,
      'avatar': avatar,
      'permissions': permissions,
    };
  }

  /// Check if user is active
  bool get isActive => status == 'active' || status == 'approved';

  /// Role checks
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isDealer => role == 'dealer';
  bool get isConsumer => role == 'consumer';

  // Permission Checks
  bool hasPermission(String resource, String action) {
    if (isSuperAdmin) return true;
    if (permissions == null) return false;
    
    final resourcePerms = permissions![resource];
    if (resourcePerms == null) return false;
    
    return resourcePerms.contains(action);
  }
}

