import 'package:flutter/material.dart';

import '../../../shared/widgets/fersal_drawer.dart';
import '../../../core/storage/token_storage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final storage = TokenStorage();

  String nombre = "Alberto";
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    cargarUsuario();
  }

  Future<void> cargarUsuario() async {
    final name = await storage.getName();

    if (!mounted) return;

    setState(() {
      nombre = name ?? "Alberto";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Paleta General
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F5F8);

    return Scaffold(
      drawer: const FersalDrawer(),
      backgroundColor: bgColor,
      bottomNavigationBar: _buildCustomBottomBar(isDark, primaryBlue),
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              // Fondo azul superior con degradado
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

              // Contenido scrolleable
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // NAVEGACIÓN INFERIOR PERSONALIZADA
  // ============================================================

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
          // Barra rectangular de fondo
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
                // Sección Izquierda
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
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart_outlined,
                        selectedIcon: Icons.bar_chart_rounded,
                        label: "Ventas",
                        index: 1,
                        primaryColor: primaryBlue,
                        unselectedColor: unselectedColor,
                      ),
                    ],
                  ),
                ),

                // Espacio libre central para el FAB
                const SizedBox(width: 68),

                // Sección Derecha
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
                      ),
                      _buildNavItem(
                        icon: Icons.people_outline_rounded,
                        selectedIcon: Icons.people_alt_rounded,
                        label: "Clientes",
                        index: 3,
                        primaryColor: primaryBlue,
                        unselectedColor: unselectedColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botón Central flotante
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {},
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
  }) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? primaryColor : unselectedColor;

    return InkWell(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
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

  // ============================================================
  // VENTAS DE HOY
  // ============================================================

  Widget _buildSalesCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? const Color(0xFF94A3B8) : Colors.black87;
    final amountColor = isDark ? Colors.white : Colors.black;
    final iconBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F8EE);
    final iconColor = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF22C55E);

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
            "Gs. 1.250.000",
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
                "18 transacciones",
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
                "Gs. 320.000",
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

  // ============================================================
  // POR COBRAR / POR PAGAR
  // ============================================================

  Widget _buildFinancialCards(bool isDark) {
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
            amount: "Gs. 450.000",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _financialCard(
            icon: Icons.person_pin,
            iconBg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE6F0FF),
            iconColor: isDark
                ? const Color(0xFF60A5FA)
                : const Color(0xFF1B62D4),
            title: "Por Pagar",
            amount: "Gs. 200.000",
            isDark: isDark,
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
  }) {
    return Container(
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
    );
  }

  // ============================================================
  // ACCIONES RÁPIDAS
  // ============================================================

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
            ),
            _actionItem(
              isDark ? const Color(0xFF9333EA) : const Color(0xFF7C3AED),
              Icons.receipt_rounded,
              "Registrar Gasto",
              isDark,
            ),
            _actionItem(
              isDark ? const Color(0xFFEA580C) : const Color(0xFFF97316),
              Icons.inventory_2_rounded,
              "Nuevo Producto",
              isDark,
            ),
            _actionItem(
              isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB),
              Icons.person_rounded,
              "Cobrar Fiado",
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionItem(Color color, IconData icon, String label, bool isDark) {
    return SizedBox(
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
    );
  }

  // ============================================================
  // STOCK BAJO
  // ============================================================

  Widget _buildLowStock(bool isDark) {
    final actionColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1B62D4);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Stock bajo (2)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () {},
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
        Row(
          children: [
            Expanded(child: _stockCard("Arroz", "1kg - 2 un.", isDark)),
            const SizedBox(width: 10),
            Expanded(child: _stockCard("Leche", "1L - 1 un.", isDark)),
          ],
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÚLTIMAS TRANSACCIONES
  // ============================================================

  Widget _buildTransactions(bool isDark) {
    final actionColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF1B62D4);

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
              onTap: () {},
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
          child: Column(
            children: [
              _transactionItem(
                color: isDark
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF22C55E),
                title: "Venta #104",
                amount: "Gs. 35.000",
                time: "11:42 AM",
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey.shade100,
                ),
              ),
              _transactionItem(
                color: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
                title: "Fiado a Pedro R.",
                amount: "Gs. 15.000",
                time: "10:15 AM",
                isDark: isDark,
              ),
            ],
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
            width: 60,
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
