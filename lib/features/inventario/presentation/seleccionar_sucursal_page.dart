import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../../../features/sucursal/data/sucursales_api.dart';
import '../../../features/sucursal/model/sucursal.dart';

class SeleccionarSucursalPage extends StatefulWidget {
  const SeleccionarSucursalPage({super.key});

  @override
  State<SeleccionarSucursalPage> createState() =>
      _SeleccionarSucursalPageState();
}

class _SeleccionarSucursalPageState extends State<SeleccionarSucursalPage> {
  final storage = TokenStorage();

  List<Sucursal> sucursales = [];

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
      final api = SucursalesApi(ApiClient(storage: storage));

      final resultado = await api.listarEmpresa(empresaId);

      setState(() {
        sucursales = resultado;

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
        title: const Text("Seleccionar sucursal"),

        backgroundColor: const Color(0xFF1B62D4),

        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: sucursales.length,

              itemBuilder: (context, index) {
                final sucursal = sucursales[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.store),

                    title: Text(sucursal.nombre),

                    onTap: () {
                      Navigator.pop(context, sucursal);
                    },
                  ),
                );
              },
            ),
    );
  }
}
