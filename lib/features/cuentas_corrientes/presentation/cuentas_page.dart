import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/cuentas_api.dart';
import '../model/cuenta_corriente.dart';
import 'cuenta_form_page.dart';

class CuentasPage extends StatefulWidget {
  const CuentasPage({super.key});

  @override
  State<CuentasPage> createState() => _CuentasPageState();
}

class _CuentasPageState extends State<CuentasPage> {
  final storage = TokenStorage();
  final searchController = TextEditingController();

  List<CuentaCorriente> cuentas = [];
  List<CuentaCorriente> filtradas = [];
  bool loading = true;
  bool _cargandoActualizacion = false;
  String busqueda = "";

  @override
  void initState() {
    super.initState();
    cargarCuentas();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> cargarCuentas({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        loading = true;
      });
    }

    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null || empresaId.isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final api = CuentasApi(ApiClient(storage: storage));
      final resultado = await api.listarEmpresa(empresaId);

      if (!mounted) return;

      setState(() {
        cuentas = resultado;
        _aplicarFiltro(busqueda);
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR CUENTAS: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar las cuentas corrientes"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _aplicarFiltro(String texto) {
    busqueda = texto;
    if (texto.trim().isEmpty) {
      filtradas = List.from(cuentas);
    } else {
      final query = texto.toLowerCase().trim();
      filtradas = cuentas.where((c) {
        final clienteCompleto = "${c.cliente} ${c.apellido ?? ''}"
            .toLowerCase();
        return clienteCompleto.contains(query);
      }).toList();
    }
  }

  void buscar(String texto) {
    setState(() {
      _aplicarFiltro(texto);
    });
  }

  Future<void> editarCredito(CuentaCorriente cuenta) async {
    final controller = TextEditingController(
      text: cuenta.limiteCredito.toInt().toString(),
    );

    final resultado = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _buildModalEditarLimite(cuenta, controller, ctx),
      ),
    );

    if (resultado == null) return;

    setState(() {
      _cargandoActualizacion = true;
    });

    try {
      final api = CuentasApi(ApiClient(storage: storage));
      await api.actualizarMonto(cuenta.id, resultado);

      await Future.delayed(const Duration(milliseconds: 600));
      await cargarCuentas(silencioso: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Límite de crédito actualizado correctamente"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("ERROR ACTUALIZANDO LÍMITE: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo actualizar el límite"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargandoActualizacion = false;
        });
      }
    }
  }

  Widget _buildModalEditarLimite(
    CuentaCorriente cuenta,
    TextEditingController controller,
    BuildContext modalContext,
  ) {
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
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                      Icons.edit_rounded,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Ajustar Límite de Crédito",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(modalContext),
                icon: Icon(Icons.close_rounded, color: textSecondary),
              ),
            ],
          ),
          const Divider(height: 16),
          const SizedBox(height: 8),
          Text(
            "Cliente: ${cuenta.cliente} ${cuenta.apellido ?? ''}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Saldo consumido actual: ${_formatearMonto(cuenta.saldo)}",
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            "Nuevo Límite de Crédito (Gs.) *",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "0",
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  color: primaryBlue,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(modalContext),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  onPressed: () {
                    final texto = controller.text
                        .trim()
                        .replaceAll(".", "")
                        .replaceAll(",", ".");
                    final nuevoMonto = double.tryParse(texto);

                    if (nuevoMonto == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ingrese un monto válido"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(modalContext, nuevoMonto);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Guardar límite",
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
    );
  }

  Future<void> eliminar(CuentaCorriente cuenta) async {
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
            "Eliminar cuenta",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            '¿Desea eliminar la cuenta corriente de "${cuenta.cliente}"?',
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

    setState(() {
      _cargandoActualizacion = true;
    });

    try {
      final api = CuentasApi(ApiClient(storage: storage));
      await api.eliminar(cuenta.id);

      await Future.delayed(const Duration(milliseconds: 500));
      await cargarCuentas(silencioso: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cuenta corriente eliminada"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("ERROR ELIMINANDO CUENTA: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo eliminar la cuenta"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargandoActualizacion = false;
        });
      }
    }
  }

  Future<void> nuevaCuenta() async {
    final result = await CuentaFormPage.mostrar(context);
    if (result == true) {
      cargarCuentas();
    }
  }

  String _formatearMonto(double monto) {
    final numero = monto.toInt();
    return "Gs. ${numero.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}";
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
            onPressed: nuevaCuenta,
            backgroundColor: primaryBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "Nueva cuenta",
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
                      onRefresh: cargarCuentas,
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
                                      final cuenta = lista[index];
                                      return _buildDismissibleCuenta(
                                        cuenta: cuenta,
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
          if (_cargandoActualizacion) _buildLoadingSplash(isDark, primaryBlue),
        ],
      ),
    );
  }

  Widget _buildLoadingSplash(bool isDark, Color primaryBlue) {
    return Container(
      color: Colors.black.withOpacity(isDark ? 0.65 : 0.4),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Procesando cambios...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Refrescando cuentas corrientes",
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
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
            "Cuentas Corrientes",
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
    double totalSaldo = 0;
    for (var c in cuentas) {
      totalSaldo += c.saldo;
    }

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
              Icons.account_balance_wallet_rounded,
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
                  "Saldo Total por Cobrar",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatearMonto(totalSaldo),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  "${cuentas.length} cuentas registradas",
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
        onChanged: buscar,
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

  Widget _buildDismissibleCuenta({
    required CuentaCorriente cuenta,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    return Dismissible(
      key: ValueKey(cuenta.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await eliminar(cuenta);
          return false;
        }

        if (direction == DismissDirection.startToEnd) {
          await editarCredito(cuenta);
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
      child: _cardCuenta(
        cuenta: cuenta,
        isDark: isDark,
        cardBg: cardBg,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryBlue: primaryBlue,
      ),
    );
  }

  Widget _cardCuenta({
    required CuentaCorriente cuenta,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
  }) {
    final limiteSaturado =
        cuenta.saldo >= cuenta.limiteCredito && cuenta.limiteCredito > 0;
    final nombreCompleto = "${cuenta.cliente} ${cuenta.apellido ?? ''}".trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFE0EDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCompleto,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cuenta.telefono != null &&
                            cuenta.telefono!.isNotEmpty)
                          Text(
                            "📱 ${cuenta.telefono}",
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        Text(
                          "Cuenta corriente activa",
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: primaryBlue, size: 20),
                onPressed: () => editarCredito(cuenta),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () => eliminar(cuenta),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _datoItem(
                  "Saldo Actual",
                  _formatearMonto(cuenta.saldo),
                  limiteSaturado ? const Color(0xFFEF4444) : primaryBlue,
                  isDark,
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                _datoItem(
                  "Límite Crédito",
                  _formatearMonto(cuenta.limiteCredito),
                  textSecondary,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoItem(String titulo, String valor, Color valorColor, bool isDark) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valorColor,
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
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            buscando
                ? "No encontramos cuentas"
                : "Aún no hay cuentas corrientes",
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
                ? "Probá buscando por otro cliente."
                : "Agregá la línea de crédito de tu primer cliente.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
