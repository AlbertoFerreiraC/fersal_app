import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../data/proveedores_api.dart';
import '../model/proveedor.dart';
import '../model/proveedor_request.dart';

class ProveedorFormPage extends StatefulWidget {
  final Proveedor? proveedor;

  const ProveedorFormPage({super.key, this.proveedor});

  bool get editando => proveedor != null;

  /// Método estático para invocar el formulario como un Popup (Bottom Sheet)
  static Future<bool?> mostrar(BuildContext context, {Proveedor? proveedor}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ProveedorFormPage(proveedor: proveedor),
      ),
    );
  }

  @override
  State<ProveedorFormPage> createState() => _ProveedorFormPageState();
}

class _ProveedorFormPageState extends State<ProveedorFormPage> {
  final TokenStorage storage = TokenStorage();

  final nombreController = TextEditingController();
  final rucController = TextEditingController();
  final telefonoController = TextEditingController();
  final emailController = TextEditingController();
  final direccionController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.proveedor != null) {
      final proveedor = widget.proveedor!;
      nombreController.text = proveedor.nombre;
      rucController.text = proveedor.ruc ?? "";
      telefonoController.text = proveedor.telefono ?? "";
      emailController.text = proveedor.email ?? "";
      direccionController.text = proveedor.direccion ?? "";
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    rucController.dispose();
    telefonoController.dispose();
    emailController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void> guardar() async {
    FocusScope.of(context).unfocus();

    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      _mostrarMensaje("Ingrese el nombre del proveedor");
      return;
    }

    final empresaId = await storage.getEmpresaId();

    if (empresaId == null || empresaId.isEmpty) {
      _mostrarMensaje("No se encontró la empresa asociada al usuario");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final api = ProveedoresApi(ApiClient(storage: storage));

      final request = ProveedorRequest(
        empresaId: empresaId,
        nombre: nombre,
        ruc: rucController.text.trim(),
        telefono: telefonoController.text.trim(),
        email: emailController.text.trim(),
        direccion: direccionController.text.trim(),
      );

      if (widget.editando) {
        await api.actualizar(widget.proveedor!.id, request);
      } else {
        await api.crear(request);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            widget.editando
                ? "Proveedor actualizado correctamente"
                : "Proveedor creado correctamente",
          ),
        ),
      );

      Navigator.pop(context, true); // Retorna true para refrescar
    } catch (e) {
      debugPrint("ERROR GUARDANDO PROVEEDOR: $e");

      if (!mounted) return;

      _mostrarMensaje("No se pudo guardar el proveedor");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(mensaje)),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final editando = widget.editando;
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

          // Indicador superior (Pill)
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
                        editando ? Icons.edit_rounded : Icons.business_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      editando ? "Editar proveedor" : "Nuevo proveedor",
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Información principal",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _campo(
                    controller: nombreController,
                    label: "Nombre del proveedor",
                    hint: "Ej. Distribuidora ABC",
                    icon: Icons.business_outlined,
                    obligatorio: true,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                  ),

                  const SizedBox(height: 12),

                  _campo(
                    controller: rucController,
                    label: "RUC",
                    hint: "Ej. 80012345-6",
                    icon: Icons.badge_outlined,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Datos de contacto",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _campo(
                    controller: telefonoController,
                    label: "Teléfono",
                    hint: "Ej. 0981 123456",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                  ),

                  const SizedBox(height: 12),

                  _campo(
                    controller: emailController,
                    label: "Correo electrónico",
                    hint: "Ej. ventas@proveedor.com",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                  ),

                  const SizedBox(height: 12),

                  _campo(
                    controller: direccionController,
                    label: "Dirección",
                    hint: "Ej. Av. España 1234",
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    primaryBlue: primaryBlue,
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
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
                          onPressed: loading ? null : guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  editando
                                      ? "Guardar cambios"
                                      : "Crear proveedor",
                                  style: const TextStyle(
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

  // ============================================================
  // CAMPO
  // ============================================================

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryBlue,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obligatorio = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          obligatorio ? "$label *" : label,
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
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontSize: 13, color: textPrimary),
            textInputAction: maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary, fontSize: 12),
              prefixIcon: Icon(icon, color: textSecondary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
