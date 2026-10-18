import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = "token";

  static const String _usuarioIdKey = "usuario_id";

  static const String _emailKey = "email";

  static const String _nameKey = "name";

  static const String _empresaIdKey = "empresa_id";

  static const String _empresaNombreKey = "empresa_nombre";

  static const String _sucursalIdKey = "sucursal_id";

  static const String _sucursalNombreKey = "sucursal_nombre";

  static const String _rememberKey = "remember";

  static const String _biometricKey = "biometric_enabled";

  // ============================================================
  // GUARDAR SESIÓN COMPLETA
  // ============================================================

  Future<void> saveSession(
    String token,
    String usuarioId,
    String email,
    String name,
    String empresaId,
    String empresaNombre,
    String? sucursalId,
    String? sucursalNombre,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);

    await prefs.setString(_usuarioIdKey, usuarioId);

    await prefs.setString(_emailKey, email);

    await prefs.setString(_nameKey, name);

    await prefs.setString(_empresaIdKey, empresaId);

    await prefs.setString(_empresaNombreKey, empresaNombre);

    if (sucursalId != null) {
      await prefs.setString(_sucursalIdKey, sucursalId);
    }

    if (sucursalNombre != null) {
      await prefs.setString(_sucursalNombreKey, sucursalNombre);
    }
  }

  Future<String?> getUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_usuarioIdKey);
  }

  Future<String?> getSucursalId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_sucursalIdKey);
  }

  Future<String?> getSucursalNombre() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_sucursalNombreKey);
  }

  // ============================================================
  // GETTERS
  // ============================================================

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

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // RECORDAR USUARIO
  // ============================================================

  Future<void> saveRemember(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberKey, value);
  }

  Future<bool> getRemember() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_rememberKey) ?? false;
  }

  // ============================================================
  // BIOMETRÍA
  // ============================================================

  Future<void> saveBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_biometricKey, value);
  }

  Future<bool> getBiometric() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_biometricKey) ?? false;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);

    await prefs.remove(_usuarioIdKey);

    await prefs.remove(_empresaIdKey);

    await prefs.remove(_empresaNombreKey);

    await prefs.remove(_sucursalIdKey);

    await prefs.remove(_sucursalNombreKey);
  }
}
