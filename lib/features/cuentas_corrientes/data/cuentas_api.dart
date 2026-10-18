import '../../../../core/network/api_client.dart';
import '../model/cuenta_corriente.dart';
import '../model/cuenta_request.dart';

class CuentasApi {
  final ApiClient apiClient;

  CuentasApi(this.apiClient);

  Future<CuentaCorriente> crear(CuentaRequest request) async {
    final response = await apiClient.client.post(
      "/cuentas-corrientes",
      data: request.toJson(),
    );

    return CuentaCorriente.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<CuentaCorriente>> listarEmpresa(String empresaId) async {
    final response = await apiClient.client.get(
      "/cuentas-corrientes",
      queryParameters: {"empresaId": empresaId},
    );

    final List data = response.data;
    return data.map((e) {
      return CuentaCorriente.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<CuentaCorriente> buscar(String id) async {
    final response = await apiClient.client.get("/cuentas-corrientes/$id");
    return CuentaCorriente.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CuentaCorriente> buscarCliente(String clienteId) async {
    final response = await apiClient.client.get(
      "/cuentas-corrientes/cliente/$clienteId",
    );
    return CuentaCorriente.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CuentaCorriente> actualizar(String id, CuentaRequest request) async {
    final response = await apiClient.client.put(
      "/cuentas-corrientes/$id",
      data: request.toJson(),
    );
    return CuentaCorriente.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> eliminar(String id) async {
    await apiClient.client.delete("/cuentas-corrientes/$id");
  }

  Future<void> actualizarMonto(String id, double limiteCredito) async {
    await apiClient.client.put(
      "/cuentas-corrientes/$id",
      data: {"limiteCredito": limiteCredito},
    );
  }
}
