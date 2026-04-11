class Category {
  final String id;
  final String name;
  final String? icon;
  final String? imageUrl;
  final String? title;
  final String? description;
  final bool isActive;
  final int order;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    this.title,
    this.description,
    this.isActive = true,
    this.order = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      imageUrl: json['imageUrl'] ?? json['image_url'], // Support camelCase or snake_case from DB
      title: json['title'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      order: json['order'] is int ? json['order'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'isActive': isActive,
      'order': order,
    };
  }
}
