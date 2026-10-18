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

class ArqueoModal extends StatefulWidget {
  final double saldoEsperado;
  final Future<void> Function(double contado)? onConfirmarArqueo;

  const ArqueoModal({
    super.key,
    required this.saldoEsperado,
    this.onConfirmarArqueo,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required double saldoEsperado,
    Future<void> Function(double contado)? onConfirmarArqueo,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ArqueoModal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: ArqueoModal(
              saldoEsperado: saldoEsperado,
              onConfirmarArqueo: onConfirmarArqueo,
            ),
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
  State<ArqueoModal> createState() => _ArqueoModalState();
}

class _ArqueoModalState extends State<ArqueoModal> {
  final _contadoController = TextEditingController();
  double? _diferencia;
  bool _enviando = false;

  static final _monedaFormat = NumberFormat.currency(
    locale: 'es_PY',
    symbol: 'Gs. ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _contadoController.dispose();
    super.dispose();
  }

  void _calcular() {
    final raw = _contadoController.text.replaceAll('.', '').trim();
    final contado = double.tryParse(raw) ?? 0.0;
    setState(() {
      _diferencia = contado - widget.saldoEsperado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Arqueo de Caja",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Compará el saldo físico contado contra el saldo en sistema.",
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBlue.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saldo en Sistema:",
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  Text(
                    _monedaFormat.format(widget.saldoEsperado),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contadoController,
              autofocus: true,
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
              onChanged: (_) => _calcular(),
              decoration: InputDecoration(
                labelText: "Efectivo Contado en Físico",
                prefixText: "Gs. ",
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_diferencia != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      (_diferencia! == 0
                              ? const Color(0xFF10B981)
                              : (_diferencia! < 0
                                    ? const Color(0xFFEF4444)
                                    : Colors.orange))
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diferencia: ${_monedaFormat.format(_diferencia!)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _diferencia! == 0
                            ? const Color(0xFF10B981)
                            : (_diferencia! < 0
                                  ? const Color(0xFFEF4444)
                                  : Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _diferencia! == 0
                          ? "✓ Caja cuadrada exactamente."
                          : (_diferencia! < 0
                                ? "⚠ Faltante de dinero en caja."
                                : "⚠ Sobrante de dinero en caja."),
                      style: TextStyle(fontSize: 12, color: textPrimary),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _enviando
                    ? null
                    : () async {
                        final raw = _contadoController.text
                            .replaceAll('.', '')
                            .trim();
                        final contado = double.tryParse(raw) ?? 0.0;
                        if (widget.onConfirmarArqueo != null) {
                          setState(() => _enviando = true);
                          await widget.onConfirmarArqueo!(contado);
                          if (!mounted) return;
                        }
                        Navigator.pop(context);
                      },
                child: _enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("LISTO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
