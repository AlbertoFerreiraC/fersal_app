import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_constants.dart';

class ApiClient {
  final TokenStorage storage;

  late Dio dio;

  ApiClient({required this.storage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {"Content-Type": "application/json"},
      ),
    );

    // ============================================================
    // INTERCEPTOR DE AUTENTICACIÓN
    // ============================================================

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await storage.logout();
          }

          handler.next(error);
        },
      ),
    );

    // ============================================================
    // LOG DE DIO
    // ============================================================

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) {
          print(object);
        },
      ),
    );
  }

  Dio get client => dio;
}
