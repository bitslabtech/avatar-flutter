/// Handles authentication, error handling, and request/response transformation
import 'dart:async';
import 'package:dio/dio.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add interceptors for auth and error handling
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_TokenRefreshInterceptor(_dio)); // Add Refresh Logic
    _dio.interceptors.add(_ErrorInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }
  
  /// Get the Dio instance for making API calls
  Dio get dio => _dio;
  
  /// Set authentication token
  /// This updates the default headers with the Bearer token
  Future<void> setAuthToken(String? token) async {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }
  
  /// Clear authentication token
  Future<void> clearAuthToken() async {
    _dio.options.headers.remove('Authorization');
  }

  // Proxy methods for Dio
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}

/// Interceptor to automatically add JWT token to requests
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Get token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: AppConstants.accessTokenKey);
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
}

/// Interceptor to handle Token Refresh on 401
class _TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _failedRequests = [];

  _TokenRefreshInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // If refresh is already in progress, queue this request
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _failedRequests.add({
          'options': err.requestOptions,
          'completer': completer,
          'handler': handler,
        });
        return; // Don't pass to next error handler yet, wait for refresh
      }

      _isRefreshing = true;
      try {
        const storage = FlutterSecureStorage();
        final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);

        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err); // No refresh token, fail normal
        }

        // Create a new Dio instance to avoid interceptor loops
        final refreshDio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ));

        // Call refresh endpoint
        final response = await refreshDio.post(ApiEndpoints.refresh, data: {
          'refreshToken': refreshToken,
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Save new tokens
          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];
          
          await storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
          await storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);
          
          // Update current Dio instance defaults
          _dio.options.headers['Authorization'] = 'Bearer $newAccessToken';

          // Retry the original failed request
          // Clone request options with new header
           final options = err.requestOptions;
           options.headers['Authorization'] = 'Bearer $newAccessToken';
           
           final retryResponse = await _dio.fetch(options);
           handler.resolve(retryResponse);

           // Retry queued requests
           for (var req in _failedRequests) {
             final RequestOptions reqOptions = req['options'];
             final ErrorInterceptorHandler reqHandler = req['handler'];
             
             reqOptions.headers['Authorization'] = 'Bearer $newAccessToken';
             
             try {
               final res = await _dio.fetch(reqOptions);
               reqHandler.resolve(res);
             } catch (e) {
               if (e is DioException) {
                 reqHandler.next(e);
               } else {
                 reqHandler.next(DioException(requestOptions: reqOptions, error: e));
               }
             }
           }
           _failedRequests.clear();
           _isRefreshing = false;
        } else {
          // Refresh failed
          _processFailedRefresh(err, handler);
        }
      } catch (e) {
        // Refresh failed (network or invalid token)
         _processFailedRefresh(err, handler);
      }
    } else {
      handler.next(err);
    }
  }

  void _processFailedRefresh(DioException err, ErrorInterceptorHandler handler) async{
      _isRefreshing = false;
      _failedRequests.clear(); // Drop queued requests as they will fail too
      
      // Clear tokens
      const storage = FlutterSecureStorage();
      await storage.delete(key: AppConstants.accessTokenKey);
      await storage.delete(key: AppConstants.refreshTokenKey);
      
      return handler.next(err);
  }
}

/// Interceptor to handle errors globally
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Transform DioException to a more user-friendly format
    String message = 'An error occurred';
    
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          message = 'Session expired. Please login again.';
          // TokenInterceptor handles retry, if we get here it means refresh failed
        } else if (statusCode == 404) {
          message = err.response?.data['message'] ?? 'Resource not found.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = err.response?.data['message'] ?? 'An error occurred';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.unknown:
        message = 'No internet connection. Please check your network.';
        break;
      default:
        message = 'An unexpected error occurred.';
    }
    
    // Create a new error with user-friendly message
    final error = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message,
    );
    
    handler.next(error);
  }
}




