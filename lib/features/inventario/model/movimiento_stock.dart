class MovimientoStock {
  final String id;
  final String producto;
  final String tipoMovimiento;
  final int cantidad;
  final int stockAnterior;
  final int stockNuevo;
  final String? observacion;

  MovimientoStock({
    required this.id,
    required this.producto,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.stockAnterior,
    required this.stockNuevo,
    this.observacion,
  });

  factory MovimientoStock.fromJson(Map<String, dynamic> json) {
    return MovimientoStock(
      id: json["id"] ?? "",
      producto: json["producto"] ?? "",
      tipoMovimiento: json["tipoMovimiento"] ?? "",
      cantidad: json["cantidad"] ?? 0,
      stockAnterior: json["stockAnterior"] ?? 0,
      stockNuevo: json["stockNuevo"] ?? 0,
      observacion: json["observacion"],
    );
  }
}
