class Categoria {
  final String id;

  final String empresaId;

  final String empresaNombre;

  final String nombre;

  final String? descripcion;

  final bool activo;

  Categoria({
    required this.id,
    required this.empresaId,
    required this.empresaNombre,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json["id"],

      empresaId: json["empresaId"],

      empresaNombre: json["empresaNombre"],

      nombre: json["nombre"],

      descripcion: json["descripcion"],

      activo: json["activo"] ?? false,
    );
  }
}
