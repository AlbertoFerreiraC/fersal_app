import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'es_PY');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final clean = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return const TextEditingValue(text: '');
    final number = int.parse(clean);
    final formatted = _formatter.format(number).replaceAll(',', '.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CierreModal extends StatefulWidget {
  final Future<void> Function(double saldoInicial) onConfirm;

  const CierreModal({super.key, required this.onConfirm});

  static Future<void> mostrar(
    BuildContext context, {
    required Future<void> Function(double saldoInicial) onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'CierreModal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: CierreModal(onConfirm: onConfirm),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<CierreModal> createState() => _CierreModalState();
}

class _CierreModalState extends State<CierreModal> {
  final _formKey = GlobalKey<FormState>();
  final _saldoInicialController = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void dispose() {
    _saldoInicialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cierre de Caja",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Esta acción registrará el balance final y cerrará el turno actual en Guaraníes.",
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _saldoInicialController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                labelText: "Saldo Inicial Asignado",
                prefixText: "Gs. ",
                prefixStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Monto requerido";
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text("CANCELAR"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _submitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _submitting = true);
                            final raw = _saldoInicialController.text
                                .replaceAll('.', '')
                                .trim();
                            final inicial = double.parse(raw);
                            await widget.onConfirm(inicial);
                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        },
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("CERRAR CAJA"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
