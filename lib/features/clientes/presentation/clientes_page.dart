import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/clientes_api.dart';
import '../model/cliente.dart';
import 'cliente_form_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final storage = TokenStorage();

  List<Cliente> clientes = [];
  bool loading = true;
  String busqueda = "";

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarClientes() async {
    setState(() {
      loading = true;
    });

    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null) {
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final api = ClientesApi(ApiClient(storage: storage));
      final resultado = await api.listarEmpresa(empresaId);

      if (!mounted) return;

      setState(() {
        clientes = resultado;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR CLIENTES: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar los clientes"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Cliente> get filtrados {
    if (busqueda.trim().isEmpty) {
      return clientes;
    }

    final texto = busqueda.toLowerCase().trim();

    return clientes.where((c) {
      return c.nombre.toLowerCase().contains(texto) ||
          (c.apellido ?? "").toLowerCase().contains(texto) ||
          (c.documento ?? "").contains(texto) ||
          (c.telefono ?? "").contains(texto);
    }).toList();
  }

  Future<void> eliminar(Cliente cliente) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Eliminar cliente",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            '¿Desea eliminar al cliente "${cliente.nombre} ${cliente.apellido ?? ''}"?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ELIMINAR"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final api = ClientesApi(ApiClient(storage: storage));
      await api.eliminar(cliente.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cliente eliminado correctamente"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await cargarClientes();
    } catch (e) {
      debugPrint("ERROR ELIMINANDO: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo eliminar el cliente"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> nuevoCliente() async {
    final result = await ClienteFormPage.mostrar(context);

    if (result == true) {
      cargarClientes();
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    final result = await ClienteFormPage.mostrar(context, cliente: cliente);

    if (result == true) {
      cargarClientes();
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

    final lista = filtrados;

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: nuevoCliente,
            backgroundColor: primaryBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Nuevo cliente",
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
                      onRefresh: cargarClientes,
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

                            // Lista de clientes
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
                                      final cliente = lista[index];
                                      return _buildDismissibleCliente(
                                        cliente: cliente,
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
            "Clientes",
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
            child: Icon(Icons.people_alt_rounded, color: primaryBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Base de datos de Clientes",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  "${clientes.length}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  "clientes registrados",
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
          hintText: "Buscar cliente...",
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

  Widget _buildDismissibleCliente({
    required Cliente cliente,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    return Dismissible(
      key: ValueKey(cliente.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await eliminar(cliente);
          return false;
        }

        if (direction == DismissDirection.startToEnd) {
          await editarCliente(cliente);
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
      child: _clienteCard(
        cliente: cliente,
        isDark: isDark,
        cardBg: cardBg,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryBlue: primaryBlue,
      ),
    );
  }

  Widget _clienteCard({
    required Cliente cliente,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    final nombreCompleto = "${cliente.nombre} ${cliente.apellido ?? ''}".trim();

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
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_rounded, color: primaryBlue, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (cliente.documento != null && cliente.documento!.isNotEmpty)
                  _datoCliente(
                    Icons.badge_outlined,
                    "Doc: ${cliente.documento}",
                    textSecondary,
                  ),
                if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _datoCliente(
                      Icons.phone_outlined,
                      cliente.telefono!,
                      textSecondary,
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
              if (value == 'editar') {
                editarCliente(cliente);
              } else if (value == 'eliminar') {
                eliminar(cliente);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Editar"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
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

  Widget _datoCliente(IconData icon, String texto, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 13, color: textSecondary),
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
              Icons.people_alt_outlined,
              size: 36,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            buscando ? "No encontramos clientes" : "Todavía no tenés clientes",
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
                ? "Probá buscando por nombre, documento o teléfono."
                : "Agregá tu primer cliente para agilizar tus ventas.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
