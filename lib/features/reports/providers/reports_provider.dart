import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sales_report.dart';
import '../repositories/reports_repository.dart';
// import 'package:file_saver/file_saver.dart'; // Web/Desktop file saving? Need cross platform solution
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'package:open_file/open_file.dart'; // For opening file on mobile
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

// State for the reports screen
class ReportsState {
  final bool isLoading;
  final String? error;
  final SalesReportResponse? report;
  final ReportFilters filters;

  ReportsState({
    this.isLoading = false,
    this.error,
    this.report,
    required this.filters,
  });

  ReportsState copyWith({
    bool? isLoading,
    String? error,
    SalesReportResponse? report,
    ReportFilters? filters,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullify error on new state unless explicitly passed
      report: report ?? this.report,
      filters: filters ?? this.filters,
    );
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final repository = ref.read(reportsRepositoryProvider);
  return ReportsNotifier(repository);
});

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository _repository;

  ReportsNotifier(this._repository) : super(ReportsState(filters: ReportFilters()));

  Future<void> loadReports({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _repository.getSalesReports(state.filters);
      state = state.copyWith(isLoading: false, report: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilters(ReportFilters newFilters) {
    state = state.copyWith(filters: newFilters);
    loadReports(refresh: true);
  }

  void updateDateRange(DateTimeRange? range) {
    if (range == null) {
      // Explicitly clear dates using sentinel (null-safe copyWith)
      final cleared = ReportFilters(
        startDate: null,
        endDate: null,
        userType: state.filters.userType,
        search: state.filters.search,
        dealerId: state.filters.dealerId,
        userId: state.filters.userId,
        page: 1,
        limit: state.filters.limit,
      );
      state = state.copyWith(filters: cleared);
      loadReports(refresh: true);
      return;
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    setFilters(state.filters.copyWith(
      startDate: dateFormat.format(range.start),
      endDate: dateFormat.format(range.end),
      page: 1,
    ));
  }

  void setUserType(String? type) {
    setFilters(state.filters.copyWith(userType: type, page: 1));
  }
  
  void setSearch(String? search) {
    setFilters(state.filters.copyWith(search: search, page: 1));
  }

  void setPage(int page) {
    setFilters(state.filters.copyWith(page: page));
  }
  
  void setSpecificUser(String? userId) {
      setFilters(state.filters.copyWith(userId: userId, page: 1));
  }

  Future<void> exportReport() async {
    try {
      final bytes = await _repository.exportSalesReports(state.filters);
      final fileName = 'Sales_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      
      if (kIsWeb) {
        // Implement Web download (using universal_html or dart:html logic, omitted for brevity as mainly mobile app)
        // Or trigger backend link directly via url_launcher? No, need auth headers.
        // For now, let's just log or use a simple anchor.
        debugPrint('Web download not fully implemented in this snippet.');
      } else {
        // Mobile/Desktop: use FilePicker so user chooses location
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Report As',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(bytes), // Required for Web/Android/iOS natively
        );

        if (outputFile != null) {
          if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
            final file = File(outputFile);
            await file.writeAsBytes(bytes);
          }
        } else {
          throw Exception('Cancelled');
        }
      }
    } catch (e) {
      // Do not set state.error here, as it replaces the entire screen UI
      // Let the widget layer handle the error with a Snackbar.
      if (e.toString().contains('Cancelled')) {
        throw Exception('Cancelled');
      }
      throw Exception('Export Failed: $e');
    }
  }
}
