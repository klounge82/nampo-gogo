import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/user.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../config/production_config.dart';

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
          ? User.fromJson(Map<String, dynamic>.from(json['admin'] as Map))
          : null,
    );
  }
}

class AdminRepository {
  final AdminService _adminService = AdminService();

  static final List<User> _mockUsers = [
    User(
      id: 'usr_admin_001',
      email: 'admin@nampogogo.com',
      nickname: '총관리자',
      role: 'admin',
      roles: ['CUSTOMER', 'ADMIN'],
      status: 'ACTIVE',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    User(
      id: 'usr_owner_001',
      email: 'owner1@nampogogo.com',
      nickname: '용두산갈비 사장님',
      role: 'owner',
      roles: ['CUSTOMER', 'OWNER'],
      status: 'ACTIVE',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ),
  ];

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

  Future<List<User>> getUsers({
    String? search,
    int skip = 0,
    int limit = 20,
    String? adminId,
  }) async {
    debugPrint('NAMPO_ADMIN_USERS_DIAG stage=REPOSITORY_ENTER');
    try {
      final list = await _adminService.fetchAdminUsers(
        search: search,
        skip: skip,
        limit: limit,
        adminId: adminId,
      );
      debugPrint('NAMPO_ADMIN_USERS_DIAG stage=REPOSITORY_INPUT runtimeType=${list.runtimeType} count=${list.length}');
      final result = <User>[];
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        debugPrint('NAMPO_ADMIN_USERS_DIAG stage=USER_PARSE_BEGIN index=$i rawType=${item.runtimeType}');
        if (item is Map) {
          final normalized = Map<String, dynamic>.from(item);
          debugPrint('NAMPO_ADMIN_USERS_DIAG stage=MAP_NORMALIZED index=$i mapType=${normalized.runtimeType}');
          final user = User.fromJson(normalized);
          debugPrint('NAMPO_ADMIN_USERS_DIAG stage=USER_PARSE_PASS index=$i id=${user.id}');
          result.add(user);
        } else {
          debugPrint('NAMPO_ADMIN_USERS_DIAG stage=USER_PARSE_ERROR index=$i itemIsNotMap rawType=${item.runtimeType}');
          final user = User.fromJson(item as Map<String, dynamic>);
          result.add(user);
        }
      }
      return result;
    } catch (e, st) {
      debugPrint('NAMPO_ADMIN_USERS_DIAG stage=REPOSITORY_ERROR exceptionType=${e.runtimeType}\n$st');
      if (ProductionConfig.enableMockData) {
        if (search != null && search.isNotEmpty) {
          return _mockUsers
              .where(
                (u) => u.email.contains(search) || u.nickname.contains(search),
              )
              .toList();
        }
        return _mockUsers;
      }
      rethrow;
    }
  }

  Future<User> updateUserStatus(
    String userId,
    String status, {
    String? adminId,
  }) async {
    try {
      final res = await _adminService.updateUserStatus(
        userId,
        status,
        adminId: adminId,
      );
      return User.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print(
          'AdminRepository: Failed user status update. Simulating offline: $e',
        );
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
        _mockLogs.insert(
          0,
          AdminAuditLogModel(
            id: 'log_mock_${DateTime.now().millisecondsSinceEpoch}',
            action: 'UPDATE_USER_STATUS',
            targetId: userId,
            details:
                'Changed status from ${current.status} to $status (Offline)',
            createdAt: DateTime.now(),
          ),
        );

        return updated;
      }
      throw Exception('사용자를 찾을 수 없습니다.');
    }
  }

  Future<List<AdminAuditLogModel>> getAuditLogs({
    String? adminId,
    int skip = 0,
    int limit = 30,
  }) async {
    try {
      final list = await _adminService.fetchAdminAuditLogs(
        adminId: adminId,
        skip: skip,
        limit: limit,
      );
      return list
          .map(
            (json) => AdminAuditLogModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('AdminRepository: Failed logs fetch. Simulating offline: $e');
      }
      return _mockLogs;
    }
  }

  // Expansion helpers (Stubbed out to avoid compile issues)
  Future<Place> createStore(
    Map<String, dynamic> data, {
    String? adminId,
  }) async {
    final res = await _adminService.createStore(data, adminId: adminId);
    return Place.fromJson(res);
  }

  Future<Place> updateStore(
    String id,
    Map<String, dynamic> data, {
    String? adminId,
  }) async {
    final res = await _adminService.updateStore(id, data, adminId: adminId);
    return Place.fromJson(res);
  }

  Future<Place> updateStoreStatus(
    String id,
    String status, {
    String? adminId,
  }) async {
    final res = await _adminService.updateStoreStatus(
      id,
      status,
      adminId: adminId,
    );
    return Place.fromJson(res);
  }

  Future<Place> updateStoreSpatialGeometry(
    String id, {
    required String geometryType,
    String? geometryData,
    int? reviewLocationRadiusM,
    String? adminId,
  }) async {
    final res = await _adminService.updateStoreSpatialGeometry(
      id,
      geometryType: geometryType,
      geometryData: geometryData,
      reviewLocationRadiusM: reviewLocationRadiusM,
      adminId: adminId,
    );
    return Place.fromJson(res);
  }

  Future<Map<String, dynamic>> createMission(
    Map<String, dynamic> data, {
    String? adminId,
  }) async {
    return await _adminService.createMission(data, adminId: adminId);
  }

  Future<Map<String, dynamic>> updateMissionStatus(
    String id,
    String status, {
    String? adminId,
  }) async {
    return await _adminService.updateMissionStatus(
      id,
      status,
      adminId: adminId,
    );
  }

  Future<Map<String, dynamic>> createCoupon(
    Map<String, dynamic> data, {
    String? adminId,
  }) async {
    return await _adminService.createCoupon(data, adminId: adminId);
  }

  Future<Map<String, dynamic>> updateCouponStatus(
    String id,
    String status, {
    String? adminId,
  }) async {
    return await _adminService.updateCouponStatus(id, status, adminId: adminId);
  }

  Future<List<dynamic>> getReservations({String? adminId}) async {
    return await _adminService.fetchAdminReservations(adminId: adminId);
  }

  Future<Map<String, dynamic>> updateReservationStatus(
    String id,
    String status, {
    String? adminId,
  }) async {
    return await _adminService.updateReservationStatus(
      id,
      status,
      adminId: adminId,
    );
  }

  Future<List<Review>> getReviews({String? adminId}) async {
    final list = await _adminService.fetchAdminReviews(adminId: adminId);
    return list
        .map((json) => Review.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Review> hideReview(String id, bool isHidden, {String? adminId}) async {
    final res = await _adminService.hideReview(id, isHidden, adminId: adminId);
    return Review.fromJson(res);
  }

  Future<Map<String, dynamic>> resetQaUserBaseline(
    String userId, {
    String? adminId,
  }) async {
    return await _adminService.resetQaUserBaseline(userId, adminId: adminId);
  }
}
