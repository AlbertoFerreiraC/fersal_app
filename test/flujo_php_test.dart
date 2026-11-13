import 'package:fersal_app/features/caja/data/caja_repository.dart';
import 'package:fersal_app/features/caja/model/cierre_caja_model.dart';
import 'package:fersal_app/features/compras/data/compras_api.dart';
import 'package:fersal_app/features/compras/model/compra_model.dart';
import 'package:fersal_app/features/ventas/data/ventas_api.dart';
import 'package:fersal_app/features/ventas/model/venta_request.dart';
import 'package:fersal_app/features/ventas/model/detalle_venta_request.dart';
import 'package:fersal_app/features/dashboard/data/dashboard_repository.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fersal_app/core/network/api_client.dart';
import 'package:fersal_app/core/storage/token_storage.dart';
import 'package:fersal_app/features/auth/data/auth_api.dart';
import 'package:fersal_app/features/auth/model/login_request.dart';
import 'package:fersal_app/features/catalogo/categoria/data/categorias_api.dart';
import 'package:fersal_app/features/catalogo/categoria/model/categoria_request.dart';
import 'package:fersal_app/features/catalogo/proveedor/data/proveedores_api.dart';
import 'package:fersal_app/features/catalogo/proveedor/model/proveedor_request.dart';
import 'package:fersal_app/features/catalogo/productos/data/productos_api.dart';
import 'package:fersal_app/features/catalogo/productos/model/producto_request.dart';

void main() {
  // Ejecutar solo contra la instancia aislada, nunca con usuarios reales.
  const enabled = bool.fromEnvironment('FERSAL_INTEGRATION');
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Flutter → PHP → PostgreSQL: login catálogo fotos dashboard y logout',
    () async {
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final storage = TokenStorage();
      final client = ApiClient(storage: storage);
      client.dio.options.baseUrl = const String.fromEnvironment('FERSAL_TEST_BASE_URL');
      final auth = AuthApi(client);
      final login = await auth.login(
        LoginRequest(
          email: const String.fromEnvironment('FERSAL_TEST_EMAIL'),
          password: const String.fromEnvironment('FERSAL_TEST_PASSWORD'),
        ),
      );
      await storage.saveSession(
        login.token,
        login.usuarioId,
        login.email,
        login.name,
        login.empresaId,
        login.empresaNombre,
        login.sucursalId,
        login.sucursalNombre,
      );
      await client.dio.get('/auth/me');
      final categories = CategoriasApi(client);
      final suppliers = ProveedoresApi(client);
      final products = ProductosApi(client);
      final category = await categories.crear(
        CategoriaRequest(
          empresaId: login.empresaId,
          nombre: 'Categoría Flutter',
          descripcion: 'Integración real',
        ),
      );
      final supplier = await suppliers.crear(
        ProveedorRequest(
          empresaId: login.empresaId,
          nombre: 'Proveedor Flutter',
          ruc: '',
          telefono: '',
          email: '',
          direccion: '',
        ),
      );
      final request = ProductoRequest(
        empresaId: login.empresaId,
        categoriaId: category.id,
        proveedorId: supplier.id,
        codigo: 'FLUTTER-TEST',
        nombre: 'Producto Flutter',
        descripcion: 'Árbol y ñandutí',
        precioCompra: 12.50,
        precioVenta: 20.50,
        stockMinimo: 2,
      );
      final product = await products.crear(request);
      expect(product.precioVenta, 20.50);
      expect(product.activo, isTrue);
      expect(product.categoriaNombre, category.nombre);
      expect(
        (await products.listarEmpresa(login.empresaId)).single.id,
        product.id,
      );
      await products.actualizar(product.id, request);
      final uploaded = await products.subirImagen(
        product.id,
        File('assets/images/logo_fersal.PNG'),
      );
      expect(uploaded.imagenUrl, startsWith('http://127.0.0.1:'));
      final image = await client.dio.get(uploaded.imagenUrl!);
      expect(image.statusCode, 200);
      await products.eliminarImagen(product.id);
      expect((await products.buscar(product.id)).imagenUrl, isNull);
      final cash = CajaRepository(client);
      final opened = await cash.abrirCaja(
        empresaId: login.empresaId,
        sucursalId: login.sucursalId!,
        usuarioId: login.usuarioId,
        saldoInicial: 100,
      );
      expect(opened.saldoInicial, 100);
      final purchase = await ComprasApi(client).registrar(
        CompraRequest(
          empresaId: login.empresaId,
          sucursalId: login.sucursalId!,
          usuarioId: login.usuarioId,
          proveedorId: supplier.id,
          condicionPago: 'CONTADO',
          pagarDesdeCaja: false,
          detalles: [
            DetalleCompraItemRequest(
              productoId: product.id,
              cantidad: 3,
              precioUnitario: 12.5,
            ),
          ],
        ),
      );
      expect(purchase.total, 37.5);
      expect(purchase.sucursal, 'Principal');
      final sales = VentasApi(client);
      final sale = await sales.crear(
        VentaRequest(
          empresaId: login.empresaId,
          sucursalId: login.sucursalId!,
          usuarioId: login.usuarioId,
          tipoPago: 'CONTADO',
          detalles: [DetalleVentaRequest(productoId: product.id, cantidad: 1)],
        ),
      );
      expect(sale.total, 20.5);
      final active = await cash.obtenerCajaAbierta(
        empresaId: login.empresaId,
        sucursalId: login.sucursalId!,
        usuarioId: login.usuarioId,
      );
      expect(active!.saldoFinal, 120.5);
      await cash.notificarArqueo(
        empresaId: login.empresaId,
        sucursalId: login.sucursalId!,
        usuarioId: login.usuarioId,
        saldoEsperado: 120.5,
        saldoFisico: 120.5,
      );
      final metrics = await DashboardRepository(client).obtenerMetricas(
        empresaId: login.empresaId,
        sucursalId: login.sucursalId!,
      );
      expect(metrics.ventasHoy, 20.5);
      expect(metrics.gananciaHoy, 8);
      final rows=await cash.listarMovimientos(empresaId:login.empresaId,sucursalId:login.sucursalId!,usuarioId:login.usuarioId);
      final viewBalance=rows.fold<double>(0,(sum,m)=>sum+(m.tipo=='INGRESO'?m.monto:-m.monto));
      expect(viewBalance,120.5);
      expect(metrics.ultimasTransacciones.single.ventaId, sale.id);
      expect(await sales.obtenerComprobante(sale.id), startsWith('JVBER'));
      await sales.anular(sale.id, login.usuarioId, 'Prueba aislada');
      final closed = await cash.cerrarCaja(
        CierreCajaModel(
          empresaId: login.empresaId,
          sucursalId: login.sucursalId!,
          usuarioId: login.usuarioId,
          saldoInicial: 999,
        ),
      );
      expect(closed.saldoFinal, 100);
      await products.eliminar(product.id);
      await categories.eliminar(category.id);
      await suppliers.eliminar(supplier.id);
      expect(await products.listarEmpresa(login.empresaId), isEmpty);
      await client.dio.post('/auth/logout');
      await storage.logout(revoke:false);
      expect(await storage.hasSession(), isFalse);
      client.dio.close();
    },
    skip: !enabled,
  );
}
