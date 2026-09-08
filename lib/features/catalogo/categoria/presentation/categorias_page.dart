import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/categorias_api.dart';
import '../model/categoria.dart';
import 'categoria_form_page.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final storage = TokenStorage();

  List<Categoria> categorias = [];
  List<Categoria> categoriasFiltradas = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> cargarCategorias() async {
    setState(() {
      loading = true;
    });

    final empresaId = await storage.getEmpresaId();

    if (empresaId == null || empresaId.isEmpty) {
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      final api = CategoriasApi(ApiClient(storage: storage));
      final resultado = await api.listarEmpresa(empresaId);

      if (!mounted) return;

      setState(() {
        categorias = resultado;
        categoriasFiltradas = resultado;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  void _filtrarCategorias(String query) {
    setState(() {
      if (query.isEmpty) {
        categoriasFiltradas = categorias;
      } else {
        categoriasFiltradas = categorias
            .where(
              (c) =>
                  c.nombre.toLowerCase().contains(query.toLowerCase()) ||
                  (c.descripcion != null &&
                      c.descripcion!.toLowerCase().contains(
                        query.toLowerCase(),
                      )),
            )
            .toList();
      }
    });
  }

  Future<void> eliminar(Categoria categoria) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Eliminar categoría",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Text(
            "¿Estás seguro de eliminar la categoría \"${categoria.nombre}\"?",
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Eliminar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final api = CategoriasApi(ApiClient(storage: storage));
    await api.eliminar(categoria.id);
    cargarCategorias();
  }

  Future<void> abrirFormulario({Categoria? categoria}) async {
    final result = await CategoriaFormPage.mostrar(
      context,
      categoria: categoria,
    );

    if (result == true) {
      cargarCategorias(); // Refresca la lista al guardar o editar
    }
  }

  // Generador de íconos y colores según el tipo/nombre de la categoría
  Map<String, dynamic> _getCategoryStyle(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.contains('alimento') || lower.contains('comida')) {
      return {
        'icon': Icons.shopping_cart_outlined,
        'bg': const Color(0xFFE0EDFF),
        'color': const Color(0xFF2563EB),
      };
    } else if (lower.contains('bebida') ||
        lower.contains('jugo') ||
        lower.contains('liquido')) {
      return {
        'icon': Icons.local_drink_outlined,
        'bg': const Color(0xFFDCFCE7),
        'color': const Color(0xFF16A34A),
      };
    } else if (lower.contains('limpieza') || lower.contains('aseo')) {
      return {
        'icon': Icons.cleaning_services_outlined,
        'bg': const Color(0xFFFEF3C7),
        'color': const Color(0xFFD97706),
      };
    } else if (lower.contains('cuidado') ||
        lower.contains('personal') ||
        lower.contains('higiene')) {
      return {
        'icon': Icons.soap_outlined,
        'bg': const Color(0xFFF3E8FF),
        'color': const Color(0xFF9333EA),
      };
    } else if (lower.contains('hogar') || lower.contains('casa')) {
      return {
        'icon': Icons.home_outlined,
        'bg': const Color(0xFFFFE4E6),
        'color': const Color(0xFFE11D48),
      };
    } else if (lower.contains('mascota') ||
        lower.contains('perro') ||
        lower.contains('gato')) {
      return {
        'icon': Icons.pets_outlined,
        'bg': const Color(0xFFFFEDD5),
        'color': const Color(0xFFEA580C),
      };
    }

    return {
      'icon': Icons.category_outlined,
      'bg': const Color(0xFFE2E8F0),
      'color': const Color(0xFF64748B),
    };
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

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () => abrirFormulario(),
            backgroundColor: primaryBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Nueva categoría",
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

                // Contenedor principal blanco curvado
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
                      onRefresh: cargarCategorias,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card de resumen de categorías y filtro
                            _buildSummaryCard(
                              isDark,
                              cardBg,
                              textPrimary,
                              textSecondary,
                              primaryBlue,
                            ),

                            const SizedBox(height: 14),

                            // Campo de búsqueda
                            _buildSearchBox(isDark, cardBg, textSecondary),

                            const SizedBox(height: 16),

                            // Encabezado de columnas Categoria / Estado
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Categoría",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    "Estado",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Lista o estado de carga
                            loading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : categoriasFiltradas.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "No se encontraron categorías",
                                        style: TextStyle(color: textSecondary),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: categoriasFiltradas.length,
                                    itemBuilder: (context, index) {
                                      final categoria =
                                          categoriasFiltradas[index];
                                      return _buildCategoryItem(
                                        categoria: categoria,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      );
                                    },
                                  ),

                            if (!loading && categoriasFiltradas.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  "Mostrando 1 - ${categoriasFiltradas.length} de ${categorias.length} categorías",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
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
            "Categorías",
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
  // CARD TOTAL DE CATEGORÍAS
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
              Icons.local_offer_rounded,
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
                  "Total de categorías",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  "${categorias.length}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  "categorías registradas",
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(Icons.filter_list_rounded, size: 16, color: primaryBlue),
            label: Text(
              "Filtrar",
              style: TextStyle(fontSize: 12, color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRA DE BÚSQUEDA
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
        onChanged: _filtrarCategorias,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
          hintText: "Buscar categoría...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // ÍTEM DE CATEGORÍA
  // ============================================================

  Widget _buildCategoryItem({
    required Categoria categoria,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final style = _getCategoryStyle(categoria.nombre);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          // Ícono cuadrado redondeado
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? (style['bg'] as Color).withOpacity(0.15)
                  : style['bg'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              style['icon'] as IconData,
              color: style['color'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Título y Descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  categoria.descripcion ?? "Sin descripción",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),

          // Tag Estado Activa / Inactiva
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  "Activa",
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Menú desplegable de 3 puntos (Editar/Eliminar)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                abrirFormulario(categoria: categoria);
              } else if (value == 'delete') {
                eliminar(categoria);
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
    );
  }
}
