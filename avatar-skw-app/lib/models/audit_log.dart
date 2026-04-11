
class AuditLog {
  final String id;
  final String? adminId;
  final String action;
  final String module;
  final String title;
  final String? description;
  final String? details; // JSON string
  final String? ipAddress;
  final String tag;
  final DateTime createdAt;
  final Map<String, dynamic>? admin;

  AuditLog({
    required this.id,
    this.adminId,
    required this.action,
    required this.module,
    required this.title,
    this.description,
    this.details,
    this.ipAddress,
    required this.tag,
    required this.createdAt,
    this.admin,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      adminId: json['admin_id'],
      action: json['action'],
      module: json['module'],
      title: json['title'],
      description: json['description'],
      details: json['details'],
      ipAddress: json['ip_address'],
      tag: json['tag'],
      createdAt: DateTime.parse(json['created_at']),
      admin: json['admin'] != null ? json['admin'] : null,
    );
  }
}
