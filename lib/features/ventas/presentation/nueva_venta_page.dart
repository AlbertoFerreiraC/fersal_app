import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../clientes/data/clientes_api.dart';
import '../../clientes/model/cliente.dart';
import '../../../features/catalogo/productos/data/productos_api.dart';
import '../../../features/catalogo/productos/model/producto.dart';

import '../data/ventas_api.dart';
import '../model/detalle_venta_request.dart';
import '../model/venta_request.dart';

import 'carrito_venta_page.dart';
import 'comprobante_page.dart';
import 'ventas_page.dart';

class NuevaVentaPage extends StatefulWidget {
  const NuevaVentaPage({super.key});

  @override
  State<NuevaVentaPage> createState() => _NuevaVentaPageState();
}

class _NuevaVentaPageState extends State<NuevaVentaPage> {
  final storage = TokenStorage();

  List<Producto> productos = [];
  List<Cliente> clientes = [];
  List<ItemCarrito> carrito = [];

  Cliente? clienteSeleccionado;
  String tipoPago = "EFECTIVO";
  String busqueda = "";

  bool loading = true;
  bool cargandoClientes = true;
  bool procesandoVenta = false;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final empresaId = await storage.getEmpresaId();
      final client = ApiClient(storage: storage);

      final productosApi = ProductosApi(client);
      final clientesApi = ClientesApi(client);

      final resultados = await Future.wait([
        productosApi.listarEmpresa(empresaId ?? ""),
        clientesApi.listarEmpresa(empresaId ?? ""),
      ]);

      if (!mounted) return;

