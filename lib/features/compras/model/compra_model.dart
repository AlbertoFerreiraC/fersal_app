class CompraRequest {
  final String empresaId;
  final String sucursalId;
  final String usuarioId;
  final String proveedorId;
  final String? numeroFactura;
  final String condicionPago; // CONTADO o CREDITO
  final bool pagarDesdeCaja;
  final String? observacion;
  final List<DetalleCompraItemRequest> detalles;

  CompraRequest({
    required this.empresaId,
    required this.sucursalId,
    required this.usuarioId,
    required this.proveedorId,
    this.numeroFactura,
    required this.condicionPago,
    required this.pagarDesdeCaja,
    this.observacion,
    required this.detalles,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,
      "sucursalId": sucursalId,
      "usuarioId": usuarioId,
      "proveedorId": proveedorId,
      "numeroFactura": numeroFactura,
      "condicionPago": condicionPago,
      "pagarDesdeCaja": pagarDesdeCaja,
      "observacion": observacion,
      "detalles": detalles.map((d) => d.toJson()).toList(),
    };
  }
}

class DetalleCompraItemRequest {
  final String productoId;
  final int cantidad;
  final double precioUnitario;

  DetalleCompraItemRequest({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  Map<String, dynamic> toJson() {
    return {
      "productoId": productoId,
      "cantidad": cantidad,
      "precioUnitario": precioUnitario,
    };
  }
}

class CompraModel {
  final String id;
  final String? numeroFactura;
  final String proveedor;
  final String sucursal;
  final String condicionPago;
  final double total;
  final String estado;
  final DateTime? fecha;
  final List<DetalleCompraResponse> detalles;

  CompraModel({
    required this.id,
    this.numeroFactura,
    required this.proveedor,
    required this.sucursal,
    required this.condicionPago,
    required this.total,
    required this.estado,
    this.fecha,
    required this.detalles,
  });

  factory CompraModel.fromJson(Map<String, dynamic> json) {
    return CompraModel(
      id: json['id'] ?? '',
      numeroFactura: json['numeroFactura'],
      proveedor: json['proveedor'] ?? '',
      sucursal: json['sucursal'] ?? '',
      condicionPago: json['condicionPago'] ?? 'CONTADO',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] ?? 'COMPLETADA',
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
      detalles: (json['detalles'] as List<dynamic>?)
              ?.map((d) => DetalleCompraResponse.fromJson(d))
              .toList() ??
          [],
    );
  }
}

class DetalleCompraResponse {
  final String productoId;
  final String producto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleCompraResponse({
    required this.productoId,
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleCompraResponse.fromJson(Map<String, dynamic> json) {
    return DetalleCompraResponse(
      productoId: json['productoId'] ?? '',
      producto: json['producto'] ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (json['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}