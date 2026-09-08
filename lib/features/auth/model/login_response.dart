class LoginResponse {
  final String token;

  final String email;

  final String name;

  final String empresaId;

  final String empresaNombre;

  LoginResponse({
    required this.token,
    required this.email,
    required this.name,
    required this.empresaId,
    required this.empresaNombre,
  });
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json["token"] ?? "",

      email: json["email"] ?? "",

      name: json["name"] ?? "",

      empresaId: json["empresaId"] ?? "",

      empresaNombre: json["empresaNombre"] ?? "",
    );
  }
}
