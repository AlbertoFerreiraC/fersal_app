class MovimientoRequest {
  final String empresaId;
  final String sucursalId;
  final String productoId;
  final String usuarioId;

  final String tipoMovimiento;
  final int cantidad;

  final String? observacion;

  MovimientoRequest({
    required this.empresaId,

    required this.sucursalId,

    required this.productoId,

    required this.usuarioId,

    required this.tipoMovimiento,

    required this.cantidad,

    this.observacion,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,

      "sucursalId": sucursalId,

      "productoId": productoId,

      "usuarioId": usuarioId,

      "tipoMovimiento": tipoMovimiento,

      "cantidad": cantidad,

      "observacion": observacion,
    };
  }
}
