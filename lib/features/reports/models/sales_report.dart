import '../../../models/order.dart'; // Reuse existing Order model

class SalesReportResponse {
  final List<Order> data;
  final ReportMeta meta;
  final ReportSummary summary;

  SalesReportResponse({
    required this.data,
    required this.meta,
    required this.summary,
  });

  factory SalesReportResponse.fromJson(Map<String, dynamic> json) {
    return SalesReportResponse(
      data: (json['data'] as List).map((i) => Order.fromJson(i)).toList(),
      meta: ReportMeta.fromJson(json['meta']),
      summary: ReportSummary.fromJson(json['summary']),
    );
  }
}

class ReportMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ReportMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ReportMeta.fromJson(Map<String, dynamic> json) {
    return ReportMeta(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

class ReportSummary {
  final int totalOrders;
  final double totalRevenue;

  ReportSummary({
    required this.totalOrders,
    required this.totalRevenue,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}

class ReportFilters {
  final String? startDate;
  final String? endDate;
  final String? userType; // 'dealer' or 'consumer' or null
  final String? search;
  final String? dealerId;
  final String? userId; // For specific user filtering
  final int page;
  final int limit;

  ReportFilters({
    this.startDate,
    this.endDate,
    this.userType,
    this.search,
    this.dealerId,
    this.userId, // Added userId
    this.page = 1,
    this.limit = 10,
  });

  static const _unset = Object();

  ReportFilters copyWith({
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? userType = _unset,
    Object? search = _unset,
    Object? dealerId = _unset,
    Object? userId = _unset,
    int? page,
    int? limit,
  }) {
    return ReportFilters(
      startDate: startDate == _unset ? this.startDate : startDate as String?,
      endDate: endDate == _unset ? this.endDate : endDate as String?,
      userType: userType == _unset ? this.userType : userType as String?,
      search: search == _unset ? this.search : search as String?,
      dealerId: dealerId == _unset ? this.dealerId : dealerId as String?,
      userId: userId == _unset ? this.userId : userId as String?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'page': page,
      'limit': limit,
    };
    if (startDate != null) data['startDate'] = startDate;
    if (endDate != null) data['endDate'] = endDate;
    if (userType != null) data['userType'] = userType;
    if (search != null && search!.isNotEmpty) data['search'] = search;
    if (dealerId != null) data['dealerId'] = dealerId;
    if (userId != null) data['userId'] = userId;
    return data;
  }
}
