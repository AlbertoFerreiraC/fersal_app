import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';
import '../data/compras_api.dart';
import '../model/compra_model.dart';
import 'nueva_compra_page.dart';

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final storage = TokenStorage();
  final searchController = TextEditingController();

  List<CompraModel> compras = [];
  List<CompraModel> filtradas = [];
  bool loading = true;

  static final NumberFormat _moneda = NumberFormat.currency(
    locale: 'es_PY',
    symbol: 'Gs. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    cargarCompras();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarCompras() async {
    setState(() => loading = true);
    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();

      if (empresaId == null || empresaId.isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final api = ComprasApi(ApiClient(storage: storage));
      final resultado = await api.listarPorEmpresaYSucursal(
        empresaId: empresaId,
        sucursalId: sucursalId,
      );

      if (!mounted) return;
      setState(() {
        compras = resultado;
        filtradas = resultado;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR CARGANDO COMPRAS: $e");
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar las compras"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void buscar(String texto) {
    setState(() {
      final q = texto.toLowerCase().trim();
      if (q.isEmpty) {
        filtradas = compras;
      } else {
        filtradas = compras.where((c) {
          return c.proveedor.toLowerCase().contains(q) ||
              (c.numeroFactura ?? '').toLowerCase().contains(q) ||
              c.condicionPago.toLowerCase().contains(q);
        }).toList();
      }
    });
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevaCompraPage()),
          );
          if (res == true) cargarCompras();
        },
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
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
                        "Compras y Proveedores",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      onRefresh: cargarCompras,
                      color: primaryBlue,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
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
                                  icon: Icon(
                                    Icons.search_rounded,
                                    color: textSecondary,
                                    size: 20,
                                  ),
                                  hintText: "Buscar por proveedor o factura...",
                                  hintStyle: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            loading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : filtradas.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 60,
                                      ),
                                      child: Text(
                                        "No hay compras registradas",
                                        style: TextStyle(color: textSecondary),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filtradas.length,
                                    itemBuilder: (context, index) {
                                      final c = filtradas[index];
                                      final esCredito =
                                          c.condicionPago == 'CREDITO';

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFF1F5F9),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: esCredito
                                                    ? (isDark
                                                          ? const Color(
                                                              0xFF451A03,
                                                            )
                                                          : const Color(
                                                              0xFFFFE8E8,
                                                            ))
                                                    : (isDark
                                                          ? const Color(
                                                              0xFF064E3B,
                                                            )
                                                          : const Color(
                                                              0xFFDCFCE7,
                                                            )),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                esCredito
                                                    ? Icons.credit_score_rounded
                                                    : Icons
                                                          .shopping_bag_outlined,
                                                color: esCredito
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF10B981),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c.proveedor,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Fac: ${c.numeroFactura ?? 'S/N'} • ${c.condicionPago}",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                  if (c.fecha != null)
                                                    Text(
                                                      DateFormat(
                                                        'dd/MM/yyyy HH:mm',
                                                      ).format(c.fecha!),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _moneda.format(c.total),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
