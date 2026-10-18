class ClienteRequest {
  final String empresaId;

  final String nombre;
  final String? apellido;
  final String? documento;
  final String? telefono;
  final String? email;
  final String? direccion;

  ClienteRequest({
    required this.empresaId,
    required this.nombre,
    this.apellido,
    this.documento,
    this.telefono,
    this.email,
    this.direccion,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,

      "nombre": nombre,

      "apellido": apellido,

      "documento": documento,

      "telefono": telefono,

      "email": email,

      "direccion": direccion,
    };
  }
}
