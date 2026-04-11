
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../models/audit_log.dart';
import '../../../providers/auth_provider.dart';

// Filter State
class AuditLogFilters {
  final String? module;
  final String? action;
  final String? adminId;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditLogFilters({
    this.module,
    this.action,
    this.adminId,
    this.startDate,
    this.endDate,
  });

  AuditLogFilters copyWith({
    String? module,
    String? action,
    String? adminId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AuditLogFilters(
      module: module ?? this.module,
      action: action ?? this.action,
      adminId: adminId ?? this.adminId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// State
class AuditLogsState {
  final List<AuditLog> logs;
  final int total;
  final bool isLoading;
  final String? error;
  final AuditLogFilters filters;
  final int page;
  final int limit;

  const AuditLogsState({
    this.logs = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.filters = const AuditLogFilters(),
    this.page = 1,
    this.limit = 50,
  });

  AuditLogsState copyWith({
    List<AuditLog>? logs,
    int? total,
    bool? isLoading,
    String? error,
    AuditLogFilters? filters,
    int? page,
    int? limit,
  }) {
    return AuditLogsState(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Provider
final auditLogsProvider =
    StateNotifierProvider<AuditLogsNotifier, AuditLogsState>((ref) {
  return AuditLogsNotifier(ref.read(apiClientProvider));
});

class AuditLogsNotifier extends StateNotifier<AuditLogsState> {
  final ApiClient _apiClient;

  AuditLogsNotifier(this._apiClient) : super(const AuditLogsState());

  Future<void> loadLogs({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, logs: []);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final Map<String, dynamic> queryParams = {
        'page': state.page,
        'limit': state.limit,
      };

      if (state.filters.module != null) queryParams['module'] = state.filters.module;
      if (state.filters.adminId != null) queryParams['adminId'] = state.filters.adminId;
      // Add date filters if backend supports

      final response = await _apiClient.get('/admin/audit-logs', queryParameters: queryParams);

      final data = response.data;
      final List<dynamic> items = data['items'] ?? [];
      final int total = data['meta']?['totalItems'] ?? items.length;

      final newLogs = items.map((json) => AuditLog.fromJson(json)).toList();

      state = state.copyWith(
        logs: refresh ? newLogs : [...state.logs, ...newLogs],
        total: total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setModuleFilter(String? module) {
    state = state.copyWith(
      filters: state.filters.copyWith(module: module),
      page: 1,
    );
    loadLogs(refresh: true);
  }

  void setAdminFilter(String? adminId) {
    state = state.copyWith(
      filters: state.filters.copyWith(adminId: adminId),
      page: 1,
    );
    loadLogs(refresh: true);
  }
}
