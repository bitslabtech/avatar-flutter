class Content {
  final String id;
  final String key;
  final String title;
  final String body;
  final bool isActive;
  final DateTime updatedAt;

  Content({
    required this.id,
    required this.key,
    required this.title,
    required this.body,
    required this.isActive,
    required this.updatedAt,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    // Handle updatedAt which can be a string, null, or empty object {}
    DateTime parsedUpdatedAt = DateTime.now();
    final updatedAtField = json['updatedAt'];
    
    if (updatedAtField != null && updatedAtField is String && updatedAtField.isNotEmpty) {
      try {
        parsedUpdatedAt = DateTime.parse(updatedAtField);
      } catch (e) {
        print('Error parsing updatedAt: $e');
        parsedUpdatedAt = DateTime.now();
      }
    }
    
    return Content(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'title': title,
      'body': body,
      'isActive': isActive,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
