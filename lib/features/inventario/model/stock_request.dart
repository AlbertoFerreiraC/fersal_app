class StockRequest {
  final String empresaId;

  final String sucursalId;

  final String productoId;

  final int cantidad;

  final int stockMinimo;

  StockRequest({
    required this.empresaId,
    required this.sucursalId,
    required this.productoId,
    required this.cantidad,
    required this.stockMinimo,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,

      "sucursalId": sucursalId,

      "productoId": productoId,

      "cantidad": cantidad,

      "stockMinimo": stockMinimo,
    };
  }
}
