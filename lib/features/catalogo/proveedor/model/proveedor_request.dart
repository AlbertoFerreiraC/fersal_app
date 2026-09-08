class ProveedorRequest {
  final String empresaId;
  final String nombre;
  final String ruc;
  final String telefono;
  final String email;
  final String direccion;

  ProveedorRequest({
    required this.empresaId,
    required this.nombre,
    required this.ruc,
    required this.telefono,
    required this.email,
    required this.direccion,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,
      "nombre": nombre,
      "ruc": ruc,
      "telefono": telefono,
      "email": email,
      "direccion": direccion,
    };
  }
}
