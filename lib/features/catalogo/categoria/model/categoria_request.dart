class CategoriaRequest {
  final String empresaId;

  final String nombre;

  final String descripcion;

  CategoriaRequest({
    required this.empresaId,
    required this.nombre,
    required this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,

      "nombre": nombre,

      "descripcion": descripcion,
    };
  }
}
