import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class FileUploadService {
  final ApiClient _apiClient;

  FileUploadService(this._apiClient);

  /// Upload a single image file
  /// Returns the full public URL of the uploaded image
  Future<String> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        '/uploads/single',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Backend returns { originalname, filename, path, ... }
      // Path is relative like /uploads/xyz.jpg
      String relativePath = response.data['path'];
      
      // Prepend base URL to make it a full URL
      return '${ApiEndpoints.baseUrl}$relativePath';
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload image');
    }
  }
}
