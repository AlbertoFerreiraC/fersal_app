class SucursalRequest {
  final String nombre;

  final String? direccion;

  final String? telefono;

  final String empresaId;

  SucursalRequest({
    required this.nombre,

    this.direccion,

    this.telefono,

    required this.empresaId,
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,

      "direccion": direccion,

      "telefono": telefono,

      "empresaId": empresaId,
    };
  }
}
