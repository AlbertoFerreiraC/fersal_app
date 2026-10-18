import '../../../../core/network/api_client.dart';
import '../model/categoria.dart';
import '../model/categoria_request.dart';

class CategoriasApi {
  final ApiClient apiClient;

  CategoriasApi(this.apiClient);

  Future<List<Categoria>> listarEmpresa(String empresaId) async {
    final response = await apiClient.client.get(
      "/categorias",
      queryParameters: {"empresaId": empresaId},
    );

    final List data = response.data;
    return data.map((json) => Categoria.fromJson(json)).toList();
  }

  Future<Categoria> crear(CategoriaRequest request) async {
    final response = await apiClient.client.post(
      "/categorias",
      data: request.toJson(),
    );
    return Categoria.fromJson(response.data);
  }

  Future<Categoria> actualizar(String id, CategoriaRequest request) async {
    final response = await apiClient.client.put(
      "/categorias/$id",
      data: request.toJson(),
    );
    return Categoria.fromJson(response.data);
  }

  Future<void> eliminar(String id) async {
    await apiClient.client.delete("/categorias/$id");
  }
}
