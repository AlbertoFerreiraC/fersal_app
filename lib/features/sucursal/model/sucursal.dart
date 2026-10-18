class Sucursal {
  final String id;

  final String empresaId;

  final String empresaNombre;

  final String nombre;

  final String? direccion;

  final String? telefono;

  final bool activo;

  Sucursal({
    required this.id,

    required this.empresaId,

    required this.empresaNombre,

    required this.nombre,

    this.direccion,

    this.telefono,

    required this.activo,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json["id"],

      empresaId: json["empresaId"],

      empresaNombre: json["empresaNombre"] ?? "",

      nombre: json["nombre"],

      direccion: json["direccion"],

      telefono: json["telefono"],

      activo: json["activo"] ?? false,
    );
  }
}
