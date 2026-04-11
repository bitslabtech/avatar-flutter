class ContactSettings {
  final String id;
  final String? supportEmail;
  final String? whatsappNumber;
  final String? callNumber;
  final bool isActive;
  final DateTime updatedAt;

  ContactSettings({
    required this.id,
    this.supportEmail,
    this.whatsappNumber,
    this.callNumber,
    required this.isActive,
    required this.updatedAt,
  });

  factory ContactSettings.fromJson(Map<String, dynamic> json) {
    DateTime parsedUpdatedAt = DateTime.now();
    final updatedAtField = json['updatedAt'];
    
    if (updatedAtField != null && updatedAtField is String && updatedAtField.isNotEmpty) {
      try {
        parsedUpdatedAt = DateTime.parse(updatedAtField);
      } catch (e) {
        parsedUpdatedAt = DateTime.now();
      }
    }
    
    return ContactSettings(
      id: json['id'] as String? ?? '',
      supportEmail: json['supportEmail'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      callNumber: json['callNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supportEmail': supportEmail,
      'whatsappNumber': whatsappNumber,
      'callNumber': callNumber,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
