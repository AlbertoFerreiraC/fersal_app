class Proveedor {
  final String id;
  final String empresaId;
  final String empresaNombre;
  final String nombre;
  final String? ruc;
  final String? telefono;
  final String? email;
  final String? direccion;
  final bool activo;

  Proveedor({
    required this.id,
    required this.empresaId,
    required this.empresaNombre,
    required this.nombre,
    this.ruc,
    this.telefono,
    this.email,
    this.direccion,
    required this.activo,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json["id"],
      empresaId: json["empresaId"],
      empresaNombre: json["empresaNombre"] ?? "",
      nombre: json["nombre"] ?? "",
      ruc: json["ruc"],
      telefono: json["telefono"],
      email: json["email"],
      direccion: json["direccion"],
      activo: json["activo"] ?? true,
    );
  }
}
