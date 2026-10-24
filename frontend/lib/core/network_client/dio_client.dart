import 'package:dio/dio.dart';

/// Network client wrapper configuring Dio for backend or mock API calls.
class DioClient {
  late final Dio dio;

  DioClient({String baseUrl = 'https://api.foodcosting.example.com/v1'}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }
}
