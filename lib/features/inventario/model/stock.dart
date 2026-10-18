class Stock {
  final String id;

  final String sucursalId;
  final String sucursalNombre;

  final String productoId;
  final String productoNombre;

  final int cantidad;
  final int stockMinimo;

  Stock({
    required this.id,
    required this.sucursalId,
    required this.sucursalNombre,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.stockMinimo,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json["id"],

      sucursalId: json["sucursalId"],
      sucursalNombre: json["sucursalNombre"],

      productoId: json["productoId"],
      productoNombre: json["productoNombre"],

      cantidad: json["cantidad"] ?? 0,
      stockMinimo: json["stockMinimo"] ?? 0,
    );
  }

  bool get stockBajo {
    return cantidad <= stockMinimo;
  }
}
