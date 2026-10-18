class Cliente {
  final String id;
  final String nombre;
  final String? apellido;
  final String? documento;
  final String? telefono;
  final String? email;
  final String? direccion;
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    this.apellido,
    this.documento,
    this.telefono,
    this.email,
    this.direccion,
    required this.activo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json["id"] ?? "",
      nombre: json["nombre"] ?? "",
      apellido: json["apellido"],
      documento: json["documento"],
      telefono: json["telefono"],
      email: json["email"],
      direccion: json["direccion"],
      activo: json["activo"] ?? false,
    );
  }
}
