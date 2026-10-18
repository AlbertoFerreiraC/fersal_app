import '../../../../core/network/api_client.dart';
import '../model/cierre_caja_model.dart';
import '../model/movimiento_caja_model.dart';

class CajaRepository {
  final ApiClient apiClient;

  CajaRepository(this.apiClient);

  Future<MovimientoCajaModel> registrarMovimiento(
    MovimientoCajaModel movimiento,
  ) async {
    final response = await apiClient.client.post(
      '/caja/movimientos',
      data: movimiento.toJson(),
    );
    return MovimientoCajaModel.fromJson(response.data);
  }

  Future<List<MovimientoCajaModel>> listarMovimientos({
    required String empresaId,
    String? sucursalId,
    String? usuarioId,
  }) async {
    final Map<String, dynamic> params = {'empresaId': empresaId};
    if (sucursalId != null && sucursalId.isNotEmpty) {
      params['sucursalId'] = sucursalId;
    }
    if (usuarioId != null && usuarioId.isNotEmpty) {
      params['usuarioId'] = usuarioId;
    }

    final response = await apiClient.client.get(
      '/caja/movimientos',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List)
          .map((item) => MovimientoCajaModel.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<CierreCajaModel?> obtenerCajaAbierta({
    required String empresaId,
    required String sucursalId,
    required String usuarioId,
  }) async {
    try {
      final response = await apiClient.client.get(
        '/caja/cierres/estado',
        queryParameters: {
          'empresaId': empresaId,
          'sucursalId': sucursalId,
          'usuarioId': usuarioId,
        },
      );
      if (response.data != null) {
        return CierreCajaModel.fromJson(response.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CierreCajaModel> abrirCaja({
    required String empresaId,
    required String sucursalId,
    required String usuarioId,
    required double saldoInicial,
  }) async {
    final response = await apiClient.client.post(
      '/caja/cierres/abrir',
      data: {
        'empresaId': empresaId,
        'sucursalId': sucursalId,
        'usuarioId': usuarioId,
        'saldoInicial': saldoInicial,
      },
    );
    return CierreCajaModel.fromJson(response.data);
  }

  Future<CierreCajaModel> cerrarCaja(CierreCajaModel request) async {
    final response = await apiClient.client.post(
      '/caja/cierres/cerrar',
      data: request.toJson(),
    );
    return CierreCajaModel.fromJson(response.data);
  }

  Future<void> notificarArqueo({
    required String empresaId,
    required String sucursalId,
    required String usuarioId,
    required double saldoEsperado,
    required double saldoFisico,
  }) async {
    await apiClient.client.post(
      '/caja/cierres/notificar-arqueo',
      data: {
        'empresaId': empresaId,
        'sucursalId': sucursalId,
        'usuarioId': usuarioId,
        'saldoEsperado': saldoEsperado,
        'saldoFisico': saldoFisico,
      },
    );
  }

  Future<List<CierreCajaModel>> listarCierres({
    required String empresaId,
    String? sucursalId,
    String? usuarioId,
  }) async {
    final Map<String, dynamic> params = {'empresaId': empresaId};
    if (sucursalId != null && sucursalId.isNotEmpty) {
      params['sucursalId'] = sucursalId;
    }
    if (usuarioId != null && usuarioId.isNotEmpty) {
      params['usuarioId'] = usuarioId;
    }

    final response = await apiClient.client.get(
      '/caja/cierres',
      queryParameters: params,
    );
    if (response.data is List) {
      return (response.data as List)
          .map((item) => CierreCajaModel.fromJson(item))
          .toList();
    }
    return [];
  }
}
