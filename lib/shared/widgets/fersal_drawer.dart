import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../core/security/biometric_service.dart';
import '../../features/catalogo/categoria/presentation/categorias_page.dart';
import '../../features/catalogo/proveedor/presentation/proveedores_page.dart';
import '../../features/catalogo/productos/presentation/productos_page.dart';

class FersalDrawer extends StatefulWidget {
  const FersalDrawer({super.key});

  @override
  State<FersalDrawer> createState() => _FersalDrawerState();
}

enum ThemeOption { light, dark, system }

class _FersalDrawerState extends State<FersalDrawer> {
  final storage = TokenStorage();

  String nombre = "Alberto Ferreira";
  String email = "admin@fersal.com";
  bool biometric = false;
  int _selectedIndex = 0;

  // Opción por defecto
  ThemeOption _selectedTheme = ThemeOption.system;

  @override
  void initState() {
    super.initState();
    cargarDatos();

    // Sincronizar el estado inicial con el estado global de la app
    if (themeNotifier.value == ThemeMode.light) {
      _selectedTheme = ThemeOption.light;
    } else if (themeNotifier.value == ThemeMode.dark) {
      _selectedTheme = ThemeOption.dark;
    } else {
      _selectedTheme = ThemeOption.system;
    }
  }

  Future<void> cargarDatos() async {
    final name = await storage.getName();
    final mail = await storage.getEmail();
    final bio = await storage.getBiometric();

    if (!mounted) return;

    setState(() {
      nombre = name ?? "Alberto Ferreira";
      email = mail ?? "admin@fersal.com";
      biometric = bio;
    });
  }

  Future<void> cerrarSesion() async {
    await storage.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final headerGradientStart = isDark
        ? const Color(0xFF1E3A8A)
        : const Color(0xFF246BFD);
    final headerGradientEnd = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFF1B62D4);
    final contentBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final dividerColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Drawer(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFF1B62D4),
      elevation: 0,
      child: Column(
        children: [
          // 1. HEADER AZUL
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerGradientStart, headerGradientEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF1B62D4),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.isNotEmpty ? email : "Mi Negocio",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFFFC107),
                              size: 13,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Plan Pro",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. CUERPO SCROLLEABLE
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: contentBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        children: [
                          _buildMenuItem(
                            index: 0,
                            icon: Icons.home_rounded,
                            title: "Inicio",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            showChevron: false,
                            onTap: () {
                              setState(() => _selectedIndex = 0);
                              Navigator.pop(context);
                            },
                          ),
                          _buildMenuItem(
                            index: 1,
                            icon: Icons.shopping_bag_rounded,
                            title: "Nueva venta",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () {
                              setState(() => _selectedIndex = 1);
                            },
                          ),
                          _buildMenuItem(
                            index: 2,
                            icon: Icons.inventory_2_rounded,
                            title: "Productos",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () {
                              setState(() => _selectedIndex = 6);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductosPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            index: 3,
                            icon: Icons.category_rounded,
                            title: "Categorías",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () {
                              setState(() => _selectedIndex = 3);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CategoriasPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItem(
                            index: 4,
                            icon: Icons.people_alt_rounded,
                            title: "Clientes",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () {
                              setState(() => _selectedIndex = 4);
                            },
                          ),
                          _buildMenuItem(
                            index: 5,
                            icon: Icons.bar_chart_rounded,
                            title: "Reportes",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () {
                              setState(() => _selectedIndex = 5);
                            },
                          ),
                          _buildMenuItem(
                            index: 6,
                            icon: Icons.category_rounded,
                            title: "Proveedor",
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () {
                              setState(() => _selectedIndex = 6);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProveedoresPage(),
                                ),
                              );
                            },
                          ),
                        
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: dividerColor, thickness: 1),
                          ),

                          // BIOMETRÍA
                          _buildSwitchTile(
                            icon: Icons.fingerprint_rounded,
                            title: "Acceso biométrico",
                            subtitle: biometric ? "Activado" : "Desactivado",
                            value: biometric,
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onChanged: (value) async {
                              if (value) {
                                final service = BiometricService();
                                final disponible = await service.isAvailable();

                                if (!mounted) return;

                                if (!disponible) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No hay biometría configurada en este dispositivo",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final resultado = await service.authenticate();

                                if (!mounted) return;

                                if (!resultado) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "No se pudo validar la huella",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await storage.saveBiometric(true);
                                setState(() => biometric = true);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Acceso biométrico activado"),
                                  ),
                                );
                              } else {
                                await storage.saveBiometric(false);
                                setState(() => biometric = false);

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Acceso biométrico desactivado",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 10),

                          // SELECTOR DE TEMA
                          _buildThemeSelector(
                            isDark: isDark,
                            primaryBlue: primaryBlue,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),
                    ),

                    // 3. PIE DE PÁGINA FIJO EN LA PARTE INFERIOR
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      decoration: BoxDecoration(
                        color: contentBg,
                        border: Border(
                          top: BorderSide(color: dividerColor, width: 1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 6),
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            leading: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                            title: const Text(
                              "Cerrar sesión",
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: cerrarSesion,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_rounded,
                                color: primaryBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "FERSAL",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Versión 1.0.0",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPONENTES HELPER
  // ============================================================

  Widget _buildThemeSelector({
    required bool isDark,
    required Color primaryBlue,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.palette_outlined, color: textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(
                "Tema de la aplicación",
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildThemeOption(
                label: "Claro",
                icon: Icons.light_mode_rounded,
                option: ThemeOption.light,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              _buildThemeOption(
                label: "Oscuro",
                icon: Icons.dark_mode_rounded,
                option: ThemeOption.dark,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              _buildThemeOption(
                label: "Sistema",
                icon: Icons.settings_suggest_rounded,
                option: ThemeOption.system,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required ThemeOption option,
    required Color primaryBlue,
    required Color textSecondary,
    required bool isDark,
  }) {
    final isSelected = _selectedTheme == option;
    final activeBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTheme = option;
          });

          // Notifica el cambio de tema en tiempo real a MaterialApp
          switch (option) {
            case ThemeOption.light:
              themeNotifier.value = ThemeMode.light;
              break;
            case ThemeOption.dark:
              themeNotifier.value = ThemeMode.dark;
              break;
            case ThemeOption.system:
              themeNotifier.value = ThemeMode.system;
              break;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primaryBlue : textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryBlue : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isDark,
    required Color primaryBlue,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? primaryBlue.withOpacity(0.18) : const Color(0xFFEEF4FF))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: isSelected ? primaryBlue : textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryBlue : textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: showChevron
            ? Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required Color primaryBlue,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textSecondary, fontSize: 11),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          activeColor: primaryBlue,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
