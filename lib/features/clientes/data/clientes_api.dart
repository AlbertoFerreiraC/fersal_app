import '../../../../core/network/api_client.dart';

import '../model/cliente.dart';
import '../model/cliente_request.dart';

class ClientesApi {
  final ApiClient apiClient;

  ClientesApi(this.apiClient);

  Future<List<Cliente>> listarEmpresa(String empresaId) async {
    final response = await apiClient.client.get("/clientes/empresa/$empresaId");

    final List data = response.data;

    return data.map((e) {
      return Cliente.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<Cliente> crear(ClienteRequest request) async {
    final response = await apiClient.client.post(
      "/clientes",
      data: request.toJson(),
    );

    return Cliente.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Cliente> actualizar(String id, ClienteRequest request) async {
    final response = await apiClient.client.put(
      "/clientes/$id",
      data: request.toJson(),
    );

    return Cliente.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> eliminar(String id) async {
    await apiClient.client.delete("/clientes/$id");
  }
}
