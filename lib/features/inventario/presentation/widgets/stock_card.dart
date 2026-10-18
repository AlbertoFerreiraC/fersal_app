import 'package:flutter/material.dart';

import '../../model/stock.dart';

class StockCard extends StatelessWidget {
  final Stock stock;

  const StockCard({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final stockBajo = stock.stockBajo;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: stockBajo
                  ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFFF3E0))
                  : (isDark
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFE0EDFF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: stockBajo
                  ? (isDark ? const Color(0xFFFB923C) : const Color(0xFFE65100))
                  : (isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF1B62D4)),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.productoNombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.store_outlined, size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        stock.sucursalNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${stock.cantidad}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stockBajo
                      ? const Color(0xFFEF4444)
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: stockBajo
                      ? (isDark
                            ? const Color(0xFF451A03)
                            : const Color(0xFFFFE8E8))
                      : (isDark
                            ? const Color(0xFF064E3B)
                            : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stockBajo ? "Stock bajo" : "Disponible",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: stockBajo
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
