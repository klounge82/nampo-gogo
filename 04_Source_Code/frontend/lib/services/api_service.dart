import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  final Dio _dio;

  // Private constructor
  ApiService._(this._dio);

  // Singleton instance
  static ApiService? _instance;

  factory ApiService() {
    if (_instance == null) {
      final baseOptions = BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      final dio = Dio(baseOptions);
      
      // Add simple logging interceptor for debugging
      dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: true,
      ));

      _instance = ApiService._(dio);
    }
    return _instance!;
  }

  // GET / (Health Check status message)
  Future<String> fetchApiStatusMessage() async {
    try {
      final response = await _dio.get('/');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data['message'] ?? 'Nampo GoGo API is running (unknown message)';
        }
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/'),
        message: 'Invalid response format from server',
      );
    } catch (e) {
      // Re-throw to be handled by repository layer
      rethrow;
    }
  }

  Dio get dio => _dio;
}
