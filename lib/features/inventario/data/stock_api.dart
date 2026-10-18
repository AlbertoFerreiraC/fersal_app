import '../../../../core/network/api_client.dart';
import '../model/stock.dart';
import '../model/stock_request.dart';

class StockApi {
  final ApiClient apiClient;

  StockApi(this.apiClient);

  Future<List<Stock>> listarPorEmpresaYSucursal({
    required String empresaId,
    String? sucursalId,
  }) async {
    final Map<String, dynamic> params = {'empresaId': empresaId};
    if (sucursalId != null && sucursalId.isNotEmpty) {
      params['sucursalId'] = sucursalId;
    }

    final response = await apiClient.client.get(
      "/stock",
      queryParameters: params,
    );

    final List data = response.data;
    return data.map((json) => Stock.fromJson(json)).toList();
  }

  Future<List<Stock>> listarSucursal(String sucursalId) async {
    final response = await apiClient.client.get("/stock/sucursal/$sucursalId");
    final List data = response.data;
    return data.map((json) => Stock.fromJson(json)).toList();
  }

  Future<List<Stock>> bajoStock(String empresaId) async {
    final response = await apiClient.client.get(
      "/stock/bajo",
      queryParameters: {'empresaId': empresaId},
    );
    final List data = response.data;
    return data.map((json) => Stock.fromJson(json)).toList();
  }

  Future<Stock> crear(StockRequest request) async {
    final response = await apiClient.client.post(
      "/stock",
      data: request.toJson(),
    );
    return Stock.fromJson(response.data);
  }

  Future<Stock> actualizar(String id, StockRequest request) async {
    final response = await apiClient.client.put(
      "/stock/$id",
      data: request.toJson(),
    );
    return Stock.fromJson(response.data);
  }
}
