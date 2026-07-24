import 'package:dio/dio.dart';
import 'api_service.dart';

class AdminBusinessService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _apiService.dio.get(
        '/admin/business/application-summary',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception('관리자 요약 통계를 불러오지 못했습니다.');
    }
  }

  Future<List<Map<String, dynamic>>> getApplications({
    String? status,
    String? q,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'ALL') {
        queryParams['status'] = status;
      }
      if (q != null && q.trim().isNotEmpty) {
        queryParams['q'] = q.trim();
      }

      final response = await _apiService.dio.get(
        '/admin/business/applications',
        queryParameters: queryParams,
      );
      final list = response.data as List;
      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      throw Exception('사업자 신청 목록을 불러오지 못했습니다.');
    }
  }

  Future<Map<String, dynamic>> getApplicationDetail(String id) async {
    try {
      final response = await _apiService.dio.get(
        '/admin/business/applications/$id',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception('사업자 신청 상세 정보를 불러오지 못했습니다.');
    }
  }

  Future<Map<String, dynamic>> approveApplication(String id) async {
    try {
      final response = await _apiService.dio.post(
        '/admin/business/applications/$id/approve',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      if (msg != null && msg.toString().isNotEmpty) {
        throw Exception(msg.toString());
      }
      throw Exception('승인 처리를 완료하지 못했습니다.');
    } catch (e) {
      throw Exception('승인 처리를 완료하지 못했습니다.');
    }
  }

  Future<Map<String, dynamic>> rejectApplication(
    String id,
    String reason,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/admin/business/applications/$id/reject',
        data: {'rejection_reason': reason},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      if (msg != null && msg.toString().isNotEmpty) {
        throw Exception(msg.toString());
      }
      throw Exception('거절 처리를 완료하지 못했습니다.');
    } catch (e) {
      throw Exception('거절 처리를 완료하지 못했습니다.');
    }
  }
}
