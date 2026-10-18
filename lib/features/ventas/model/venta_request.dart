import 'detalle_venta_request.dart';

class VentaRequest {
  final String empresaId;

  final String sucursalId;

  final String usuarioId;

  final String? clienteId;

  final String tipoPago;

  final String? observacion;

  final List<DetalleVentaRequest> detalles;

  VentaRequest({
    required this.empresaId,

    required this.sucursalId,

    required this.usuarioId,

    this.clienteId,

    required this.tipoPago,

    this.observacion,

    required this.detalles,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,

      "sucursalId": sucursalId,

      "usuarioId": usuarioId,

      "clienteId": clienteId,

      "tipoPago": tipoPago,

      "observacion": observacion ?? "",

      "detalles": detalles.map((e) => e.toJson()).toList(),
    };
  }
}
