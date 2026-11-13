import 'package:biometric_signature/biometric_signature.dart';
import 'biometric_credentials.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return (await BiometricSignature().biometricAuthAvailable()).canAuthenticate == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> enroll() async {
    final api=ApiClient(storage:TokenStorage());
    try { await BiometricCredentials().enroll(api); return true; } catch (_) { return false; } finally { api.dio.close(); }
  }
  Future<void> disable() async {
    final api=ApiClient(storage:TokenStorage());
    try { await BiometricCredentials().disable(api); } finally { api.dio.close(); }
  }

  Future<bool> authenticate() async {
    try {
      final result = await auth.authenticate(
        localizedReason: "Usa tu huella para ingresar a FERSAL",

        options: const AuthenticationOptions(
          biometricOnly: true,

          stickyAuth: true,
        ),
      );

      return result;
    } catch (e) {
      return false;
    }
  }
}
