import '../../../../core/network/api_client.dart';
import '../model/compra_model.dart';

class ComprasApi {
  final ApiClient apiClient;

  ComprasApi(this.apiClient);

  Future<CompraModel> registrar(CompraRequest request) async {
    final response = await apiClient.client.post(
      "/compras",
      data: request.toJson(),
    );
    return CompraModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<CompraModel>> listarPorEmpresaYSucursal({
    required String empresaId,
    String? sucursalId,
  }) async {
    final Map<String, dynamic> params = {'empresaId': empresaId};
    if (sucursalId != null && sucursalId.isNotEmpty) {
      params['sucursalId'] = sucursalId;
    }

    final response = await apiClient.client.get(
      "/compras",
      queryParameters: params,
    );

    final List data = response.data;
    return data
        .map((e) => CompraModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CompraModel> buscar(String id) async {
    final response = await apiClient.client.get("/compras/$id");
    return CompraModel.fromJson(Map<String, dynamic>.from(response.data));
  }
}
