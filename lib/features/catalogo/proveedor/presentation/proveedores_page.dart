import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/proveedores_api.dart';
import '../model/proveedor.dart';
import 'proveedor_form_page.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final TokenStorage storage = TokenStorage();
  final TextEditingController _searchController = TextEditingController();

  List<Proveedor> proveedores = [];
  bool loading = true;
  String busqueda = "";

  @override
  void initState() {
    super.initState();
    cargarProveedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR
  // ============================================================

  Future<void> cargarProveedores() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null || empresaId.isEmpty) {
        if (!mounted) return;

        setState(() {
          proveedores = [];
          loading = false;
        });

        return;
      }

      final api = ProveedoresApi(ApiClient(storage: storage));
      final resultado = await api.listarEmpresa(empresaId);

      if (!mounted) return;

      setState(() {
        proveedores = resultado;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR CARGANDO PROVEEDORES: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar los proveedores"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // FILTRO
  // ============================================================

  List<Proveedor> get proveedoresFiltrados {
    final texto = busqueda.trim().toLowerCase();

    if (texto.isEmpty) {
      return proveedores;
    }

    return proveedores.where((proveedor) {
      return proveedor.nombre.toLowerCase().contains(texto) ||
          (proveedor.ruc ?? "").toLowerCase().contains(texto) ||
          (proveedor.telefono ?? "").toLowerCase().contains(texto) ||
          (proveedor.email ?? "").toLowerCase().contains(texto);
    }).toList();
  }

  // ============================================================
  // MODALES (NUEVO Y EDITAR)
  // ============================================================

  Future<void> abrirNuevoProveedor() async {
    final result = await ProveedorFormPage.mostrar(context);

    if (result == true) {
      cargarProveedores();
    }
  }

  Future<void> editarProveedor(Proveedor proveedor) async {
    final result = await ProveedorFormPage.mostrar(
      context,
      proveedor: proveedor,
    );

    if (result == true) {
      cargarProveedores();
    }
  }

  // ============================================================
  // ELIMINAR
  // ============================================================

  Future<void> eliminarProveedor(Proveedor proveedor) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Eliminar proveedor",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            '¿Querés eliminar "${proveedor.nombre}"?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("ELIMINAR"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final api = ProveedoresApi(ApiClient(storage: storage));

      await api.eliminar(proveedor.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Proveedor eliminado correctamente"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await cargarProveedores();
    } catch (e) {
      debugPrint("ERROR ELIMINANDO PROVEEDOR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo eliminar el proveedor"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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

    final lista = proveedoresFiltrados;

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: abrirNuevoProveedor,
            backgroundColor: primaryBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Nuevo proveedor",
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
          // Fondo azul superior
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
                // AppBar Superior
                _buildAppBar(context),

                // Contenedor principal curvado
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
                      onRefresh: cargarProveedores,
                      color: primaryBlue,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card de resumen
                            _buildSummaryCard(
                              isDark,
                              cardBg,
                              textPrimary,
                              textSecondary,
                              primaryBlue,
                            ),

                            const SizedBox(height: 14),

                            // Campo de Búsqueda
                            _buildSearchBox(isDark, cardBg, textSecondary),

                            const SizedBox(height: 16),

                            // Contenido Principal
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
                                      final proveedor = lista[index];
                                      return _proveedorItem(
                                        proveedor: proveedor,
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

  // ============================================================
  // APP BAR SUPERIOR
  // ============================================================

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
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
            "Proveedores",
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
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE RESUMEN
  // ============================================================

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
              Icons.local_shipping_rounded,
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
                  "Gestioná tus proveedores",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  "${proveedores.length}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  "proveedores registrados",
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUSCADOR
  // ============================================================

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
        controller: _searchController,
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
          hintText: "Buscar proveedor...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: busqueda.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
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

  // ============================================================
  // ITEM PROVEEDOR
  // ============================================================

  Widget _proveedorItem({
    required Proveedor proveedor,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    return Dismissible(
      key: ValueKey(proveedor.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await eliminarProveedor(proveedor);
          return false;
        }

        if (direction == DismissDirection.startToEnd) {
          await editarProveedor(proveedor);
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
            // Icono del proveedor
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFE0EDFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.business_rounded, color: primaryBlue, size: 22),
            ),

            const SizedBox(width: 12),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proveedor.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if ((proveedor.ruc ?? "").isNotEmpty)
                    _datoProveedor(
                      Icons.badge_outlined,
                      "RUC: ${proveedor.ruc}",
                      textSecondary,
                    ),
                  if ((proveedor.telefono ?? "").isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _datoProveedor(
                        Icons.phone_outlined,
                        proveedor.telefono!,
                        textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: proveedor.activo
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
                      color: proveedor.activo
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    proveedor.activo ? "Activo" : "Inactivo",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: proveedor.activo
                          ? const Color(0xFF15803D)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),

            // Menú de opciones
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  editarProveedor(proveedor);
                } else if (value == 'delete') {
                  eliminarProveedor(proveedor);
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

  // ============================================================
  // DATO HELPER
  // ============================================================

  Widget _datoProveedor(IconData icon, String texto, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

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
            child: Icon(Icons.business_outlined, size: 36, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            buscando
                ? "No encontramos proveedores"
                : "Todavía no tenés proveedores",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            buscando ? "Probá con otro nombre, RUC, teléfono o email." : "Agregá tu primer proveedor para comenzar a organizar tus compras.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
