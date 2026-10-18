import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../../../features/catalogo/productos/data/productos_api.dart';
import '../../../features/catalogo/productos/model/producto.dart';

class SeleccionarProductoPage extends StatefulWidget {
  const SeleccionarProductoPage({super.key});

  @override
  State<SeleccionarProductoPage> createState() =>
      _SeleccionarProductoPageState();
}

class _SeleccionarProductoPageState extends State<SeleccionarProductoPage> {
  final storage = TokenStorage();

  List<Producto> productos = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    cargar();
  }

  Future<void> cargar() async {
    final empresaId = await storage.getEmpresaId();

    if (empresaId == null) return;

    try {
      final api = ProductosApi(ApiClient(storage: storage));

      final resultado = await api.listarEmpresa(empresaId);

      if (!mounted) return;

      setState(() {
        productos = resultado;

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar producto"),

        backgroundColor: const Color(0xFF1B62D4),

        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: productos.length,

              itemBuilder: (context, index) {
                final producto = productos[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),

                    title: Text(producto.nombre),

                    subtitle: Text(producto.codigo ?? ""),

                    onTap: () {
                      Navigator.pop(context, producto);
                    },
                  ),
                );
              },
            ),
    );
  }
}
