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
    // Delay then navigate; guard with mounted to avoid using context across
    // an async gap.
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
    // Palette inspired by the provided logo image:
    // - deepGreen: #264B38 (background)
    // - darkRed: #8B1E1E (accent)
    // - lightPink: #E7B1B8 (accent)
    const deepGreen = Color(0xFF264B38);
    const darkRed = Color(0xFF8B1E1E);
    const lightPink = Color(0xFFE7B1B8);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [deepGreen, Color(0xFF0B2A1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Try to load the real logo asset; if it's not present the UI will
              // fall back to a stylized icon built from the logo palette.
              SizedBox(
                width: 220,
                height: 220,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_fersal.PNG',
                    fit: BoxFit.contain,
                    // If the image is missing, show a simple fallback icon using the
                    // logo palette. The asset should be a transparent PNG so it
                    // renders directly over the green background.
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: lightPink.withOpacity(.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco,
                            color: darkRed,
                            size: 56,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'FERSAL',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Innovación. Diseño. Soluciones.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
