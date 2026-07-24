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
      if (e.response?.statusCode == 404) {
        throw Exception('신청 경로를 확인하지 못했습니다. 앱을 최신 버전으로 업데이트한 후 다시 시도해 주세요.');
      }
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      if (msg != null && msg.toString().isNotEmpty) {
        final errStr = msg.toString();
        if (errStr.toLowerCase().contains('not found') ||
            errStr.contains('404')) {
          throw Exception('신청 경로를 확인하지 못했습니다. 앱을 최신 버전으로 업데이트한 후 다시 시도해 주세요.');
        }
        throw Exception(errStr);
      }
      throw Exception('신청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    } catch (_) {
      throw Exception('신청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.');
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

  Future<Map<String, dynamic>> getManagedStore() async {
    try {
      final response = await _apiService.dio.get('/business/store/me');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '매장 정보를 불러오지 못했습니다.');
    }
  }

  Future<Map<String, dynamic>> updateManagedStore(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.dio.patch(
        '/business/store/me',
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '매장 정보 수정에 실패했습니다.');
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({String? storeId}) async {
    try {
      final response = await _apiService.dio.get(
        '/business/products',
        queryParameters: {if (storeId != null) 'store_id': storeId},
      );
      final list = response.data as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '상품 목록을 불러오지 못했습니다.');
    }
  }

  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> data, {
    String? storeId,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/business/products',
        data: data,
        queryParameters: {if (storeId != null) 'store_id': storeId},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '상품 등록에 실패했습니다.');
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.dio.patch(
        '/business/products/$productId',
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '상품 수정에 실패했습니다.');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _apiService.dio.delete('/business/products/$productId');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '상품 중지에 실패했습니다.');
    }
  }

  Future<Map<String, dynamic>> getReviews({
    String? storeId,
    bool photoOnly = false,
    String sort = 'latest',
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/business/reviews',
        queryParameters: {
          if (storeId != null) 'store_id': storeId,
          'photo_only': photoOnly,
          'sort': sort,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '리뷰 목록을 불러오지 못했습니다.');
    }
  }
}
