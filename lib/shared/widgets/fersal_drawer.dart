import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../core/security/biometric_service.dart';

import '../../features/catalogo/categoria/presentation/categorias_page.dart';
import '../../features/catalogo/proveedor/presentation/proveedores_page.dart';
import '../../features/catalogo/productos/presentation/productos_page.dart';
import '../../features/inventario/presentation/stocks_page.dart';
import '../../features/sucursal/presentation/sucursales_page.dart';
import '../../features/inventario/presentation/movimientos/movimientos_page.dart';
import '../../features/clientes/presentation/clientes_page.dart';
import '../../features/cuentas_corrientes/presentation/cuentas_page.dart';
import '../../features/ventas/presentation/nueva_venta_page.dart';
import '../../features/caja/presentation/caja_page.dart';

class FersalDrawer extends StatefulWidget {
  const FersalDrawer({super.key});

  @override
  State<FersalDrawer> createState() => _FersalDrawerState();
}

enum ThemeOption { light, dark, system }

class _FersalDrawerState extends State<FersalDrawer> {
  final storage = TokenStorage();

  String nombre = "";
  String email = "";
  String empresa = "";
  String sucursal = "";
  bool biometric = false;
  int _selectedIndex = 0;
  ThemeOption _selectedTheme = ThemeOption.system;

  @override
  void initState() {
    super.initState();
    cargarDatos();

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
    final empresaNombre = await storage.getEmpresaNombre();
    final sucursalNombre = await storage.getSucursalNombre();
    final bio = await storage.getBiometric();

    if (!mounted) return;

    setState(() {
      nombre = name ?? "";
      email = mail ?? "";
      empresa = empresaNombre ?? "";
      sucursal = sucursalNombre ?? "";
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          // ==========================
          // HEADER
          // ==========================
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFF1B62D4),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isEmpty ? "Usuario" : nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        empresa,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sucursal.isNotEmpty)
                        Text(
                          sucursal,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================
          // MODULOS SCROLL
          // ==========================
          Expanded(
            child: Container(
              color: contentBg,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _buildMenuItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    title: "Inicio",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
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
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NuevaVentaPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 2,
                    icon: Icons.point_of_sale_rounded,
                    title: "Caja",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CajaPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 3,
                    icon: Icons.inventory_2_rounded,
                    title: "Productos",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
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
                    index: 4,
                    icon: Icons.category_rounded,
                    title: "Categorías",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
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
                    index: 5,
                    icon: Icons.people_alt_rounded,
                    title: "Clientes",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClientesPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 6,
                    icon: Icons.people,
                    title: "Proveedores",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProveedoresPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 7,
                    icon: Icons.warehouse,
                    title: "Stock",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StocksPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 8,
                    icon: Icons.store,
                    title: "Sucursales",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SucursalesPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 9,
                    icon: Icons.compare_arrows_rounded,
                    title: "Movimientos Stock",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MovimientosPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    index: 10,
                    icon: Icons.account_balance_wallet,
                    title: "Cuentas corrientes",
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CuentasPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ==========================
          // PARTE FIJA INFERIOR
          // ==========================
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
            decoration: BoxDecoration(
              color: contentBg,
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==========================
                  // BIOMETRIA
                  // ==========================
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

                        if (!disponible) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Biometría no disponible"),
                            ),
                          );
                          return;
                        }

                        final resultado = await service.authenticate();

                        if (!resultado) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Validación biométrica fallida"),
                            ),
                          );
                          return;
                        }

                        await storage.saveBiometric(true);

                        setState(() {
                          biometric = true;
                        });
                      } else {
                        await storage.saveBiometric(false);

                        setState(() {
                          biometric = false;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 8),

                  // ==========================
                  // TEMA
                  // ==========================
                  _buildThemeSelector(
                    isDark: isDark,
                    primaryBlue: primaryBlue,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 8),

                  // ==========================
                  // LOGOUT
                  // ==========================
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Cerrar sesión",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: cerrarSesion,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 18,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "FERSAL",
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Versión 1.0.0",
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SELECTOR DE TEMA
  // ==========================================================
  Widget _buildThemeSelector({
    required bool isDark,
    required Color primaryBlue,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_outlined, color: textSecondary, size: 20),
            const SizedBox(width: 10),
            Text(
              "Tema",
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildThemeOption(
                label: "Claro",
                icon: Icons.light_mode,
                option: ThemeOption.light,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              _buildThemeOption(
                label: "Oscuro",
                icon: Icons.dark_mode,
                option: ThemeOption.dark,
                primaryBlue: primaryBlue,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              _buildThemeOption(
                label: "Sistema",
                icon: Icons.settings_suggest,
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
    final selected = _selectedTheme == option;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTheme = option;
          });

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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? primaryBlue : textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? primaryBlue : textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ITEM MENU
  // ==========================================================
  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isDark,
    required Color primaryBlue,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    final selected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected ? primaryBlue.withOpacity(.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: selected ? primaryBlue : textSecondary),
          title: Text(
            title,
            style: TextStyle(
              color: selected ? primaryBlue : textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            onTap();
          },
        ),
      ),
    );
  }

  // ==========================================================
  // SWITCH TILE
  // ==========================================================
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
      leading: Icon(icon, color: textSecondary),
      title: Text(
        title,
        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        activeColor: primaryBlue,
        onChanged: onChanged,
      ),
    );
  }
}
