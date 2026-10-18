import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../../../features/catalogo/productos/data/productos_api.dart';
import '../../../features/catalogo/productos/model/producto.dart';
import '../../../features/sucursal/data/sucursales_api.dart';
import '../../../features/sucursal/model/sucursal.dart';

import '../data/stock_api.dart';
import '../model/stock_request.dart';

class StockFormPage extends StatefulWidget {
  const StockFormPage({super.key});

  /// Método estático para mostrar la vista como una ventana emergente / BottomSheet
  static Future<bool?> mostrar(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const StockFormPage(),
      ),
    );
  }

  @override
  State<StockFormPage> createState() => _StockFormPageState();
}

class _StockFormPageState extends State<StockFormPage> {
  final storage = TokenStorage();

  Producto? productoSeleccionado;
  Sucursal? sucursalSeleccionada;

  final cantidadController = TextEditingController();
  final minimoController = TextEditingController();

  List<Producto> productos = [];
  List<Sucursal> sucursales = [];

  bool guardando = false;
  bool cargandoListas = true;

  @override
  void initState() {
    super.initState();
    _cargarCombos();
  }

  @override
  void dispose() {
    cantidadController.dispose();
    minimoController.dispose();
    super.dispose();
  }

  Future<void> _cargarCombos() async {
    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null) {
        setState(() => cargandoListas = false);
        return;
      }

      final client = ApiClient(storage: storage);
      final prodApi = ProductosApi(client);
      final sucApi = SucursalesApi(client);

      final resultados = await Future.wait([
        prodApi.listarEmpresa(empresaId),
        sucApi.listarEmpresa(empresaId),
      ]);

      if (!mounted) return;

      setState(() {
        productos = resultados[0] as List<Producto>;
        sucursales = resultados[1] as List<Sucursal>;
        cargandoListas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => cargandoListas = false);
    }
  }

  // Diálogo Modal con Buscador Integrado para Productos/Sucursales
  Future<T?> _abrirSelectorBuscador<T>({
    required String titulo,
    required List<T> items,
    required String Function(T) itemLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return showDialog<T>(
      context: context,
      builder: (context) {
        String filtro = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtrados = items.where((i) {
              return itemLabel(i).toLowerCase().contains(filtro.toLowerCase());
            }).toList();

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                titulo,
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
                        hintText: "Buscar...",
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
                    Expanded(
                      child: filtrados.isEmpty
                          ? Center(
                              child: Text(
                                "Sin resultados",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtrados.length,
                              itemBuilder: (ctx, idx) {
                                final item = filtrados[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    itemLabel(item),
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
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
  }

  Future<void> guardar() async {
    if (productoSeleccionado == null ||
        sucursalSeleccionada == null ||
        cantidadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleccione producto, sucursal y cantidad"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null) {
        throw Exception("No existe empresa");
      }

      final request = StockRequest(
        empresaId: empresaId,
        sucursalId: sucursalSeleccionada!.id,
        productoId: productoSeleccionado!.id,
        cantidad: int.parse(cantidadController.text.trim()),
        stockMinimo: int.tryParse(minimoController.text.trim()) ?? 0,
      );

      final api = StockApi(ApiClient(storage: storage));
      await api.crear(request);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error guardando stock: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // Indicador Pill
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 12),

          // Header
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
                        Icons.inventory_2_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Nuevo registro de stock",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido Formulario
          cargandoListas
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectorButton(
                          label: "Producto *",
                          valor:
                              productoSeleccionado?.nombre ??
                              "Seleccionar producto",
                          icon: Icons.inventory_2_outlined,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () async {
                            final prod = await _abrirSelectorBuscador<Producto>(
                              titulo: "Seleccionar producto",
                              items: productos.where((p) => p.activo).toList(),
                              itemLabel: (p) => "${p.nombre} (${p.codigo})",
                            );
                            if (prod != null) {
                              setState(() => productoSeleccionado = prod);
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildSelectorButton(
                          label: "Sucursal *",
                          valor:
                              sucursalSeleccionada?.nombre ??
                              "Seleccionar sucursal",
                          icon: Icons.store_outlined,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () async {
                            final suc = await _abrirSelectorBuscador<Sucursal>(
                              titulo: "Seleccionar sucursal",
                              items: sucursales.where((s) => s.activo).toList(),
                              itemLabel: (s) => s.nombre,
                            );
                            if (suc != null) {
                              setState(() => sucursalSeleccionada = suc);
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _campoNumero(
                                label: "Cantidad inicial *",
                                hint: "Ej. 10",
                                controller: cantidadController,
                                inputBg: inputBg,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _campoNumero(
                                label: "Stock mínimo",
                                hint: "Ej. 2",
                                controller: minimoController,
                                inputBg: inputBg,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Cancelar",
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: guardando ? null : guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: guardando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Guardar stock",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required String label,
    required String valor,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, color: textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _campoNumero({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 13, color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary, fontSize: 12),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
