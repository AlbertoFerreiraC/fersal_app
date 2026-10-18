import '../../../../core/network/api_client.dart';

import '../model/sucursal.dart';
import '../model/sucursal_request.dart';

class SucursalesApi {
  final ApiClient apiClient;

  SucursalesApi(this.apiClient);

  Future<List<Sucursal>> listarEmpresa(String empresaId) async {
    final response = await apiClient.client.get(
      "/sucursales/empresa/$empresaId",
    );

    final List data = response.data;

    return data.map((json) => Sucursal.fromJson(json)).toList();
  }

  Future<Sucursal> crear(SucursalRequest request) async {
    final response = await apiClient.client.post(
      "/sucursales",

      data: request.toJson(),
    );

    return Sucursal.fromJson(response.data);
  }

  Future<Sucursal> actualizar(String id, SucursalRequest request) async {
    final response = await apiClient.client.put(
      "/sucursales/$id",

      data: request.toJson(),
    );

    return Sucursal.fromJson(response.data);
  }

  Future<void> eliminar(String id) async {
    await apiClient.client.delete("/sucursales/$id");
  }
}
