class CuentaCorriente {
  final String id;

  final String clienteId;

  final String cliente;

  final String? apellido;

  final String? telefono;

  final double saldo;

  final double limiteCredito;

  final bool activo;

  CuentaCorriente({
    required this.id,
    required this.clienteId,
    required this.cliente,
    this.apellido,
    this.telefono,
    required this.saldo,
    required this.limiteCredito,
    required this.activo,
  });

  factory CuentaCorriente.fromJson(Map<String, dynamic> json) {
    return CuentaCorriente(
      id: json["id"] ?? "",

      clienteId: json["clienteId"] ?? "",

      cliente: json["cliente"] ?? "",

      apellido: json["apellido"],

      telefono: json["telefono"],

      saldo: (json["saldo"] ?? 0).toDouble(),

      limiteCredito: (json["limiteCredito"] ?? 0).toDouble(),

      activo: json["activo"] ?? false,
    );
  }
}
