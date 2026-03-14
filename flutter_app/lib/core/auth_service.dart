import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../services/logo_cache_service.dart';
import '../services/qr_cache_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _user;
  static Map<String, dynamic>? _tenant;

  static Future<void> init() async {
    _accessToken = await _storage.read(key: 'accessToken');
    _refreshToken = await _storage.read(key: 'refreshToken');
    
    final userStr = await _storage.read(key: 'user');
    final tenantStr = await _storage.read(key: 'tenant');
    
    if (userStr != null) {
      _user = jsonDecode(userStr);
    }
    
    if (tenantStr != null) {
      _tenant = jsonDecode(tenantStr);
    }
    
    if (_accessToken != null) {
      ApiClient.setAuthToken(_accessToken!);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $identifier');
      print('📡 API Base URL: ${ApiClient.dio.options.baseUrl}');
      
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      print('✅ Login successful');
      
      _accessToken = response.data['accessToken'];
      _refreshToken = response.data['refreshToken'];
      _user = response.data['user'];
      _tenant = response.data['tenant'];

      // Save to secure storage
      await _storage.write(key: 'accessToken', value: _accessToken);
      await _storage.write(key: 'refreshToken', value: _refreshToken);
      await _storage.write(key: 'user', value: jsonEncode(_user));
      await _storage.write(key: 'tenant', value: jsonEncode(_tenant));

      // Set token in API client
      ApiClient.setAuthToken(_accessToken!);

      // Cache logo and UPI QR locally in background (non-blocking)
      LogoCacheService.cacheLogoFromTenant(_tenant);
      QrCacheService.cacheQrFromTenant(_tenant);

      return {
        'success': true,
        'user': _user,
        'tenant': _tenant,
      };
    } on DioException catch (e) {
      print('❌ Login error: ${e.message}');
      print('Error type: ${e.type}');
      if (e.response != null) {
        print('Response: ${e.response?.data}');
      }
      
      String errorMessage = 'Login failed';
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Cannot connect to server.\n\nAPI: ${ApiClient.dio.options.baseUrl}\nError: ${e.message}';
      } else if (e.response?.data != null && e.response?.data['error'] != null) {
        errorMessage = e.response!.data['error'];
      } else if (e.response != null) {
        errorMessage = 'Server error: ${e.response?.statusCode}\n${e.response?.data}';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {
        'success': false,
        'error': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await ApiClient.dio.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      _accessToken = response.data['accessToken'];
      await _storage.write(key: 'accessToken', value: _accessToken);
      ApiClient.setAuthToken(_accessToken!);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _tenant = null;

    await _storage.deleteAll();
    ApiClient.clearAuthToken();
    LogoCacheService.clearCache();
    QrCacheService.clearCache();
  }

  static Map<String, dynamic>? getCurrentUser() => _user;
  
  static Map<String, dynamic>? getCurrentTenant() => _tenant;
  
  static bool isLoggedIn() => _accessToken != null;
  
  static bool isAdmin() => _user?['role'] == 'ADMIN';

  static Future<void> refreshTenant() async {
    try {
      final response = await ApiClient.dio.get('/tenant/self');
      _tenant = response.data;
      await _storage.write(key: 'tenant', value: jsonEncode(_tenant));
      // Re-cache logo and QR if admin changed them
      LogoCacheService.cacheLogoFromTenant(_tenant);
      QrCacheService.cacheQrFromTenant(_tenant);
    } catch (e) {
      print('Error refreshing tenant: $e');
    }
  }
}
