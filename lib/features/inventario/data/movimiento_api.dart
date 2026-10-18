import '../../../../core/network/api_client.dart';
import '../model/movimiento_stock.dart';
import '../model/movimiento_request.dart';

class MovimientoApi {
  final ApiClient apiClient;

  MovimientoApi(this.apiClient);

  Future<MovimientoStock> crear(MovimientoRequest request) async {
    final response = await apiClient.client.post(
      "/movimientos-stock",
      data: request.toJson(),
    );

    return MovimientoStock.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<MovimientoStock>> listarPorEmpresaYSucursal({
    required String empresaId,
    String? sucursalId,
  }) async {
    final Map<String, dynamic> params = {'empresaId': empresaId};
    if (sucursalId != null && sucursalId.isNotEmpty) {
      params['sucursalId'] = sucursalId;
    }

    final response = await apiClient.client.get(
      "/movimientos-stock",
      queryParameters: params,
    );

    final List data = response.data;
    return data.map((e) {
      return MovimientoStock.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<List<MovimientoStock>> listarProducto(String productoId) async {
    final response = await apiClient.client.get(
      "/movimientos-stock/producto/$productoId",
    );

    final List data = response.data;
    return data.map((e) {
      return MovimientoStock.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }
}
