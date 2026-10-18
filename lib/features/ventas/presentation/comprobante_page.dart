import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class ComprobantePage extends StatefulWidget {
  final String ventaId;

  const ComprobantePage({super.key, required this.ventaId});

  @override
  State<ComprobantePage> createState() => _ComprobantePageState();
}

class _ComprobantePageState extends State<ComprobantePage> {
  final storage = TokenStorage();

  Uint8List? pdfBytes;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarComprobante();
  }

  Future<void> cargarComprobante() async {
    try {
      final api = ApiClient(storage: storage);
      final response = await api.client.get(
        "/ventas/${widget.ventaId}/comprobante",
      );

      final base64 = response.data["contenidoBase64"];
      final bytes = base64Decode(base64);

      if (!mounted) return;

      setState(() {
        pdfBytes = bytes;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR PDF: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> compartir() async {
    if (pdfBytes == null) return;

    await Share.shareXFiles([
      XFile.fromData(
        pdfBytes!,
        name: "comprobante.pdf",
        mimeType: "application/pdf",
      ),
    ], text: "Comprobante de venta FERSAL");
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Fondo azul superior
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
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
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
                        "Comprobante de Venta",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                        ),
                        onPressed: compartir,
                      ),
                    ],
                  ),
                ),

                // Visor PDF
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
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : pdfBytes == null
                          ? const Center(
                              child: Text("No se pudo cargar el comprobante"),
                            )
                          : SfPdfViewer.memory(pdfBytes!),
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
}
