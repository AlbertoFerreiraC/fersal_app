import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/ventas_api.dart';
import '../model/venta.dart';
import 'comprobante_page.dart';
import 'nueva_venta_page.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final storage = TokenStorage();

  List<Venta> ventas = [];
  List<Venta> filtradas = [];
  bool loading = true;
  String busqueda = "";

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarVentas();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarVentas() async {
    setState(() {
      loading = true;
    });

    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();

      if (empresaId == null || empresaId.isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final api = VentasApi(ApiClient(storage: storage));
      final resultado = await api.listarPorEmpresaYSucursal(
        empresaId: empresaId,
        sucursalId: sucursalId,
      );

      if (!mounted) return;

      setState(() {
        ventas = resultado;
        filtradas = resultado;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR VENTAS: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar las ventas"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void buscar(String texto) {
    setState(() {
      busqueda = texto;
      if (texto.trim().isEmpty) {
        filtradas = ventas;
      } else {
        final query = texto.toLowerCase().trim();
        filtradas = ventas.where((v) {
          return v.numero.toLowerCase().contains(query) ||
              v.cliente.toLowerCase().contains(query) ||
              v.estado.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String formatoMonto(double monto) {
    return "Gs. ${monto.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}";
  }

  Future<void> nuevaVenta() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NuevaVentaPage()),
    );
    cargarVentas();
  }

  Future<void> _anularVenta(Venta venta) async {
    final controller = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Anular venta"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Motivo de anulación"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Anular"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final usuarioId = await storage.getUsuarioId();
    if (usuarioId == null) return;

    try {
      final api = VentasApi(ApiClient(storage: storage));

      await api.anular(
        venta.id,
        usuarioId,
        controller.text.isEmpty ? "Sin motivo" : controller.text,
      );

      cargarVentas();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venta anulada correctamente")),
      );
    } catch (e) {
      debugPrint("ERROR ANULAR VENTA: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo anular la venta")),
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

    final lista = filtradas;

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: nuevaVenta,
            backgroundColor: primaryBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Nueva venta",
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
                      onRefresh: cargarVentas,
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
                                      final venta = lista[index];
                                      return _ventaCard(
                                        venta: venta,
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
            "Ventas",
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
    double totalContado = 0;
    double totalCredito = 0;
    double facturadoTotal = 0;

    for (var v in ventas) {
      final tipo = v.tipoPago.toUpperCase();
      final estado = v.estado.toUpperCase();

      final esCredito =
          tipo.contains("CREDITO") ||
          tipo.contains("CRÉDITO") ||
          tipo.contains("CUENTA_CORRIENTE") ||
          estado.contains("PENDIENTE") ||
          estado.contains("DEUDA");

      if (esCredito) {
        totalCredito += v.total;
      } else {
        totalContado += v.total;
      }
      facturadoTotal += v.total;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_rounded, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Resumen de Ventas",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${ventas.length} transacciones",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTAL FACTURADO (BRUTO)",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatoMonto(facturadoTotal),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  titulo: "Total Contado",
                  monto: totalContado,
                  colorIcono: const Color(0xFF15803D),
                  bgColorIcono: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFDCFCE7),
                  icono: Icons.payments_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  titulo: "Crédito (Fiado)",
                  monto: totalCredito,
                  colorIcono: const Color(0xFFDC2626),
                  bgColorIcono: isDark
                      ? const Color(0xFF451A03)
                      : const Color(0xFFFFE8E8),
                  icono: Icons.credit_card_rounded,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String titulo,
    required double monto,
    required Color colorIcono,
    required Color bgColorIcono,
    required IconData icono,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColorIcono.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorIcono.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColorIcono,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: colorIcono, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatoMonto(monto),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
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
        onChanged: buscar,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
          hintText: "Buscar por comprobante o cliente...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: busqueda.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    buscar("");
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

  Widget _ventaCard({
    required Venta venta,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
    required bool isDark,
  }) {
    final estado = venta.estado.toUpperCase();
    final pendiente = estado.contains("PENDIENTE");
    final anulada = estado.contains("ANULADA");

    return InkWell(
      onTap: anulada
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ComprobantePage(ventaId: venta.id),
                ),
              );
            },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: anulada
                ? Colors.red.withOpacity(0.3)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: anulada
                        ? Colors.red.withOpacity(0.15)
                        : (isDark
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFE0EDFF)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    anulada
                        ? Icons.cancel_outlined
                        : Icons.receipt_long_rounded,
                    color: anulada ? Colors.red : primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.numero,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        venta.cliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatoMonto(venta.total),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: anulada ? Colors.grey : primaryBlue,
                      ),
                    ),
                    if (!anulada)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == "anular") {
                            _anularVenta(venta);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: "anular",
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text("Anular venta"),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      venta.tipoPago,
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: anulada
                        ? Colors.red.withOpacity(0.15)
                        : pendiente
                        ? (isDark
                              ? const Color(0xFF451A03)
                              : const Color(0xFFFFE8E8))
                        : (isDark
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    venta.estado,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: anulada
                          ? Colors.red
                          : pendiente
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
              Icons.receipt_long_outlined,
              size: 36,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            buscando
                ? "No encontramos ventas"
                : "Aún no hay ventas registradas",
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
                ? "Probá buscando por comprobante o cliente."
                : "Generá tu primera venta para comenzar.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
