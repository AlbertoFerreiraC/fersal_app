import '../../../../core/network/api_client.dart';
import '../model/dashboard_model.dart';

class DashboardRepository {
  final ApiClient apiClient;

  DashboardRepository(this.apiClient);

  Future<DashboardModel> obtenerMetricas({
    required String empresaId,
    required String sucursalId,
  }) async {
    final response = await apiClient.client.get(
      '/dashboard',
      queryParameters: {'empresaId': empresaId, 'sucursalId': sucursalId},
    );

    return DashboardModel.fromJson(response.data);
  }
}
