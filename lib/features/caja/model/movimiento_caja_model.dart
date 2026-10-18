class MovimientoCajaModel {
  final String? id;
  final String empresaId;
  final String sucursalId;
  final String usuarioId;
  final String tipo;
  final double monto;
  final String descripcion;
  final DateTime? fecha;

  MovimientoCajaModel({
    this.id,
    required this.empresaId,
    required this.sucursalId,
    required this.usuarioId,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    this.fecha,
  });

  factory MovimientoCajaModel.fromJson(Map<String, dynamic> json) {
    return MovimientoCajaModel(
      id: json['id'],
      empresaId: json['empresaId'] ?? '',
      sucursalId: json['sucursalId'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      tipo: json['tipo'] ?? 'INGRESO',
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      descripcion: json['descripcion'] ?? '',
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'empresaId': empresaId,
      'sucursalId': sucursalId,
      'usuarioId': usuarioId,
      'tipo': tipo,
      'monto': monto,
      'descripcion': descripcion,
    };
  }
}
