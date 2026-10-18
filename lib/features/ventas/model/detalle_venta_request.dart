class DetalleVentaRequest {
  final String productoId;

  final int cantidad;

  DetalleVentaRequest({required this.productoId, required this.cantidad});

  Map<String, dynamic> toJson() {
    return {"productoId": productoId, "cantidad": cantidad};
  }
}
