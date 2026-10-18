class DetalleVenta {
  final String productoId;

  final String producto;

  final int cantidad;

  final double precio;

  final double subtotal;

  DetalleVenta({
    required this.productoId,

    required this.producto,

    required this.cantidad,

    required this.precio,

    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      productoId: json["productoId"] ?? "",

      producto: json["producto"] ?? "",

      cantidad: json["cantidad"] ?? 0,

      precio: double.tryParse(json["precio"]?.toString() ?? "0") ?? 0,

      subtotal: double.tryParse(json["subtotal"]?.toString() ?? "0") ?? 0,
    );
  }
}
