import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/file_upload_service.dart';
import 'auth_provider.dart';

// Provider for FileUploadService
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FileUploadService(apiClient);
});
