import 'package:flutter/material.dart';

import '../../auth/presentation/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);

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
                    const Color(0xFF1E3A8A).withOpacity(0.6),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFF1B62D4),
                    const Color(0xFF246BFD).withOpacity(0.85),
                    const Color(0xFF1E62D4),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // LOGO CON RESPLANDOR
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.35),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: Image.asset(
                      'assets/images/logo_fersal.PNG',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 70,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // TÍTULO FERSAL
              const Text(
                'FERSAL',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              // ESlogan / SUBTÍTULO
              Text(
                'INNOVACIÓN • DISEÑO • SOLUCIONES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),

              const Spacer(),

              // INDICADOR DE CARGA Y VERSIÓN
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
