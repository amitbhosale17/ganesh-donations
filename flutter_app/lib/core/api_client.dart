import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

class ApiClient {
  static final _storage = const FlutterSecureStorage();
  static bool _isRefreshing = false;
  
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://ganesh-donations-api.onrender.com',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          developer.log('🌐 ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log('✅ ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          developer.log('❌ Error: ${error.message}', error: error);
          
          // Handle 401 errors - token expired
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            
            try {
              // Get refresh token
              final refreshToken = await _storage.read(key: 'refreshToken');
              
              if (refreshToken != null) {
                developer.log('🔄 Refreshing token...');
                
                // Request new tokens
                final response = await Dio().post(
                  '${dio.options.baseUrl}/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );
                
                if (response.statusCode == 200) {
                  final newAccessToken = response.data['accessToken'];
                  final newRefreshToken = response.data['refreshToken'];
                  
                  // Save new tokens
                  await _storage.write(key: 'accessToken', value: newAccessToken);
                  await _storage.write(key: 'refreshToken', value: newRefreshToken);
                  
                  // Update authorization header
                  setAuthToken(newAccessToken);
                  
                  developer.log('✅ Token refreshed successfully');
                  
                  // Retry the original request
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(error.requestOptions);
                  _isRefreshing = false;
                  return handler.resolve(retryResponse);
                }
              }
            } catch (e) {
              developer.log('❌ Token refresh failed: $e');
              _isRefreshing = false;
              
              // Clear tokens and redirect to login
              await _storage.delete(key: 'accessToken');
              await _storage.delete(key: 'refreshToken');
              clearAuthToken();
            }
            
            _isRefreshing = false;
          }
          
          return handler.next(error);
        },
      ),
    );

  static void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}
