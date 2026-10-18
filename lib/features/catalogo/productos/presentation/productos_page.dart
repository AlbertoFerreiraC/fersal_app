import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/productos_api.dart';
import '../model/producto.dart';
import 'producto_form_page.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final storage = TokenStorage();

  List<Producto> productos = [];
  bool loading = true;
  String busqueda = "";

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarProductos() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    final empresaId = await storage.getEmpresaId();

    if (empresaId == null || empresaId.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      final apiClient = ApiClient(storage: storage);
      final api = ProductosApi(apiClient);
      final resultado = await api.listarEmpresa(empresaId);

      if (!mounted) return;

      setState(() {
        productos = resultado;
        loading = false;
      });
    } on DioException catch (e) {
      debugPrint("ERROR DIO PRODUCTOS: ${e.message}");
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error ${e.response?.statusCode ?? ''}: No se pudieron cargar productos",
          ),
        ),
      );
    } catch (e) {
      debugPrint("ERROR GENERAL PRODUCTOS: $e");
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudieron cargar los productos")),
      );
    }
  }

  List<Producto> get productosFiltrados {
    if (busqueda.trim().isEmpty) return productos;

    final texto = busqueda.toLowerCase().trim();
    return productos.where((producto) {
      return producto.nombre.toLowerCase().contains(texto) ||
          producto.codigo.toLowerCase().contains(texto) ||
          (producto.categoriaNombre ?? "").toLowerCase().contains(texto) ||
          (producto.proveedorNombre ?? "").toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> eliminarProducto(Producto producto) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Eliminar producto",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            "¿Querés eliminar \"${producto.nombre}\"?",
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final api = ProductosApi(ApiClient(storage: storage));
      await api.eliminar(producto.id);

      if (!mounted) return;

      setState(() {
        productos.removeWhere((item) => item.id == producto.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Producto eliminado correctamente"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("ERROR ELIMINANDO PRODUCTO: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo eliminar el producto"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> editarProducto(Producto producto) async {
    final result = await ProductoFormPage.mostrar(context, producto: producto);
    if (result == true) {
      await cargarProductos();
    }
  }

  Future<void> nuevoProducto() async {
    final result = await ProductoFormPage.mostrar(context);
    if (result == true) {
      await cargarProductos();
    }
  }

  String precio(double? valor) {
    if (valor == null) return "Gs. 0";
    final numero = valor.toInt();
    return "Gs. ${numero.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}";
  }

  String resolverImagenUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    String baseUrl = ApiClient(storage: storage).dio.options.baseUrl;
    if (baseUrl.endsWith("/api"))
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    if (url.startsWith("/")) return "$baseUrl$url";
    return "$baseUrl/$url";
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

    final lista = productosFiltrados;

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: nuevoProducto,
            backgroundColor: primaryBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Nuevo producto",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
        ],
      ),
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
                    child: RefreshIndicator(
                      onRefresh: cargarProductos,
                      color: primaryBlue,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(
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
                                : lista.isEmpty
                                ? _emptyState(
                                    textPrimary,
                                    textSecondary,
                                    primaryBlue,
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: lista.length,
                                    itemBuilder: (context, index) {
                                      final producto = lista[index];
                                      return _productoItem(
                                        producto: producto,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          ),
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
            "Productos",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0EDFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Catálogo de productos",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  "${productos.length}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  "productos registrados",
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        onChanged: (value) => setState(() => busqueda = value),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
          hintText: "Buscar producto...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: busqueda.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() => busqueda = "");
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

  Widget _productoItem({
    required Producto producto,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    return Dismissible(
      key: ValueKey(producto.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await eliminarProducto(producto);
          return false;
        }
        if (direction == DismissDirection.startToEnd) {
          await editarProducto(producto);
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "Editar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Eliminar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: Container(
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
            _imagenProducto(producto, isDark, primaryBlue),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (producto.categoriaNombre != null &&
                          producto.categoriaNombre!.isNotEmpty)
                        Flexible(
                          child: _tag(
                            producto.categoriaNombre!,
                            primaryBlue,
                            isDark,
                          ),
                        ),
                      if (producto.proveedorNombre != null &&
                          producto.proveedorNombre!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _tag(
                            producto.proveedorNombre!,
                            const Color(0xFF9333EA),
                            isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    precio(producto.precioVenta),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: producto.activo
                    ? (isDark
                          ? const Color(0xFF064E3B)
                          : const Color(0xFFDCFCE7))
                    : (isDark
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFFE8E8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: producto.activo
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    producto.activo ? "Activo" : "Inactivo",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: producto.activo
                          ? const Color(0xFF15803D)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  editarProducto(producto);
                } else if (value == 'delete') {
                  eliminarProducto(producto);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text("Editar"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text("Eliminar", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenProducto(Producto producto, bool isDark, Color primaryBlue) {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      final url = resolverImagenUrl(producto.imagenUrl!);

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderImagen(isDark, primaryBlue),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : Colors.black.withOpacity(.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryBlue,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _placeholderImagen(isDark, primaryBlue);
  }

  Widget _placeholderImagen(bool isDark, Color primaryBlue) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0EDFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.inventory_2_rounded, color: primaryBlue, size: 26),
    );
  }

  Widget _tag(String texto, Color color, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(.2) : color.withOpacity(.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? color.withOpacity(0.9) : color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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
            child: Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            buscando
                ? "No encontramos productos"
                : "Todavía no tenés productos",
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
                ? "Probá con otro nombre, código o categoría."
                : "Agregá tu primer producto para comenzar a vender.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
