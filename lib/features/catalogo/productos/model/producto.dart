class Producto {
  final String id;

  final String empresaId;
  final String? empresaNombre;

  final String? categoriaId;
  final String? categoriaNombre;

  final String? proveedorId;
  final String? proveedorNombre;

  final String codigo;
  final String nombre;
  final String? descripcion;

  final String? imagenUrl;

  final double? precioCompra;
  final double? precioVenta;

  final int? stockMinimo;

  final bool activo;

  Producto({
    required this.id,
    required this.empresaId,
    this.empresaNombre,
    this.categoriaId,
    this.categoriaNombre,
    this.proveedorId,
    this.proveedorNombre,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    this.precioCompra,
    this.precioVenta,
    this.stockMinimo,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json["id"]?.toString() ?? "",

      empresaId: json["empresaId"]?.toString() ?? "",

      empresaNombre: json["empresaNombre"]?.toString(),

      categoriaId: json["categoriaId"]?.toString(),

      categoriaNombre: json["categoriaNombre"]?.toString(),

      proveedorId: json["proveedorId"]?.toString(),

      proveedorNombre: json["proveedorNombre"]?.toString(),

      codigo: json["codigo"]?.toString() ?? "",

      nombre: json["nombre"]?.toString() ?? "",

      descripcion: json["descripcion"]?.toString(),

      imagenUrl: json["imagenUrl"]?.toString(),

      precioCompra: _toDouble(json["precioCompra"]),

      precioVenta: _toDouble(json["precioVenta"]),

      stockMinimo: _toInt(json["stockMinimo"]),

      activo: json["activo"] == true,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}
