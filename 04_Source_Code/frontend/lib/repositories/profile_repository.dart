import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class ProfileRepository {
  final Dio _dio;
  final AuthService _authService;

  ProfileRepository({Dio? dio, AuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)),
        _authService = authService ?? AuthService();

  Future<Options> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // GET /users/me
  Future<User> getMe() async {
    try {
      final opts = await _getHeaders();
      final res = await _dio.get('/users/me', options: opts);
      return User.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('ProfileRepository: getMe failed, return cached. Error: $e');
      }
      rethrow;
    }
  }

  // PATCH /users/me (Update nickname)
  Future<User> updateNickname(String nickname) async {
    try {
      final opts = await _getHeaders();
      final res = await _dio.patch(
        '/users/me',
        data: {'nickname': nickname},
        options: opts,
      );
      return User.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('ProfileRepository: updateNickname failed. Error: $e');
      }
      rethrow;
    }
  }

  // POST /users/me/profile-image
  Future<String> uploadProfileImage(File file) async {
    try {
      final opts = await _getHeaders();
      final fileName = file.path.split('/').last;
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);

      final res = await _dio.post(
        '/users/me/profile-image',
        data: {
          'filename': fileName,
          'base64_data': base64Data,
        },
        options: opts,
      );
      return res.data['profile_image_url'] as String;
    } catch (e) {
      if (kDebugMode) {
        print('ProfileRepository: uploadProfileImage failed. Error: $e');
      }
      rethrow;
    }
  }

  // DELETE /users/me/profile-image
  Future<User> removeProfileImage() async {
    try {
      final opts = await _getHeaders();
      final res = await _dio.delete('/users/me/profile-image', options: opts);
      return User.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('ProfileRepository: removeProfileImage failed. Error: $e');
      }
      rethrow;
    }
  }

  // POST /auth/change-password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final opts = await _getHeaders();
      await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: opts,
      );
    } catch (e) {
      if (kDebugMode) {
        print('ProfileRepository: changePassword failed. Error: $e');
      }
      rethrow;
    }
  }

  // DELETE /users/me (Withdrawal)
  Future<void> withdrawAccount() async {
    try {
      final opts = await _getHeaders();
      await _dio.delete('/users/me', options: opts);
    } catch (e) {
      if (kDebugMode) {
        print('ProfileRepository: withdrawAccount failed. Error: $e');
      }
      rethrow;
    }
  }
}
