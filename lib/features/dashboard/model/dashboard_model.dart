class DashboardModel {
  final double ventasHoy;
  final int transaccionesHoy;
  final double gananciaHoy;
  final double totalPorCobrar;
  final double totalPorPagar;
  final List<StockBajoModel> stockBajo;
  final List<TransaccionRecienteModel> ultimasTransacciones;

  DashboardModel({
    required this.ventasHoy,
    required this.transaccionesHoy,
    required this.gananciaHoy,
    required this.totalPorCobrar,
    required this.totalPorPagar,
    required this.stockBajo,
    required this.ultimasTransacciones,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      ventasHoy: (json['ventasHoy'] as num?)?.toDouble() ?? 0.0,
      transaccionesHoy: (json['transaccionesHoy'] as num?)?.toInt() ?? 0,
      gananciaHoy: (json['gananciaHoy'] as num?)?.toDouble() ?? 0.0,
      totalPorCobrar: (json['totalPorCobrar'] as num?)?.toDouble() ?? 0.0,
      totalPorPagar: (json['totalPorPagar'] as num?)?.toDouble() ?? 0.0,
      stockBajo:
          (json['stockBajo'] as List<dynamic>?)
              ?.map((e) => StockBajoModel.fromJson(e))
              .toList() ??
          [],
      ultimasTransacciones:
          (json['ultimasTransacciones'] as List<dynamic>?)
              ?.map((e) => TransaccionRecienteModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class StockBajoModel {
  final String productoId;
  final String nombre;
  final int stockActual;
  final int stockMinimo;

  StockBajoModel({
    required this.productoId,
    required this.nombre,
    required this.stockActual,
    required this.stockMinimo,
  });

  factory StockBajoModel.fromJson(Map<String, dynamic> json) {
    return StockBajoModel(
      productoId: json['productoId'] ?? '',
      nombre: json['nombre'] ?? '',
      stockActual: (json['stockActual'] as num?)?.toInt() ?? 0,
      stockMinimo: (json['stockMinimo'] as num?)?.toInt() ?? 0,
    );
  }
}

class TransaccionRecienteModel {
  final String ventaId;
  final String numero;
  final String cliente;
  final double total;
  final String tipoPago;
  final DateTime? fecha;

  TransaccionRecienteModel({
    required this.ventaId,
    required this.numero,
    required this.cliente,
    required this.total,
    required this.tipoPago,
    this.fecha,
  });

  factory TransaccionRecienteModel.fromJson(Map<String, dynamic> json) {
    return TransaccionRecienteModel(
      ventaId: json['ventaId'] ?? '',
      numero: json['numero'] ?? '',
      cliente: json['cliente'] ?? 'Consumidor Final',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      tipoPago: json['tipoPago'] ?? 'EFECTIVO',
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
    );
  }
}
