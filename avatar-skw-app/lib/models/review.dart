class Review {
  final String id;
  final int rating;
  final String? comment;
  final String userId;
  final String userName; // For display
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'],
      userId: json['userId'],
      userName: json['user'] != null 
          ? json['user']['name'] ?? 'Anonymous'
          : 'Anonymous',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
