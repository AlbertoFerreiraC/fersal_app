import 'package:flutter/material.dart';

class FersalBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;

  const FersalBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF0F52BA);
    final navBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final unselectedColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF64748B);

    return SizedBox(
      height: 85, // Altura total reservada para el Stack
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Barra blanca/oscura de fondo
          Container(
            height: 65,
            decoration: BoxDecoration(
              color: navBgColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Lado izquierdo (2 items)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: "Inicio",
                        index: 0,
                        primaryColor: primaryColor,
                        unselectedColor: unselectedColor,
                      ),
                      _buildNavItem(
                        icon: Icons.sync_alt_rounded,
                        selectedIcon: Icons.sync_alt_rounded,
                        label: "Transferir",
                        index: 1,
                        primaryColor: primaryColor,
                        unselectedColor: unselectedColor,
                      ),
                    ],
                  ),
                ),

                // Espacio reservado para el botón central
                const SizedBox(width: 70),

                // Lado derecho (2 items)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.payments_outlined,
                        selectedIcon: Icons.payments_rounded,
                        label: "Pagar",
                        index: 2,
                        primaryColor: primaryColor,
                        unselectedColor: unselectedColor,
                      ),
                      _buildNavItem(
                        icon: Icons.grid_view_outlined,
                        selectedIcon: Icons.grid_view_rounded,
                        label: "Para vos",
                        index: 3,
                        primaryColor: primaryColor,
                        unselectedColor: unselectedColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Botón flotante central perfectamente posicionado
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onFabPressed,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded, // o Icons.add si prefieres
                  color: Colors.white,
                  size: 28,
                ),
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
    final isSelected = currentIndex == index;
    final color = isSelected ? primaryColor : unselectedColor;

    return InkWell(
      onTap: () => onTap(index),
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
}
