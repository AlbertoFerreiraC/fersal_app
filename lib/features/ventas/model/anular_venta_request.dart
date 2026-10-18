class AnularVentaRequest {
  final String motivo;

  AnularVentaRequest({required this.motivo});

  Map<String, dynamic> toJson() {
    return {"motivo": motivo};
  }
}
