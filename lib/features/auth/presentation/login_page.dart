import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/security/biometric_service.dart';

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

  String nombreUsuario = "";

  final storage = TokenStorage();

  @override
  void initState() {
    super.initState();

    cargarSesion();
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

  Future<void> login() async {
    setState(() {
      loading = true;
    });

    try {
      final api = AuthApi(ApiClient(storage: storage));

      final response = await api.login(
        LoginRequest(
          email: emailController.text.trim(),

          password: passwordController.text,
        ),
      );
      // debug prints removed

      await storage.saveSession(
        response.token,
        response.email,
        response.name,
        response.empresaId,
        response.empresaNombre,
      );

      await storage.saveRemember(remember);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      // debug prints removed

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> validarBiometria() async {
    final activa = await storage.getBiometric();

    if (!activa) {
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

      final api = AuthApi(ApiClient(storage: storage));

      final response = await api.biometricLogin(email);

      await storage.saveSession(
        response.token,
        response.email,
        response.name,
        response.empresaId,
        response.empresaNombre,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      // debug prints removed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al ingresar con biometría")),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [Color(0xff03142F), Color(0xff020817)],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),

              child: Column(
                children: [
                  const SizedBox(height: 45),

                  Container(
                    width: 150,

                    height: 150,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(.25),

                          blurRadius: 50,
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.account_balance,

                      size: 80,

                      color: Color(0xffD6B56C),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "FERSAL",

                    style: TextStyle(
                      fontSize: 42,

                      fontWeight: FontWeight.bold,

                      letterSpacing: 5,

                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "GESTIÓN INTELIGENTE",

                    style: TextStyle(
                      letterSpacing: 4,

                      color: Colors.white70,

                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 70),

                  Text(
                    usuarioGuardado
                        ? "¡Hola, $nombreUsuario!"
                        : "Iniciar sesión",

                    style: const TextStyle(
                      fontSize: 30,

                      fontWeight: FontWeight.bold,

                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    usuarioGuardado
                        ? "Ingresá tu contraseña para continuar"
                        : "Accedé a tu sistema de gestión",

                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 45),

                  if (!usuarioGuardado)
                    _input(
                      controller: emailController,

                      icon: Icons.email_outlined,

                      hint: "Email",
                    ),

                  if (!usuarioGuardado) const SizedBox(height: 20),

                  _input(
                    controller: passwordController,
                    icon: Icons.lock_outline,
                    hint: "Contraseña",
                    password: true,
                  ),

                  if (usuarioGuardado)
                    TextButton(
                      onPressed: cambiarUsuario,

                      child: const Text(
                        "¿No sos tú? Iniciar con otro usuario",

                        style: TextStyle(color: Color(0xff2580FF)),
                      ),
                    ),

                  if (!usuarioGuardado)
                    Row(
                      children: [
                        Checkbox(
                          value: remember,

                          activeColor: const Color(0xff1769FF),

                          onChanged: (value) {
                            setState(() {
                              remember = value ?? false;
                            });
                          },
                        ),

                        const Text(
                          "Recordarme",

                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,

                    height: 58,

                    child: ElevatedButton(
                      onPressed: loading ? null : login,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1769FF),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "INGRESAR",

                              style: TextStyle(
                                fontSize: 17,

                                fontWeight: FontWeight.bold,

                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  const Text(
                    "FERSAL APP",

                    style: TextStyle(color: Colors.white54, letterSpacing: 3),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Tu negocio, bajo control.",

                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,

    required IconData icon,

    required String hint,

    bool password = false,

    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,

      onTap: onTap,

      obscureText: password,

      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(color: Colors.white60),

        prefixIcon: Icon(icon, color: Colors.white70),

        suffixIcon: password
            ? IconButton(
                icon: const Icon(Icons.fingerprint, color: Color(0xffD6B56C)),

                onPressed: validarBiometria,
              )
            : null,

        filled: true,

        fillColor: Colors.white.withOpacity(.05),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: const BorderSide(color: Colors.white24),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),

          borderSide: const BorderSide(color: Color(0xff1769FF)),
        ),
      ),
    );
  }
}
