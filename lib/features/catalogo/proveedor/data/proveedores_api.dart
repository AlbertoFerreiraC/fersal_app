import '../../../../core/network/api_client.dart';

import '../model/proveedor.dart';
import '../model/proveedor_request.dart';

class ProveedoresApi {
  final ApiClient apiClient;

  ProveedoresApi(this.apiClient);

  Future<List<Proveedor>> listarEmpresa(String empresaId) async {
    final response = await apiClient.client.get(
      "/proveedores/empresa/$empresaId",
    );

    final List data = response.data;

    return data.map((json) => Proveedor.fromJson(json)).toList();
  }

  Future<Proveedor> crear(ProveedorRequest request) async {
    final response = await apiClient.client.post(
      "/proveedores",
      data: request.toJson(),
    );

    return Proveedor.fromJson(response.data);
  }

  Future<Proveedor> actualizar(String id, ProveedorRequest request) async {
    final response = await apiClient.client.put(
      "/proveedores/$id",
      data: request.toJson(),
    );

    return Proveedor.fromJson(response.data);
  }

  Future<void> eliminar(String id) async {
    await apiClient.client.delete("/proveedores/$id");
  }
}
