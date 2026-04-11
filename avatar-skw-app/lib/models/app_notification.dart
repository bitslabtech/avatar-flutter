import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'order_update', 'account_update', etc.
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime createdDate;
    try {
      final rawDate = json['createdAt'] ?? json['created_at'];
      if (rawDate is String) {
        createdDate = DateTime.parse(rawDate);
      } else if (rawDate is int) {
         // Assume milliseconds if large, seconds if small? 
         // JS usually uses milliseconds for Date.now(), but unix timestamp is seconds.
         // Let's assume milliseconds as it's common in JS/Node.
         createdDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      } else if (rawDate != null) {
        debugPrint('Parsing arbitrary type date: $rawDate (${rawDate.runtimeType})');
        createdDate = DateTime.parse(rawDate.toString());
      } else {
        debugPrint('Notification date is NULL, falling back to now()');
        createdDate = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error parsing notification date: $e, Raw: ${json['createdAt'] ?? json['created_at']}');
      createdDate = DateTime.now();
    }
    
    // Check if the resulting date is suspiciously close to now (fallback blocked verification)
    // debugPrint('Parsed Notification Date: $createdDate (Raw: ${json['createdAt']})');

    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'No Title',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      data: json['data'] != null ? json['data'] as Map<String, dynamic> : null,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: createdDate,
    );
  }
}
