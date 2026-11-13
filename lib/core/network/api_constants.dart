enum AppEnvironment { local, vpn, render }

class ApiConstants {
  // ============================================================
  // SELECTOR RÁPIDO DE AMBIENTE
  // Cambia este valor a AppEnvironment.render para usar la nube
  // ============================================================
  static const AppEnvironment _defaultEnvironment = AppEnvironment.render;

  // URLs configuradas
  static const String _urlLocal = "http://10.80.2.64:8080/api";
  static const String _urlVpn = "http://100.116.228.4:8080/api";
  static const String _urlRender = "https://fersal-dev.com/fersal/api";

  /// Permite pasar el ambiente por línea de comandos o usar el selector por defecto:
  /// flutter run --dart-define=ENV=render
  /// flutter run --dart-define=ENV=vpn
  /// flutter run --dart-define=ENV=local
  static String get baseUrl {
    const envArg = String.fromEnvironment('ENV', defaultValue: '');

    if (envArg.toLowerCase() == 'render') {
      return _urlRender;
    } else if (envArg.toLowerCase() == 'vpn') {
      return _urlVpn;
    } else if (envArg.toLowerCase() == 'local') {
      return _urlLocal;
    }

    // Retorna según el ambiente por defecto que hayas elegido arriba
    switch (_defaultEnvironment) {
      case AppEnvironment.render:
        return _urlRender;
      case AppEnvironment.vpn:
        return _urlVpn;
      case AppEnvironment.local:
      default:
        return _urlLocal;
    }
  }

  static bool get isRender => baseUrl == _urlRender;
  static bool get isVpn => baseUrl == _urlVpn;

  // Endpoints Comunes
  static const String login = "/auth/login";
  static const String movimientosCaja = "/caja/movimientos";
  static const String clientes = "/clientes";
}