import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../model/producto.dart';
import '../model/producto_request.dart';

class ProductosApi {
  final ApiClient apiClient;

  ProductosApi(this.apiClient);

  Future<List<Producto>> listarEmpresa(String empresaId) async {
    final response = await apiClient.client.get(
      "/productos",
      queryParameters: {"empresaId": empresaId},
    );

    final List data = response.data;
    return data
        .map((json) => Producto.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<Producto> buscar(String id) async {
    final response = await apiClient.client.get("/productos/$id");
    return Producto.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Producto> crear(ProductoRequest request) async {
    final response = await apiClient.client.post(
      "/productos",
      data: request.toJson(),
    );
    return Producto.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Producto> actualizar(String id, ProductoRequest request) async {
    final response = await apiClient.client.put(
      "/productos/$id",
      data: request.toJson(),
    );
    return Producto.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> eliminar(String id) async {
    await apiClient.client.delete("/productos/$id");
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  Future<Producto> subirImagen(String productoId, File imagen) async {
    final nombreArchivo = imagen.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      "imagen": await MultipartFile.fromFile(
        imagen.path,
        filename: nombreArchivo,
      ),
    });

    final response = await apiClient.client.post(
      "/productos/$productoId/imagen",
      data: formData,
      options: Options(contentType: "multipart/form-data"),
    );

    debugPrint("========================================");
    debugPrint("RESPUESTA SUBIR IMAGEN");
    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("JSON: ${response.data}");
    debugPrint("========================================");

    return Producto.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> eliminarImagen(String productoId) async {
    await apiClient.client.delete("/productos/$productoId/imagen");
  }
}
