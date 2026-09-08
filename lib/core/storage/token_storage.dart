import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = "token";

  static const String _emailKey = "email";

  static const String _nameKey = "name";

  static const String _empresaIdKey = "empresa_id";

  static const String _empresaNombreKey = "empresa_nombre";

  static const String _rememberKey = "remember";

  static const String _biometricKey = "biometric_enabled";

  // ==========================
  // SESIÓN
  // ==========================

  Future<void> saveSession(
    String token,
    String email,
    String name,
    String empresaId,
    String empresaNombre,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);

    await prefs.setString(_emailKey, email);

    await prefs.setString(_nameKey, name);

    await prefs.setString(_empresaIdKey, empresaId);

    await prefs.setString(_empresaNombreKey, empresaNombre);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_emailKey);
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_nameKey);
  }

  Future<String?> getEmpresaId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_empresaIdKey);
  }

  Future<String?> getEmpresaNombre() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_empresaNombreKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();

    return token != null;
  }

  // ==========================
  // RECORDAR USUARIO
  // ==========================

  Future<void> saveRemember(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberKey, value);
  }

  Future<bool> getRemember() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_rememberKey) ?? false;
  }

  // ==========================
  // BIOMETRÍA
  // ==========================

  Future<void> saveBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_biometricKey, value);
  }

  Future<bool> getBiometric() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_biometricKey) ?? false;
  }

  // ==========================
  // CERRAR SESIÓN
  // ==========================

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
  }
}
