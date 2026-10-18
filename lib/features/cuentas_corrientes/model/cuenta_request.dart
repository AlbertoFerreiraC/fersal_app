class CuentaRequest {
  final String empresaId;

  final String clienteId;

  final double limiteCredito;

  CuentaRequest({
    required this.empresaId,

    required this.clienteId,

    required this.limiteCredito,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,

      "clienteId": clienteId,

      "limiteCredito": limiteCredito,
    };
  }
}
