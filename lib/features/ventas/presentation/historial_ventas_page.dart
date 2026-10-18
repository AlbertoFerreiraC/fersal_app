import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../data/ventas_api.dart';
import '../model/venta.dart';
import 'comprobante_page.dart';

class HistorialVentasPage extends StatefulWidget {
  const HistorialVentasPage({super.key});

  @override
  State<HistorialVentasPage> createState() => _HistorialVentasPageState();
}

class _HistorialVentasPageState extends State<HistorialVentasPage> {
  final storage = TokenStorage();

  List<Venta> ventas = [];
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
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR HISTORIAL: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  List<Venta> get filtradas {
    if (busqueda.trim().isEmpty) {
      return ventas;
    }

    final q = busqueda.toLowerCase();

    return ventas.where((v) {
      return v.numero.toLowerCase().contains(q) ||
          v.cliente.toLowerCase().contains(q) ||
          v.estado.toLowerCase().contains(q);
    }).toList();
  }

  String formatoMonto(double monto) {
    return "Gs. ${monto.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => "${m.group(1)}.")}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primary = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1B62D4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text(
          "Historial de Ventas",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: cargarVentas,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (v) {
                  setState(() {
                    busqueda = v;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Buscar venta o cliente...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: filtradas.length,
                        itemBuilder: (context, index) {
                          final venta = filtradas[index];

                          return Card(
                            color: card,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primary,
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                venta.numero,
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                venta.cliente,
                                style: TextStyle(color: secondary),
                              ),
                              trailing: Text(
                                formatoMonto(venta.total),
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ComprobantePage(ventaId: venta.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
