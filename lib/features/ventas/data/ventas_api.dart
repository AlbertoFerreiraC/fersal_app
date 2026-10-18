import '../../../../core/network/api_client.dart';
import '../model/venta.dart';
import '../model/venta_request.dart';

class VentasApi {
  final ApiClient apiClient;

  VentasApi(this.apiClient);

  Future<List<Venta>> listarPorEmpresaYSucursal({
    required String empresaId,
    String? sucursalId,
  }) async {
    final Map<String, dynamic> params = {'empresaId': empresaId};
    if (sucursalId != null && sucursalId.isNotEmpty) {
      params['sucursalId'] = sucursalId;
    }

    final response = await apiClient.client.get(
      "/ventas",
      queryParameters: params,
    );

    final List data = response.data;
    return data
        .map((e) => Venta.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Venta> crear(VentaRequest request) async {
    final response = await apiClient.client.post(
      "/ventas",
      data: request.toJson(),
    );

    return Venta.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Venta> buscar(String id) async {
    final response = await apiClient.client.get("/ventas/$id");
    return Venta.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<String> obtenerComprobante(String ventaId) async {
    final response = await apiClient.client.get("/ventas/$ventaId/comprobante");
    return response.data["contenidoBase64"];
  }

  Future<Venta> anular(String ventaId, String usuarioId, String motivo) async {
    final response = await apiClient.client.put(
      "/ventas/$ventaId/anular",
      queryParameters: {"usuarioId": usuarioId},
      data: {"motivo": motivo},
    );

    return Venta.fromJson(Map<String, dynamic>.from(response.data));
  }
}
