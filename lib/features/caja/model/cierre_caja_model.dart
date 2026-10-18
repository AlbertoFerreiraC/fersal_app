class CierreCajaModel {
  final String? id;
  final String? empresaId;
  final String? sucursalId;
  final String? usuarioId;
  final double saldoInicial;
  final double? totalIngresos;
  final double? totalEgresos;
  final double? saldoFinal;
  final DateTime? fecha;

  CierreCajaModel({
    this.id,
    this.empresaId,
    this.sucursalId,
    this.usuarioId,
    required this.saldoInicial,
    this.totalIngresos,
    this.totalEgresos,
    this.saldoFinal,
    this.fecha,
  });

  factory CierreCajaModel.fromJson(Map<String, dynamic> json) {
    return CierreCajaModel(
      id: json['id'],
      empresaId: json['empresaId'],
      sucursalId: json['sucursalId'],
      usuarioId: json['usuarioId'],
      saldoInicial: (json['saldoInicial'] as num?)?.toDouble() ?? 0.0,
      totalIngresos: (json['totalIngresos'] as num?)?.toDouble() ?? 0.0,
      totalEgresos: (json['totalEgresos'] as num?)?.toDouble() ?? 0.0,
      saldoFinal: (json['saldoFinal'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (empresaId != null) 'empresaId': empresaId,
      if (sucursalId != null) 'sucursalId': sucursalId,
      if (usuarioId != null) 'usuarioId': usuarioId,
      'saldoInicial': saldoInicial,
    };
  }
}
