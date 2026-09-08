import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await auth.canCheckBiometrics;

      final supported = await auth.isDeviceSupported();

      await auth.getAvailableBiometrics();

      return canCheck && supported;
    } catch (e) {
      return false;
    }
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
