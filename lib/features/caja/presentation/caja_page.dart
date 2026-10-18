import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/widgets/fersal_drawer.dart';

import '../data/caja_repository.dart';
import '../model/cierre_caja_model.dart';
import '../model/movimiento_caja_model.dart';
import 'widgets/apertura_modal.dart';
import 'widgets/arqueo_modal.dart';
import 'widgets/cierre_modal.dart';
import 'widgets/movimiento_modal.dart';

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage>
    with SingleTickerProviderStateMixin {
  final storage = TokenStorage();
  late final CajaRepository repository;

  late TabController tabController;
  final searchController = TextEditingController();

  List<MovimientoCajaModel> movimientos = [];
  List<MovimientoCajaModel> movimientosFiltrados = [];
  List<CierreCajaModel> cierres = [];
  List<CierreCajaModel> cierresFiltrados = [];

  CierreCajaModel? cajaAbiertaActual;
  bool loading = true;

  static final NumberFormat _moneda = NumberFormat.currency(
    locale: 'es_PY',
    symbol: 'Gs. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    repository = CajaRepository(ApiClient(storage: storage));
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() => setState(() {}));
    cargarDatos();
  }

  @override
  void dispose() {
    searchController.dispose();
    tabController.dispose();
    super.dispose();
  }

  bool get isCajaAbierta => cajaAbiertaActual != null;

  Future<void> cargarDatos() async {
    setState(() => loading = true);

    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();
      final usuarioId = await storage.getUsuarioId();

      if (empresaId == null || empresaId.isEmpty) {
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final movsFuture = repository.listarMovimientos(
        empresaId: empresaId,
        sucursalId: sucursalId,
        usuarioId: usuarioId,
      );
      final clsFuture = repository.listarCierres(
        empresaId: empresaId,
        sucursalId: sucursalId,
        usuarioId: usuarioId,
      );
      final estadoCajaFuture = (sucursalId != null && usuarioId != null)
          ? repository.obtenerCajaAbierta(
              empresaId: empresaId,
              sucursalId: sucursalId,
              usuarioId: usuarioId,
            )
          : Future.value(null);

      final resultados = await Future.wait([
        movsFuture,
        clsFuture,
        estadoCajaFuture,
      ]);

      final movs = resultados[0] as List<MovimientoCajaModel>;
      final cls = resultados[1] as List<CierreCajaModel>;
      final abierta = resultados[2] as CierreCajaModel?;

      movs.sort((a, b) {
        if (a.fecha == null && b.fecha == null) return 0;
        if (a.fecha == null) return 1;
        if (b.fecha == null) return -1;
        return b.fecha!.compareTo(a.fecha!);
      });

      cls.sort((a, b) {
        if (a.fecha == null && b.fecha == null) return 0;
        if (a.fecha == null) return 1;
        if (b.fecha == null) return -1;
        return b.fecha!.compareTo(a.fecha!);
      });

      if (!mounted) return;

      setState(() {
        cajaAbiertaActual = abierta;
        movimientos = movs;
        movimientosFiltrados = movimientos;

        cierres = cls;
        cierresFiltrados = cierres;

        loading = false;
      });
      buscar(searchController.text);
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar los registros de caja"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void buscar(String texto) {
    setState(() {
      final query = texto.toLowerCase();
      if (query.isEmpty) {
        movimientosFiltrados = movimientos;
        cierresFiltrados = cierres;
      } else {
        movimientosFiltrados = movimientos.where((m) {
          return m.descripcion.toLowerCase().contains(query) ||
              m.tipo.toLowerCase().contains(query) ||
              m.monto.toString().contains(query);
        }).toList();

        cierresFiltrados = cierres.where((c) {
          return (c.saldoFinal?.toString() ?? '').contains(query) ||
              (c.fecha?.toString() ?? '').contains(query);
        }).toList();
      }
    });
  }

  double get totalIngresos => movimientos
      .where((m) => m.tipo == 'INGRESO')
      .fold(0.0, (acc, item) => acc + item.monto);

  double get totalSalidas => movimientos
      .where((m) => m.tipo == 'SALIDA')
      .fold(0.0, (acc, item) => acc + item.monto);

  double get saldoActual => totalIngresos - totalSalidas;

  void _mostrarAvisoCajaCerrada() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Operación bloqueada: Primero debes ABRIR la caja para este turno",
        ),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleApertura(double monto) async {
    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();
      final usuarioId = await storage.getUsuarioId();

      if (empresaId == null || sucursalId == null || usuarioId == null) {
        throw Exception("Datos de sesión incompletos");
      }

      await repository.abrirCaja(
        empresaId: empresaId,
        sucursalId: sucursalId,
        usuarioId: usuarioId,
        saldoInicial: monto,
      );

      final reqMov = MovimientoCajaModel(
        empresaId: empresaId,
        sucursalId: sucursalId,
        usuarioId: usuarioId,
        tipo: 'INGRESO',
        monto: monto,
        descripcion: 'APERTURA DE CAJA',
      );
      await repository.registrarMovimiento(reqMov);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Caja abierta correctamente"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      cargarDatos();
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = "Error al abrir caja";
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        msg = e.response!.data['detail'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al abrir caja: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleMovimiento(String tipo, double monto, String desc) async {
    if (!isCajaAbierta) {
      _mostrarAvisoCajaCerrada();
      return;
    }

    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();
      final usuarioId = await storage.getUsuarioId();

      final req = MovimientoCajaModel(
        empresaId: empresaId ?? '',
        sucursalId: sucursalId ?? '',
        usuarioId: usuarioId ?? '',
        tipo: tipo,
        monto: monto,
        descripcion: desc,
      );

      await repository.registrarMovimiento(req);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Movimiento registrado correctamente"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      cargarDatos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar movimiento: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCierre(double saldoInicial) async {
    if (!isCajaAbierta) {
      _mostrarAvisoCajaCerrada();
      return;
    }

    try {
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();
      final usuarioId = await storage.getUsuarioId();

      final req = CierreCajaModel(
        empresaId: empresaId ?? '',
        sucursalId: sucursalId ?? '',
        usuarioId: usuarioId ?? '',
        saldoInicial: saldoInicial,
      );

      final resultado = await repository.cerrarCaja(req);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cierre completado. Saldo Final: ${_moneda.format(resultado.saldoFinal ?? 0.0)}",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      cargarDatos();
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = "Error al cerrar caja";
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        msg = e.response!.data['detail'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cerrar caja: $e"),
          behavior: SnackBarBehavior.floating,
        ),
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

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: tabController.index == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: isCajaAbierta
                      ? () => MovimientoModal.mostrar(
                          context,
                          onConfirm: _handleMovimiento,
                        )
                      : _mostrarAvisoCajaCerrada,
                  backgroundColor: isCajaAbierta ? primaryBlue : Colors.grey,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "Nuevo movimiento",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCajaAbierta ? primaryBlue : Colors.grey,
                  ),
                ),
              ],
            )
          : null,
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
                      onRefresh: cargarDatos,
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
                            _buildQuickActions(primaryBlue, isDark),
                            const SizedBox(height: 16),
                            Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: TabBar(
                                controller: tabController,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: primaryBlue,
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: textSecondary,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                tabs: const [
                                  Tab(text: "Movimientos"),
                                  Tab(text: "Historial Cierres"),
                                ],
                              ),
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
                                : (tabController.index == 0
                                      ? _buildMovimientosList(
                                          isDark,
                                          cardBg,
                                          textPrimary,
                                          textSecondary,
                                          primaryBlue,
                                        )
                                      : _buildCierresList(
                                          isDark,
                                          cardBg,
                                          textPrimary,
                                          textSecondary,
                                          primaryBlue,
                                        )),
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
            "Caja",
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
    final statusColor = isCajaAbierta
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final statusText = isCajaAbierta ? "ABIERTA" : "CERRADA";

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFE0EDFF),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Saldo Actual en Caja",
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _moneda.format(saldoActual),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      isCajaAbierta
                          ? "Turno activo (${cajaAbiertaActual?.fecha != null ? DateFormat('HH:mm').format(cajaAbiertaActual!.fecha!) : 'Hoy'})"
                          : "No hay turno activo para este usuario",
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    "Total Ingresos",
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "+${_moneda.format(totalIngresos)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              Container(
                height: 22,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
              Column(
                children: [
                  Text(
                    "Total Salidas",
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "-${_moneda.format(totalSalidas)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color primaryBlue, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _btnAccion(
            icon: Icons.lock_open_rounded,
            label: "Apertura",
            color: primaryBlue,
            isDark: isDark,
            enabled: !isCajaAbierta,
            onTap: () {
              if (isCajaAbierta) return;
              AperturaModal.mostrar(context, onConfirm: _handleApertura);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btnAccion(
            icon: Icons.calculate_rounded,
            label: "Arqueo",
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            enabled: isCajaAbierta,
            onTap: () {
              if (!isCajaAbierta) {
                _mostrarAvisoCajaCerrada();
                return;
              }
              ArqueoModal.mostrar(
                context,
                saldoEsperado: saldoActual,
                onConfirmarArqueo: (contado) async {
                  try {
                    final empresaId = await storage.getEmpresaId();
                    final sucursalId = await storage.getSucursalId();
                    final usuarioId = await storage.getUsuarioId();
                    if (empresaId == null ||
                        sucursalId == null ||
                        usuarioId == null)
                      return;

                    await repository.notificarArqueo(
                      empresaId: empresaId,
                      sucursalId: sucursalId,
                      usuarioId: usuarioId,
                      saldoEsperado: saldoActual,
                      saldoFisico: contado,
                    );
                  } catch (e) {
                    debugPrint("ERROR AL NOTIFICAR ARQUEO: $e");
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btnAccion(
            icon: Icons.lock_rounded,
            label: "Cierre",
            color: const Color(0xFFEF4444),
            isDark: isDark,
            enabled: isCajaAbierta,
            onTap: () {
              if (!isCajaAbierta) {
                _mostrarAvisoCajaCerrada();
                return;
              }
              CierreModal.mostrar(context, onConfirm: _handleCierre);
            },
          ),
        ),
      ],
    );
  }

  Widget _btnAccion({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final effectiveColor = enabled
        ? color
        : (isDark ? Colors.white24 : Colors.grey.shade400);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: effectiveColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: effectiveColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
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
          hintText: tabController.index == 0
              ? "Buscar movimiento..."
              : "Buscar cierre...",
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          border: InputBorder.none,
          suffixIcon: searchController.text.isNotEmpty
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

  Widget _buildMovimientosList(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    if (movimientosFiltrados.isEmpty) {
      return _emptyState(
        "No encontramos movimientos",
        "Probá buscando por otro término o registrá uno nuevo.",
        "Todavía no tenés movimientos",
        "Agregá tu primer ingreso o salida para registrar actividad en caja.",
        textPrimary,
        textSecondary,
        primaryBlue,
        Icons.receipt_long_outlined,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movimientosFiltrados.length,
      itemBuilder: (context, index) {
        final m = movimientosFiltrados[index];
        final isIngreso = m.tipo == 'INGRESO';
        final accentColor = isIngreso
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIngreso
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.descripcion,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.fecha != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(m.fecha!)
                          : 'Sin fecha',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                "${isIngreso ? '+' : '-'} ${_moneda.format(m.monto)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCierresList(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    if (cierresFiltrados.isEmpty) {
      return _emptyState(
        "No encontramos cierres",
        "Probá buscando por otro término.",
        "Todavía no tenés cierres",
        "Efectuá el cierre de caja para guardar el balance final del turno.",
        textPrimary,
        textSecondary,
        primaryBlue,
        Icons.history_rounded,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cierresFiltrados.length,
      itemBuilder: (context, index) {
        final c = cierresFiltrados[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: Color(0xFF246BFD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.fecha != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(c.fecha!)
                            : 'Sin fecha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF246BFD).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Final: ${_moneda.format(c.saldoFinal ?? 0.0)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _itemDato(
                    "Inicial",
                    c.saldoInicial,
                    textSecondary,
                    textPrimary,
                  ),
                  _itemDato(
                    "Ingresos",
                    c.totalIngresos ?? 0.0,
                    textSecondary,
                    const Color(0xFF10B981),
                  ),
                  _itemDato(
                    "Egresos",
                    c.totalEgresos ?? 0.0,
                    textSecondary,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _itemDato(
    String label,
    double monto,
    Color labelColor,
    Color montoColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        const SizedBox(height: 2),
        Text(
          _moneda.format(monto),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: montoColor,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(
    String busquedaTitulo,
    String busquedaSubtitulo,
    String vacioTitulo,
    String vacioSubtitulo,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
    IconData icon,
  ) {
    final buscando = searchController.text.trim().isNotEmpty;

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
            child: Icon(icon, size: 36, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            buscando ? busquedaTitulo : vacioTitulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            buscando ? busquedaSubtitulo : vacioSubtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
