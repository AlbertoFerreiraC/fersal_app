import 'detalle_venta.dart';

class Venta {
  final String id;

  final String numero;

  final String cliente;

  final String? documento;

  final String? telefono;

  final String? direccion;

  final String empresa;

  final String? empresaRuc;

  final String? empresaTelefono;

  final String fecha;

  final String? observacion;

  final double total;

  final String estado;

  final String tipoPago;

  final List<DetalleVenta> detalles;

  final String? motivoAnulacion;

  final String? fechaAnulacion;

  Venta({
    required this.id,

    required this.numero,

    required this.cliente,

    this.documento,

    this.telefono,

    this.direccion,

    required this.empresa,

    this.empresaRuc,

    this.empresaTelefono,

    required this.fecha,

    this.observacion,

    required this.total,

    required this.estado,

    required this.tipoPago,

    required this.detalles,

    this.motivoAnulacion,

    this.fechaAnulacion,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json["id"] ?? "",

      numero: json["numero"] ?? "",

      cliente: json["cliente"] ?? "Consumidor Final",

      documento: json["documento"],

      telefono: json["telefono"],

      direccion: json["direccion"],

      empresa: json["empresa"] ?? "",

      empresaRuc: json["empresaRuc"],

      empresaTelefono: json["empresaTelefono"],

      fecha: json["fecha"] ?? "",

      observacion: json["observacion"],

      total: double.tryParse(json["total"]?.toString() ?? "0") ?? 0,

      estado: json["estado"] ?? "",

      tipoPago: json["tipoPago"] ?? "",

      detalles: json["detalles"] == null
          ? []
          : List<DetalleVenta>.from(
              json["detalles"].map(
                (e) => DetalleVenta.fromJson(Map<String, dynamic>.from(e)),
              ),
            ),
      motivoAnulacion: json["motivoAnulacion"],

      fechaAnulacion: json["fechaAnulacion"],
    );
  }
}
