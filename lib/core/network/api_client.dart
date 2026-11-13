import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'api_constants.dart';

class ApiClient {
  final TokenStorage storage;
  late Dio dio;

  ApiClient({required this.storage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
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
          if (error.response?.statusCode == 401 && error.requestOptions.path != '/auth/login' && error.requestOptions.headers['Authorization'] == 'Bearer ${await storage.getToken()}') {
            debugPrint("SESIÓN EXPIRADA (401) -> Cerrando sesión local");
            await storage.logout(revoke: false);
          }
          handler.next(error);
        },
      ),
    );

    // ============================================================
    // LOG DE DIO (Solo activo en modo debug para evitar lag)
    // ============================================================
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (object) {
            debugPrint("[HTTP] $object");
          },
        ),
      );
    }
  }

  Dio get client => dio;
}
