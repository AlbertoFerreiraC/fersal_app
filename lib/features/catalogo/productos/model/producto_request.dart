class ProductoRequest {
  final String empresaId;

  final String? categoriaId;

  final String? proveedorId;

  final String codigo;

  final String nombre;

  final String descripcion;

  final double? precioCompra;

  final double? precioVenta;

  final int? stockMinimo;

  ProductoRequest({
    required this.empresaId,
    this.categoriaId,
    this.proveedorId,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    this.precioCompra,
    this.precioVenta,
    this.stockMinimo,
  });

  Map<String, dynamic> toJson() {
    return {
      "empresaId": empresaId,
      "categoriaId": categoriaId,
      "proveedorId": proveedorId,
      "codigo": codigo,
      "nombre": nombre,
      "descripcion": descripcion,
      "precioCompra": precioCompra,
      "precioVenta": precioVenta,
      "stockMinimo": stockMinimo,
    };
  }
}