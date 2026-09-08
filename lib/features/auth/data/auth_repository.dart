import '../model/login_request.dart';
import '../model/login_response.dart';

import 'auth_api.dart';

class AuthRepository {
  final AuthApi api;

  AuthRepository(this.api);

  Future<LoginResponse> login(String email, String password) {
    return api.login(LoginRequest(email: email, password: password));
  }
}
