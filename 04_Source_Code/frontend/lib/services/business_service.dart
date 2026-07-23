import 'package:dio/dio.dart';
import 'api_service.dart';

class BusinessService {
  final ApiService _apiService;

  BusinessService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> applyBusinessAccount({
    required String businessName,
    required String businessRegistrationNumber,
    required String representativeName,
    required String phone,
    String? requestedStoreId,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/business/applications',
        data: {
          'business_name': businessName,
          'business_registration_number': businessRegistrationNumber,
          'representative_name': representativeName,
          'phone': phone,
          'requested_store_id': requestedStoreId,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? '사업자 신청에 실패했습니다.';
      throw Exception(msg.toString());
    }
  }

  Future<Map<String, dynamic>?> getMyApplication() async {
    try {
      final response = await _apiService.dio.get('/business/applications/me');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (_) {
      return null;
    }
  }
}
