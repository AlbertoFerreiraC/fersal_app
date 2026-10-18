import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../features/catalogo/productos/data/productos_api.dart';
import '../../../features/catalogo/productos/model/producto.dart';
import '../../../features/catalogo/proveedor/data/proveedores_api.dart';
import '../../../features/catalogo/proveedor/model/proveedor.dart';
import '../data/compras_api.dart';
import '../model/compra_model.dart';

class ItemCompraTemp {
  final Producto producto;
  int cantidad;
  double precioUnitario;

  ItemCompraTemp({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class NuevaCompraPage extends StatefulWidget {
  const NuevaCompraPage({super.key});

  @override
  State<NuevaCompraPage> createState() => _NuevaCompraPageState();
}

class _NuevaCompraPageState extends State<NuevaCompraPage> {
  final storage = TokenStorage();
  final facturaController = TextEditingController();
  final obsController = TextEditingController();

  List<Proveedor> proveedores = [];
  List<Producto> productos = [];
  List<ItemCompraTemp> items = [];

  Proveedor? proveedorSeleccionado;
  String condicionPago = "CONTADO"; // CONTADO o CREDITO
  bool pagarDesdeCaja = true;

  bool cargando = true;
  bool guardando = false;

  static final NumberFormat _moneda = NumberFormat.currency(
    locale: 'es_PY',
    symbol: 'Gs. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    facturaController.dispose();
    obsController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final empresaId = await storage.getEmpresaId();
      if (empresaId == null) return;

      final client = ApiClient(storage: storage);
      final provApi = ProveedoresApi(client);
      final prodApi = ProductosApi(client);

      final resultados = await Future.wait([
        provApi.listarEmpresa(empresaId),
        prodApi.listarEmpresa(empresaId),
      ]);

      if (!mounted) return;
      setState(() {
        proveedores = resultados[0] as List<Proveedor>;
        productos = (resultados[1] as List<Producto>)
            .where((p) => p.activo)
            .toList();
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
    }
  }

  double get total => items.fold(0.0, (acc, item) => acc + item.subtotal);

  void _agregarProductoModal() {
    Producto? seleccionado;
    final cantCtrl = TextEditingController(text: "1");
    final precioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Agregar Producto"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Producto>(
                    value: seleccionado,
                    hint: const Text("Seleccionar producto"),
                    isExpanded: true,
                    items: productos.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.nombre));
                    }).toList(),
                    onChanged: (p) {
                      setDialogState(() {
                        seleccionado = p;
                        if (p?.precioCompra != null) {
                          precioCtrl.text = p!.precioCompra!.toInt().toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Cantidad"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Costo Unitario (Gs.)",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (seleccionado == null) return;
                    final cant = int.tryParse(cantCtrl.text.trim()) ?? 0;
                    final costo =
                        double.tryParse(
                          precioCtrl.text.replaceAll('.', '').trim(),
                        ) ??
                        0.0;
                    if (cant <= 0 || costo <= 0) return;

                    setState(() {
                      items.add(
                        ItemCompraTemp(
                          producto: seleccionado!,
                          cantidad: cant,
                          precioUnitario: costo,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("Agregar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _guardarCompra() async {
    if (proveedorSeleccionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Seleccione un proveedor")));
      return;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Agregue al menos un producto a la compra"),
        ),
      );
      return;
    }

    setState(() => guardando = true);
    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();
      final usuarioId = await storage.getUsuarioId();

      if (empresaId == null || sucursalId == null || usuarioId == null) {
        throw Exception("Datos de sesión no encontrados");
      }

      final req = CompraRequest(
        empresaId: empresaId,
        sucursalId: sucursalId,
        usuarioId: usuarioId,
        proveedorId: proveedorSeleccionado!.id,
        numeroFactura: facturaController.text.trim().isEmpty
            ? null
            : facturaController.text.trim(),
        condicionPago: condicionPago,
        pagarDesdeCaja: pagarDesdeCaja,
        observacion: obsController.text.trim(),
        detalles: items.map((i) {
          return DetalleCompraItemRequest(
            productoId: i.producto.id,
            cantidad: i.cantidad,
            precioUnitario: i.precioUnitario,
          );
        }).toList(),
      );

      final api = ComprasApi(ApiClient(storage: storage));
      await api.registrar(req);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compra registrada y stock actualizado")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("ERROR GUARDANDO COMPRA: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error al guardar compra: $e")));
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Compra"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Proveedor>(
                    value: proveedorSeleccionado,
                    hint: const Text("Seleccionar Proveedor *"),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: proveedores.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.nombre));
                    }).toList(),
                    onChanged: (p) => setState(() => proveedorSeleccionado = p),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: facturaController,
                    decoration: InputDecoration(
                      labelText: "Nº Factura de Proveedor",
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("CONTADO")),
                          selected: condicionPago == "CONTADO",
                          onSelected: (_) =>
                              setState(() => condicionPago = "CONTADO"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("CRÉDITO")),
                          selected: condicionPago == "CREDITO",
                          onSelected: (_) =>
                              setState(() => condicionPago = "CREDITO"),
                        ),
                      ),
                    ],
                  ),
                  if (condicionPago == "CONTADO") ...[
                    const SizedBox(height: 6),
                    SwitchListTile(
                      title: const Text("Pagar desde la caja del turno actual"),
                      value: pagarDesdeCaja,
                      onChanged: (val) => setState(() => pagarDesdeCaja = val),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Productos a Ingresar",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _agregarProductoModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Ítem"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.producto.nombre),
                          subtitle: Text(
                            "${item.cantidad} un. x ${_moneda.format(item.precioUnitario)}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _moneda.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => items.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TOTAL COMPRA:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _moneda.format(total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardando ? null : _guardarCompra,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "REGISTRAR COMPRA Y CARGAR STOCK",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
