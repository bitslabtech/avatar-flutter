import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../providers/auth_provider.dart'; // Import for apiClientProvider
import '../models/sales_report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.read(apiClientProvider));
});

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<SalesReportResponse> getSalesReports(ReportFilters filters) async {
    try {
      final response = await _apiClient.get(
        '/reports/sales',
        queryParameters: filters.toJson(),
      );
      return SalesReportResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load sales reports: $e');
    }
  }

  Future<List<int>> exportSalesReports(ReportFilters filters) async {
    try {
      final response = await _apiClient.get(
        '/reports/sales/export',
        queryParameters: filters.toJson(),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (e) {
      throw Exception('Failed to export sales reports: $e');
    }
  }
}