      setState(() {
        productos = resultados[0] as List<Producto>;
        clientes = resultados[1] as List<Cliente>;
        loading = false;
        cargandoClientes = false;
      });
    } catch (e) {
      debugPrint("ERROR CARGANDO DATOS VENTA: $e");
      if (!mounted) return;
      setState(() {
        loading = false;
        cargandoClientes = false;
      });
    }
  }

  List<Producto> get filtrados {
    if (busqueda.trim().isEmpty) {
      return productos.where((p) => p.activo).toList();
    }

    final query = busqueda.toLowerCase().trim();
    return productos.where((p) {
      return p.activo &&
          (p.nombre.toLowerCase().contains(query) ||
              p.codigo.toLowerCase().contains(query));
    }).toList();
  }

  void agregarProducto(Producto producto) {
    final existeIndex = carrito.indexWhere((e) => e.producto.id == producto.id);

    if (existeIndex >= 0) {
      setState(() {
        carrito[existeIndex].cantidad++;
      });
    } else {
      setState(() {
        carrito.add(ItemCarrito(producto: producto, cantidad: 1));
      });
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${producto.nombre} agregado al carrito"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double get total {
    double suma = 0;
    for (final item in carrito) {
      suma += item.subtotal;
    }
    return suma;
  }

  int get totalUnidades {
    int suma = 0;
    for (final item in carrito) {
      suma += item.cantidad;
    }
    return suma;
  }

  Future<void> abrirCarrito() async {
    final resultado = await CarritoVentaPage.mostrar(context, carrito: carrito);
    if (resultado != null) {
      setState(() {
        carrito = resultado;
      });
    }
  }

  String _formatearMonto(double monto) {
    final numero = monto.toInt();
    return "Gs. ${numero.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}";
  }

  String _obtenerNombrePago(String clave) {
    switch (clave) {
      case "TRANSFERENCIA":
        return "Transferencia Bancaria";
      case "CUENTA_CORRIENTE":
        return "Crédito (Cuenta Corriente)";
      default:
        return "Efectivo";
    }
  }

  Future<void> _mostrarDialogoError(String titulo, String mensaje) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 40,
            ),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Entendido",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmarVenta() async {
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Agregue productos al carrito antes de continuar"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildModalPrevisualizacion(ctx),
    );

    if (confirmado == true) {
      await _procesarVentaEnBackend();
    }
  }

  Widget _buildModalPrevisualizacion(BuildContext ctx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final nombreCliente = clienteSeleccionado != null
        ? "${clienteSeleccionado!.nombre} ${clienteSeleccionado!.apellido ?? ''}"
        : "Consumidor Final";

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFFE0EDFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fact_check_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Resumen de Venta",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "MONTO TOTAL A COBRAR",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatearMonto(total),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildFilaResumen(
                          Icons.person_outline_rounded,
                          "Cliente:",
                          nombreCliente,
                          textPrimary,
                          textSecondary,
                        ),
                        const Divider(height: 16),
                        _buildFilaResumen(
                          Icons.payments_outlined,
                          "Método de Pago:",
                          _obtenerNombrePago(tipoPago),
                          textPrimary,
                          textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Productos Seleccionados ($totalUnidades)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: carrito.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = carrito[idx];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "${item.cantidad}x",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.producto.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              _formatearMonto(item.subtotal),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Volver",
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Emitir Ticket",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaResumen(
    IconData icon,
    String titulo,
    String valor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 8),
        Text(titulo, style: TextStyle(fontSize: 12, color: textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _procesarVentaEnBackend() async {
    setState(() {
      procesandoVenta = true;
    });

    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();
      final usuarioId = await storage.getUsuarioId();

      if (empresaId == null || sucursalId == null || usuarioId == null) {
        setState(() {
          procesandoVenta = false;
        });
        await _mostrarDialogoError(
          "Sesión Inválida",
          "Los datos de la sesión están incompletos. Reinicie su sesión.",
        );
        return;
      }

      final request = VentaRequest(
        empresaId: empresaId,
        sucursalId: sucursalId,
        usuarioId: usuarioId,
        clienteId: clienteSeleccionado?.id,
        tipoPago: tipoPago,
        observacion: "",
        detalles: carrito
            .map(
              (e) => DetalleVentaRequest(
                productoId: e.producto.id,
                cantidad: e.cantidad,
              ),
            )
            .toList(),
      );

      final api = VentasApi(ApiClient(storage: storage));
      final venta = await api.crear(request);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ComprobantePage(ventaId: venta.id)),
      );
    } on DioException catch (e) {
      debugPrint("ERROR CREANDO VENTA DIO: $e");

      if (!mounted) return;

      setState(() {
        procesandoVenta = false;
      });

      String titulo = "Error al registrar venta";
      String detalle =
          "Ocurrió un error inesperado al procesar la venta en el servidor.";

      if (e.response?.data is Map) {
        final Map data = e.response!.data as Map;
        if (data.containsKey('title') && data['title'] != null) {
          titulo = data['title'].toString();
        }
        if (data.containsKey('detail') && data['detail'] != null) {
          detalle = data['detail'].toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        titulo = "Tiempo agotado";
        detalle = "No se pudo conectar con el servidor. Verifique su red.";
      }

      await _mostrarDialogoError(titulo, detalle);
    } catch (e) {
      debugPrint("ERROR CREANDO VENTA: $e");

      if (!mounted) return;

      setState(() {
        procesandoVenta = false;
      });

      await _mostrarDialogoError(
        "Error",
        "Ocurrió un problema no previsto: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final listaProductos = filtrados;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: carrito.isNotEmpty && !procesandoVenta
          ? FloatingActionButton.extended(
              onPressed: abrirCarrito,
              backgroundColor: primaryBlue,
              elevation: 4,
              icon: const Icon(
                Icons.shopping_cart_rounded,
                color: Colors.white,
              ),
              label: Text(
                "Carrito ($totalUnidades) • ${_formatearMonto(total)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                    : [const Color(0xFF246BFD), const Color(0xFF1B62D4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConfigVentaCard(
                            isDark,
                            cardBg,
                            textPrimary,
                            textSecondary,
                            primaryBlue,
                          ),
                          const SizedBox(height: 14),
                          _buildSearchBox(isDark, cardBg, textSecondary),
                          const SizedBox(height: 16),
                          loading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : listaProductos.isEmpty
                              ? _emptyState(
                                  textPrimary,
                                  textSecondary,
                                  primaryBlue,
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: listaProductos.length,
                                  itemBuilder: (context, index) {
                                    final p = listaProductos[index];
                                    return _buildProductoItem(
                                      producto: p,
                                      isDark: isDark,
                                      cardBg: cardBg,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      primaryBlue: primaryBlue,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (procesandoVenta) _buildProcesandoSplash(isDark, primaryBlue),
        ],
      ),
      bottomNavigationBar: carrito.isNotEmpty && !procesandoVenta
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: confirmarVenta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "CONFIRMAR VENTA (${_formatearMonto(total)})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProcesandoSplash(bool isDark, Color primaryBlue) {
    return Container(
      color: Colors.black.withOpacity(isDark ? 0.65 : 0.4),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Emitiendo comprobante...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Registrando venta en el sistema",
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "Nueva Venta",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: "Historial de ventas",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VentasPage()),
              );
            },
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: abrirCarrito,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                if (carrito.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$totalUnidades",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigVentaCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cliente",
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: _abrirSelectorClienteModal,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clienteSeleccionado != null
                          ? "${clienteSeleccionado!.nombre} ${clienteSeleccionado!.apellido ?? ''}"
                          : "Consumidor Final",
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Forma de Pago",
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildOpcionPago(
                "EFECTIVO",
                "Efectivo",
                Icons.payments_outlined,
                primaryBlue,
                isDark,
              ),
              const SizedBox(width: 6),
              _buildOpcionPago(
                "TRANSFERENCIA",
                "Transf.",
                Icons.account_balance_outlined,
                primaryBlue,
                isDark,
              ),
              const SizedBox(width: 6),
              _buildOpcionPago(
                "CUENTA_CORRIENTE",
                "Crédito",
                Icons.credit_card_outlined,
                primaryBlue,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionPago(
    String clave,
    String label,
    IconData icon,
    Color primaryBlue,
    bool isDark,
  ) {
    final seleccionado = tipoPago == clave;
    final bg = seleccionado
        ? primaryBlue.withOpacity(0.15)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final border = seleccionado
        ? primaryBlue
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            tipoPago = clave;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: seleccionado ? primaryBlue : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: seleccionado ? primaryBlue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSelectorClienteModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final sel = await showDialog<Cliente?>(
      context: context,
      builder: (context) {
        String filtro = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtrados = clientes.where((c) {
              final nombreCompleto = "${c.nombre} ${c.apellido ?? ''}"
                  .toLowerCase();
              return nombreCompleto.contains(filtro.toLowerCase()) ||
                  (c.documento ?? "").contains(filtro);
            }).toList();

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Seleccionar Cliente",
                style: TextStyle(fontSize: 16, color: textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Buscar cliente...",
                        hintStyle: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textSecondary,
                          size: 18,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() => filtro = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      dense: true,
                      title: Text(
                        "Consumidor Final",
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, null),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (ctx, idx) {
                          final item = filtrados[idx];
                          return ListTile(
                            dense: true,
                            title: Text(
                              "${item.nombre} ${item.apellido ?? ''}",
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: item.documento != null
                                ? Text(
                                    "Doc: ${item.documento}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    setState(() {
      clienteSeleccionado = sel;
    });
  }

  Widget _buildSearchBox(bool isDark, Color cardBg, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            busqueda = value;
          });
        },
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
          hintText: "Buscar producto por nombre o código...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: busqueda.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      busqueda = "";
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: textSecondary,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildProductoItem({
    required Producto producto,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Código: ${producto.codigo}",
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearMonto(producto.precioVenta ?? 0),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => agregarProducto(producto),
            icon: Icon(Icons.add_circle_rounded, color: primaryBlue, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    final buscando = busqueda.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.search_off_rounded, size: 36, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            buscando ? "No encontramos productos" : "Sin catálogo disponible",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            buscando
                ? "Probá con otro nombre o código."
                : "Asegúrate de tener productos registrados.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
