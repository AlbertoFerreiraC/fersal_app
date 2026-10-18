import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/storage/token_storage.dart';

import '../data/auth_api.dart';
import '../model/login_request.dart';

import '../../dashboard/presentation/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool remember = true;
  bool usuarioGuardado = false;
  bool obscurePassword = true;
  String nombreUsuario = "";

  final storage = TokenStorage();

  @override
  void initState() {
    super.initState();
    cargarSesion();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> cargarSesion() async {
    final recordar = await storage.getRemember();
    final email = await storage.getEmail();
    final nombre = await storage.getName();

    if (recordar && email != null && nombre != null) {
      setState(() {
        emailController.text = email;
        nombreUsuario = nombre;
        usuarioGuardado = true;
      });
    }
  }

  void cambiarUsuario() {
    setState(() {
      usuarioGuardado = false;
      emailController.clear();
      passwordController.clear();
      nombreUsuario = "";
      remember = false;
    });
  }

  Future<void> _vincularTokenFcm(ApiClient api, String usuarioId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await api.client.put(
          '/usuarios/$usuarioId/fcm-token',
          data: {'token': token},
        );
      }
    } catch (_) {
      // Manejo silencioso para no bloquear el ingreso en caso de fallo de red
    }
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa tu correo y contraseña"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final apiClient = ApiClient(storage: storage);
      final api = AuthApi(apiClient);

      final response = await api.login(
        LoginRequest(
          email: emailController.text.trim(),
          password: passwordController.text,
        ),
      );

      await storage.saveSession(
        response.token,
        response.usuarioId,
        response.email,
        response.name,
        response.empresaId,
        response.empresaNombre,
        response.sucursalId,
        response.sucursalNombre,
      );

      await storage.saveRemember(remember);

      // Sincroniza el token FCM usando directamente el usuarioId retornado por el backend
      await _vincularTokenFcm(apiClient, response.usuarioId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de inicio de sesión: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> validarBiometria() async {
    final activa = await storage.getBiometric();

    if (!activa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Acceso biométrico no activado en la app"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final service = BiometricService();
    final resultado = await service.authenticate();

    if (!resultado) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final email = await storage.getEmail();

      if (email == null) {
        throw Exception("No existe usuario guardado");
      }

      final apiClient = ApiClient(storage: storage);
      final api = AuthApi(apiClient);
      final response = await api.biometricLogin(email);

      await storage.saveSession(
        response.token,
        response.usuarioId,
        response.email,
        response.name,
        response.empresaId,
        response.empresaNombre,
        response.sucursalId,
        response.sucursalNombre,
      );

      // Sincroniza el token FCM usando el usuarioId obtenido en login biométrico
      await _vincularTokenFcm(apiClient, response.usuarioId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al ingresar con biometría"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E3A8A).withOpacity(0.5),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFF1B62D4),
                    const Color(0xFF246BFD).withOpacity(0.85),
                    const Color(0xFFF8FAFC),
                  ],
            stops: const [0.0, 0.45, 0.85],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: Image.asset(
                          'assets/images/logo_fersal.PNG',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF3B82F6),
                              size: 80,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "FERSAL",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "GESTIÓN INTELIGENTE",
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuarioGuardado
                              ? "¡Hola, $nombreUsuario!"
                              : "Iniciar sesión",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          usuarioGuardado
                              ? "Ingresá tu contraseña para acceder"
                              : "Ingresá tus credenciales para continuar",
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (!usuarioGuardado) ...[
                          _buildInputLabel("Correo electrónico", textSecondary),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: emailController,
                            hint: "ejemplo@fersal.com",
                            icon: Icons.email_outlined,
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildInputLabel("Contraseña", textSecondary),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: passwordController,
                          hint: "••••••••",
                          icon: Icons.lock_outline_rounded,
                          obscureText: obscurePassword,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.fingerprint_rounded,
                                  color: primaryBlue,
                                  size: 22,
                                ),
                                onPressed: validarBiometria,
                                tooltip: "Ingreso Biométrico",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (usuarioGuardado)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: cambiarUsuario,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "¿No sos tú? Cambiar de usuario",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: remember,
                                  activeColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      remember = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Recordarme en este dispositivo",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "INGRESAR AL SISTEMA",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "FERSAL APP v1.0.0",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tu negocio, bajo control.",
                    style: TextStyle(
                      color: textSecondary.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, Color textSecondary) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: textSecondary.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: textSecondary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
