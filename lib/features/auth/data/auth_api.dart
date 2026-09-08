import '../../../core/network/api_client.dart';

import '../model/login_request.dart';
import '../model/login_response.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi(this.apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await apiClient.client.post(
      "/auth/login",

      data: request.toJson(),
    );

    return LoginResponse.fromJson(response.data);
  }

  Future<LoginResponse> biometricLogin(String email) async {
    final response = await apiClient.client.post(
      "/auth/biometric",

      data: {"email": email},
    );

    return LoginResponse.fromJson(response.data);
  }
}
