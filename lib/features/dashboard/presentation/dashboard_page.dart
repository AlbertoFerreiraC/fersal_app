import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/widgets/fersal_drawer.dart';
import '../../caja/presentation/caja_page.dart';
import '../../catalogo/productos/presentation/productos_page.dart';
import '../../clientes/presentation/clientes_page.dart';
import '../../cuentas_corrientes/presentation/cuentas_page.dart';
import '../../inventario/presentation/stocks_page.dart';
import '../../ventas/presentation/comprobante_page.dart';
import '../../ventas/presentation/nueva_venta_page.dart';
import '../../ventas/presentation/ventas_page.dart';
import '../data/dashboard_repository.dart';
import '../model/dashboard_model.dart';
import '../../compras/presentation/compras_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final storage = TokenStorage();
  late final DashboardRepository repository;

  String nombre = "";
  int _currentNavIndex = 0;
  bool loading = true;

  DashboardModel? metricas;

  static final NumberFormat _moneda = NumberFormat.currency(
    locale: 'es_PY',
    symbol: 'Gs. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    repository = DashboardRepository(ApiClient(storage: storage));
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      final name = await storage.getName();
      final empresaId = await storage.getEmpresaId();
      final sucursalId = await storage.getSucursalId();

      if (!mounted) return;
      setState(() {
        nombre = name ?? "Usuario";
      });

      if (empresaId != null && sucursalId != null) {
        final res = await repository.obtenerMetricas(
          empresaId: empresaId,
          sucursalId: sucursalId,
        );

        if (!mounted) return;
        setState(() {
          metricas = res;
          loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("ERROR CARGANDO DASHBOARD: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F5F8);

    if (loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                  : [const Color(0xFF246BFD), const Color(0xFF1B62D4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF1B62D4),
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "FERSAL",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sincronizando información de tu negocio...",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      bottomNavigationBar: _buildCustomBottomBar(isDark, primaryBlue),
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E3A8A),
                            const Color(0xFF1E293B),
                            bgColor,
                          ]
                        : [
                            const Color(0xFF246BFD),
                            const Color(0xFF387BFF),
                            bgColor,
                          ],
                    stops: const [0.0, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: cargarDatos,
                  color: primaryBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSalesCard(isDark),
                              const SizedBox(height: 14),
                              _buildFinancialCards(isDark),
                              const SizedBox(height: 20),
                              _buildQuickActions(isDark),
                              const SizedBox(height: 20),
                              _buildLowStock(isDark),
                              const SizedBox(height: 20),
                              _buildTransactions(isDark),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomBottomBar(bool isDark, Color primaryBlue) {
    final navBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final unselectedColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF8C98A8);

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: navBgColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: "Inicio",
                        index: 0,
                        primaryColor: primaryBlue,
                        unselectedColor: unselectedColor,
                        onTap: () => setState(() => _currentNavIndex = 0),
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart_outlined,
                        selectedIcon: Icons.bar_chart_rounded,
                        label: "Ventas",
                        index: 1,
                        primaryColor: primaryBlue,
                        unselectedColor: unselectedColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VentasPage(),
                            ),
                          ).then((_) => cargarDatos());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 68),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.inventory_2_outlined,
                        selectedIcon: Icons.inventory_2_rounded,
                        label: "Inventario",
                        index: 2,
                        primaryColor: primaryBlue,
                        unselectedColor: unselectedColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StocksPage(),
                            ),
                          ).then((_) => cargarDatos());
                        },
                      ),
                      _buildNavItem(
                        icon: Icons.people_outline_rounded,
                        selectedIcon: Icons.people_alt_rounded,
                        label: "Clientes",
                        index: 3,
                        primaryColor: primaryBlue,
                        unselectedColor: unselectedColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClientesPage(),
                            ),
                          ).then((_) => cargarDatos());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaVentaPage()),
                ).then((_) => cargarDatos());
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required Color primaryColor,
    required Color unselectedColor,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? primaryColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                icon: const Icon(Icons.menu, color: Colors.white, size: 26),
              ),
              const Spacer(),
              const Text(
                "FERSAL",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "¡Hola, $nombre! 👋",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Así va tu negocio hoy",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? const Color(0xFF94A3B8) : Colors.black87;
    final amountColor = isDark ? Colors.white : Colors.black;
    final iconBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F8EE);
    final iconColor = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF22C55E);

    final ventasMonto = metricas?.ventasHoy ?? 0.0;
    final transacciones = metricas?.transaccionesHoy ?? 0;
    final ganancia = metricas?.gananciaHoy ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ventas de hoy",
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _moneda.format(ventasMonto),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: amountColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "$transacciones transacciones",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.black45,
                  fontSize: 13,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "•",
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : Colors.black45,
                  ),
                ),
              ),
              Text(
                "Ganancia: ",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                  fontSize: 13,
                ),
              ),
              Text(
                _moneda.format(ganancia),
                style: TextStyle(
                  color: iconColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCards(bool isDark) {
    final fiados = metricas?.totalPorCobrar ?? 0.0;
    final porPagar = metricas?.totalPorPagar ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _financialCard(
            icon: Icons.account_balance_wallet,
            iconBg: isDark ? const Color(0xFF451A03) : const Color(0xFFFFE8E8),
            iconColor: isDark
                ? const Color(0xFFF87171)
                : const Color(0xFFFF4D4D),
            title: "Por Cobrar (Fiado)",
            amount: _moneda.format(fiados),
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CuentasPage()),
              ).then((_) => cargarDatos());
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _financialCard(
            icon: Icons.person_pin,
            iconBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE6F0FF),
            iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B62D4),
            title: "Por Pagar",
            amount: _moneda.format(porPagar),
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComprasPage()),
              ).then((_) => cargarDatos());
            },
          ),
        ),
      ],
    );
  }

  Widget _financialCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String amount,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Acciones rápidas",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionItem(
              isDark ? const Color(0xFF16A34A) : const Color(0xFF22C55E),
              Icons.shopping_bag_rounded,
              "Nueva Venta",
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaVentaPage()),
                ).then((_) => cargarDatos());
              },
            ),
            _actionItem(
              isDark ? const Color(0xFF0284C7) : const Color(0xFF0284C7),
              Icons.point_of_sale_rounded,
              "Turno Caja",
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CajaPage()),
                ).then((_) => cargarDatos());
              },
            ),
            _actionItem(
              isDark ? const Color(0xFF9333EA) : const Color(0xFF7C3AED),
              Icons.receipt_rounded,
              "Catálogo",
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductosPage()),
                ).then((_) => cargarDatos());
              },
            ),
            _actionItem(
              isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB),
              Icons.person_rounded,
              "Fiados",
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CuentasPage()),
                ).then((_) => cargarDatos());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionItem(
    Color color,
    IconData icon,
    String label,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStock(bool isDark) {
    final actionColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1B62D4);
    final items = metricas?.stockBajo ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Stock bajo (${items.length})",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StocksPage()),
                ).then((_) => cargarDatos());
              },
              child: Text(
                "Ver todo",
                style: TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Todos tus productos cuentan con stock suficiente.",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              ),
            ),
          )
        else
          Row(
            children: items.take(2).map((s) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _stockCard(
                    s.nombre,
                    "${s.stockActual} disp. (Mín: ${s.stockMinimo})",
                    isDark,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _stockCard(String title, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_outlined,
              color: isDark ? const Color(0xFFFB923C) : const Color(0xFFE65100),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(bool isDark) {
    final actionColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1B62D4);
    final txs = metricas?.ultimasTransacciones ?? [];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Últimas transacciones",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VentasPage()),
                ).then((_) => cargarDatos());
              },
              child: Text(
                "Ver todas",
                style: TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: txs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No hay ventas registradas el día de hoy.",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : Colors.grey.shade100,
                  ),
                  itemBuilder: (context, idx) {
                    final t = txs[idx];
                    final esCredito =
                        t.tipoPago.toUpperCase().contains("CUENTA") ||
                        t.tipoPago.toUpperCase().contains("CREDITO");

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComprobantePage(ventaId: t.ventaId),
                          ),
                        );
                      },
                      child: _transactionItem(
                        color: esCredito
                            ? (isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB))
                            : (isDark
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFF22C55E)),
                        title: "${t.numero} • ${t.cliente}",
                        amount: _moneda.format(t.total),
                        time: t.fecha != null
                            ? DateFormat('HH:mm').format(t.fecha!)
                            : '',
                        isDark: isDark,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _transactionItem({
    required Color color,
    required String title,
    required String amount,
    required String time,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 50,
            child: Text(
              time,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
