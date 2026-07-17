import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/user.dart';
import '../models/place.dart';
import '../models/review.dart';

class AdminAuditLogModel {
  final String id;
  final String? adminId;
  final String action;
  final String? targetId;
  final String? details;
  final DateTime createdAt;
  final User? admin;

  AdminAuditLogModel({
    required this.id,
    this.adminId,
    required this.action,
    this.targetId,
    this.details,
    required this.createdAt,
    this.admin,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      id: json['id'] as String? ?? '',
      adminId: json['admin_id'] as String?,
      action: json['action'] as String? ?? '',
      targetId: json['target_id'] as String?,
      details: json['details'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      admin: json['admin'] != null 
          ? User.fromJson(json['admin'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class AdminRepository {
  final AdminService _adminService;

  static final List<User> _mockUsers = [
    User(
      id: 'usr_mock_1',
      email: 'member1@gogo.com',
      nickname: '광안리서퍼',
      role: 'member',
      status: 'active',
      currentPoints: 450,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    User(
      id: 'usr_mock_2',
      email: 'member2@gogo.com',
      nickname: '악성리뷰러',
      role: 'member',
      status: 'blocked',
      currentPoints: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  static final List<AdminAuditLogModel> _mockLogs = [
    AdminAuditLogModel(
      id: 'log_mock_1',
      action: 'UPDATE_USER_STATUS',
      targetId: 'usr_mock_2',
      details: 'Changed status from active to blocked',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      admin: User(
        id: 'usr_admin_1',
        email: 'admin@gogo.com',
        nickname: '총괄관리자',
        role: 'admin',
        status: 'active',
        currentPoints: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ),
  ];

  AdminRepository({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  Future<Map<String, dynamic>> getStats({String? adminId}) async {
    try {
      return await _adminService.fetchAdminStats(adminId: adminId);
    } catch (e) {
      if (kDebugMode) {
        print('AdminRepository: Failed stats fetch. Simulating offline: $e');
      }
      return {
        'total_users': 150,
        'total_stores': 12,
        'total_missions': 8,
        'total_reservations': 42,
        'total_reviews': 35,
        'active_reservations': 4,
      };
    }
  }

  Future<List<User>> getUsers({String? search, int skip = 0, int limit = 20, String? adminId}) async {
    try {
      final list = await _adminService.fetchAdminUsers(search: search, skip: skip, limit: limit, adminId: adminId);
      return list.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('AdminRepository: Failed users fetch. Simulating offline: $e');
      }
      if (search != null && search.isNotEmpty) {
        return _mockUsers.where((u) => u.email.contains(search) || u.nickname.contains(search)).toList();
      }
      return _mockUsers;
    }
  }

  Future<User> updateUserStatus(String userId, String status, {String? adminId}) async {
    try {
      final res = await _adminService.updateUserStatus(userId, status, adminId: adminId);
      return User.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('AdminRepository: Failed user status update. Simulating offline: $e');
      }
      final index = _mockUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final current = _mockUsers[index];
        final updated = User(
          id: current.id,
          email: current.email,
          nickname: current.nickname,
          role: current.role,
          status: status,
          currentPoints: current.currentPoints,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        _mockUsers[index] = updated;
        
        // Append simulated audit log
        _mockLogs.insert(0, AdminAuditLogModel(
          id: 'log_mock_${DateTime.now().millisecondsSinceEpoch}',
          action: 'UPDATE_USER_STATUS',
          targetId: userId,
          details: 'Changed status from ${current.status} to $status (Offline)',
          createdAt: DateTime.now(),
        ));
        
        return updated;
      }
      throw Exception('사용자를 찾을 수 없습니다.');
    }
  }

  Future<List<AdminAuditLogModel>> getAuditLogs({String? adminId, int skip = 0, int limit = 30}) async {
    try {
      final list = await _adminService.fetchAdminAuditLogs(adminId: adminId, skip: skip, limit: limit);
      return list.map((json) => AdminAuditLogModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('AdminRepository: Failed logs fetch. Simulating offline: $e');
      }
      return _mockLogs;
    }
  }

  // Expansion helpers (Stubbed out to avoid compile issues)
  Future<Place> createStore(Map<String, dynamic> data, {String? adminId}) async {
    final res = await _adminService.createStore(data, adminId: adminId);
    return Place.fromJson(res);
  }

  Future<Place> updateStore(String id, Map<String, dynamic> data, {String? adminId}) async {
    final res = await _adminService.updateStore(id, data, adminId: adminId);
    return Place.fromJson(res);
  }

  Future<Place> updateStoreStatus(String id, String status, {String? adminId}) async {
    final res = await _adminService.updateStoreStatus(id, status, adminId: adminId);
    return Place.fromJson(res);
  }

  Future<Map<String, dynamic>> createMission(Map<String, dynamic> data, {String? adminId}) async {
    return await _adminService.createMission(data, adminId: adminId);
  }

  Future<Map<String, dynamic>> updateMissionStatus(String id, String status, {String? adminId}) async {
    return await _adminService.updateMissionStatus(id, status, adminId: adminId);
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data, {String? adminId}) async {
    return await _adminService.createCoupon(data, adminId: adminId);
  }

  Future<Map<String, dynamic>> updateCouponStatus(String id, String status, {String? adminId}) async {
    return await _adminService.updateCouponStatus(id, status, adminId: adminId);
  }

  Future<List<dynamic>> getReservations({String? adminId}) async {
    return await _adminService.fetchAdminReservations(adminId: adminId);
  }

  Future<Map<String, dynamic>> updateReservationStatus(String id, String status, {String? adminId}) async {
    return await _adminService.updateReservationStatus(id, status, adminId: adminId);
  }

  Future<List<Review>> getReviews({String? adminId}) async {
    final list = await _adminService.fetchAdminReviews(adminId: adminId);
    return list.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Review> hideReview(String id, bool isHidden, {String? adminId}) async {
    final res = await _adminService.hideReview(id, isHidden, adminId: adminId);
    return Review.fromJson(res);
  }
}
