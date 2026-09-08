import 'dart:async';

import 'package:flutter/material.dart';

import '../storage/token_storage.dart';
import '../../features/auth/presentation/login_page.dart';

class SessionManager extends StatefulWidget {
  final Widget child;

  final GlobalKey<NavigatorState> navigatorKey;

  const SessionManager({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<SessionManager>
    with WidgetsBindingObserver {
  final TokenStorage storage = TokenStorage();

  Timer? _timer;

  static const Duration _timeout = Duration(minutes: 1);

  DateTime _ultimaActividad = DateTime.now();

  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _verificarInactividad();
    });
  }

  void _registrarActividad() {
    _ultimaActividad = DateTime.now();
  }

  Future<void> _verificarInactividad() async {
    if (_cerrandoSesion) {
      return;
    }

    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    final diferencia = DateTime.now().difference(_ultimaActividad);

    if (diferencia >= _timeout) {
      await _cerrarSesion();
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) {
      return;
    }

    _cerrandoSesion = true;

    _timer?.cancel();

    await storage.logout();

    final navigator = widget.navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verificarInactividad();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,

      onPointerDown: (_) {
        _registrarActividad();
      },

      onPointerMove: (_) {
        _registrarActividad();
      },

      onPointerUp: (_) {
        _registrarActividad();
      },

      child: widget.child,
    );
  }
}
