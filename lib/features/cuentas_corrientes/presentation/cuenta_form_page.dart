import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../../clientes/data/clientes_api.dart';
import '../../clientes/model/cliente.dart';

import '../data/cuentas_api.dart';
import '../model/cuenta_request.dart';

class CuentaFormPage extends StatefulWidget {
  const CuentaFormPage({super.key});

  /// Invoca la creación como ventana emergente (Bottom Sheet)
  static Future<bool?> mostrar(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const CuentaFormPage(),
      ),
    );
  }

  @override
  State<CuentaFormPage> createState() => _CuentaFormPageState();
}

class _CuentaFormPageState extends State<CuentaFormPage> {
  final storage = TokenStorage();

  List<Cliente> clientes = [];
  Cliente? clienteSeleccionado;

  final limiteController = TextEditingController();

  bool loading = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  @override
  void dispose() {
    limiteController.dispose();
    super.dispose();
  }

  Future<void> cargarClientes() async {
    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null) {
        if (mounted) setState(() => loading = false);
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
      debugPrint("ERROR CLIENTES CUENTA: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<Cliente?> _abrirSelectorCliente() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return showDialog<Cliente>(
      context: context,
      builder: (context) {
        String filtro = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtrados = clientes.where((c) {
              final nombreCompleto = "${c.nombre} ${c.apellido ?? ''}"
                  .toLowerCase();
              return nombreCompleto.contains(filtro.toLowerCase()) ||
                  (c.documento ?? "").contains(filtro);
            }).toList();

            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Seleccionar Cliente",
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
                        hintText: "Buscar cliente...",
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
                                    "${item.nombre} ${item.apellido ?? ''}",
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: item.documento != null
                                      ? Text(
                                          "CI/RUC: ${item.documento}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        )
                                      : null,
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
    if (clienteSeleccionado == null) {
      error("Seleccione un cliente");
      return;
    }

    final limiteTexto = limiteController.text
        .trim()
        .replaceAll(".", "")
        .replaceAll(",", ".");
    if (limiteTexto.isEmpty) {
      error("Ingrese un límite de crédito");
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null) {
        throw Exception("No existe ID de empresa");
      }

      final request = CuentaRequest(
        empresaId: empresaId,
        clienteId: clienteSeleccionado!.id,
        limiteCredito: double.parse(limiteTexto),
      );

      final api = CuentasApi(ApiClient(storage: storage));
      await api.crear(request);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("ERROR CREANDO CUENTA: $e");
      error("No se pudo crear la cuenta corriente");
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  void error(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
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
                        Icons.account_balance_wallet_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Nueva Cuenta Corriente",
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

          // Formulario
          loading
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
                          label: "Cliente *",
                          valor: clienteSeleccionado != null
                              ? "${clienteSeleccionado!.nombre} ${clienteSeleccionado!.apellido ?? ''}"
                              : "Seleccione un cliente",
                          icon: Icons.person_outline_rounded,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onTap: () async {
                            final sel = await _abrirSelectorCliente();
                            if (sel != null) {
                              setState(() => clienteSeleccionado = sel);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "Límite de crédito (Gs.) *",
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
                            controller: limiteController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: "Ej. 1.500.000",
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: textSecondary,
                                size: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botones
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
                                        "Crear cuenta",
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
}
