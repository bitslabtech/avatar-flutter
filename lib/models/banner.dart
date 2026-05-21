/// Banner model for promotional banners on home screen
/// Used in the banner slider carousel
import '../core/api/api_endpoints.dart';

class Banner {
  final String id;
  final String? title;
  final String imageUrl;
  final String? linkUrl; // Optional link to navigate to (product, category, etc.)
  final String? tag;
  final String? description;
  final String? btnText;
  final int order; // Display order for sorting
  final bool isActive;

  Banner({
    required this.id,
    this.title,
    required this.imageUrl,
    this.linkUrl,
    this.tag,
    this.description,
    this.btnText,
    required this.order,
    this.isActive = true,
  });

  String get resolvedImageUrl => ApiEndpoints.resolveImageUrl(imageUrl);

  /// Create Banner from JSON response
  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as String,
      title: json['title'] as String?,
      imageUrl: json['imageUrl'] as String,
      linkUrl: json['linkUrl'] as String?,
      tag: json['tag'] as String?,
      description: json['description'] as String?,
      btnText: json['btnText'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert Banner to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'tag': tag,
      'description': description,
      'btnText': btnText,
      'order': order,
      'isActive': isActive,
    };
  }
}


