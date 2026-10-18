class LoginResponse {
  final String token;

  final String usuarioId;

  final String email;

  final String name;

  final String empresaId;

  final String empresaNombre;

  final String? sucursalId;

  final String? sucursalNombre;

  LoginResponse({
    required this.token,
    required this.usuarioId,
    required this.email,
    required this.name,
    required this.empresaId,
    required this.empresaNombre,
    this.sucursalId,
    this.sucursalNombre,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json["token"] ?? "",

      usuarioId: json["usuarioId"] ?? "",

      email: json["email"] ?? "",

      name: json["name"] ?? "",

      empresaId: json["empresaId"] ?? "",

      empresaNombre: json["empresaNombre"] ?? "",

      sucursalId: json["sucursalId"],

      sucursalNombre: json["sucursalNombre"],
    );
  }
}
