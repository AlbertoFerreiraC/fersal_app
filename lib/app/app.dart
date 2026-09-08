import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/security/session_manager.dart';
import '../features/dashboard/presentation/splash_page.dart';

// Notificador global para escuchar los cambios de tema en tiempo real
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class FersalApp extends StatelessWidget {
  const FersalApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fersal App',
          navigatorKey: navigatorKey,
          theme: FersalTheme.light,
          darkTheme: FersalTheme.dark,
          themeMode: currentThemeMode, // <--- Usa la variable reactiva
          builder: (context, child) {
            return SessionManager(
              navigatorKey: navigatorKey,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashPage(),
        );
      },
    );
  }
}
