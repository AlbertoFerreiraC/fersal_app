import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

import '../../categoria/data/categorias_api.dart';
import '../../categoria/model/categoria.dart';

import '../../proveedor/data/proveedores_api.dart';
import '../../proveedor/model/proveedor.dart';

import '../data/productos_api.dart';
import '../model/producto.dart';
import '../model/producto_request.dart';

class ProductoFormPage extends StatefulWidget {
  final Producto? producto;

  const ProductoFormPage({super.key, this.producto});

  bool get editando => producto != null;

  /// Método estático para invocar el formulario como un Popup (Bottom Sheet)
  static Future<Producto?> mostrar(BuildContext context, {Producto? producto}) {
    return showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ProductoFormPage(producto: producto),
      ),
    );
  }

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final storage = TokenStorage();
  final ImagePicker imagePicker = ImagePicker();

  final nombreController = TextEditingController();
  final codigoController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioCompraController = TextEditingController();
  final precioVentaController = TextEditingController();
  final stockMinimoController = TextEditingController();

  List<Categoria> categorias = [];
  List<Proveedor> proveedores = [];

  String? categoriaSeleccionada;
  String? proveedorSeleccionado;
  File? imagenSeleccionada;
  String? imagenActual;

  bool loading = false;
  bool loadingDatos = true;
  bool eliminandoImagen = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    descripcionController.dispose();
    precioCompraController.dispose();
    precioVentaController.dispose();
    stockMinimoController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGAR DATOS
  // ============================================================

  Future<void> cargarDatos() async {
    try {
      final empresaId = await storage.getEmpresaId();

      if (empresaId == null || empresaId.isEmpty) {
        if (!mounted) return;
        setState(() {
          loadingDatos = false;
        });
        return;
      }

      final apiClient = ApiClient(storage: storage);
      final categoriasApi = CategoriasApi(apiClient);
      final proveedoresApi = ProveedoresApi(apiClient);

      final resultados = await Future.wait([
        categoriasApi.listarEmpresa(empresaId),
        proveedoresApi.listarEmpresa(empresaId),
      ]);

      if (!mounted) return;

      setState(() {
        categorias = resultados[0] as List<Categoria>;
        proveedores = resultados[1] as List<Proveedor>;
        loadingDatos = false;
      });

      cargarProducto();
    } catch (e) {
      debugPrint("ERROR CARGANDO DATOS PRODUCTO: $e");

      if (!mounted) return;

      setState(() {
        loadingDatos = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudieron cargar categorías y proveedores"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // CARGAR PRODUCTO PARA EDICION
  // ============================================================

  void cargarProducto() {
    final producto = widget.producto;

    if (producto == null) {
      return;
    }

    nombreController.text = producto.nombre;
    codigoController.text = producto.codigo;
    descripcionController.text = producto.descripcion ?? "";
    precioCompraController.text = producto.precioCompra?.toString() ?? "";
    precioVentaController.text = producto.precioVenta?.toString() ?? "";
    stockMinimoController.text = producto.stockMinimo?.toString() ?? "";

    categoriaSeleccionada = producto.categoriaId;
    proveedorSeleccionado = producto.proveedorId;
    imagenActual = producto.imagenUrl;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  Future<void> seleccionarImagen(ImageSource source) async {
    try {
      final XFile? imagen = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (imagen == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        imagenSeleccionada = File(imagen.path);
      });
    } catch (e) {
      debugPrint("ERROR SELECCIONANDO IMAGEN: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo seleccionar la imagen"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> mostrarOpcionesImagen() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1B62D4);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);

    await showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Seleccionar imagen",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: primaryBlue),
                  ),
                  title: Text(
                    "Tomar una foto",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: const Text("Usar la cámara"),
                  onTap: () {
                    Navigator.pop(context);
                    seleccionarImagen(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA).withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                  title: Text(
                    "Elegir de la galería",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: const Text("Seleccionar una imagen"),
                  onTap: () {
                    Navigator.pop(context);
                    seleccionarImagen(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // QUITAR IMAGEN
  // ============================================================

  Future<void> quitarImagen() async {
    if (imagenSeleccionada != null) {
      setState(() {
        imagenSeleccionada = null;
      });
      return;
    }

    if (imagenActual == null || imagenActual!.isEmpty) {
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            "Eliminar imagen",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Text(
            "¿Querés eliminar la imagen de este producto?",
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      setState(() {
        eliminandoImagen = true;
      });

      final api = ProductosApi(ApiClient(storage: storage));
      await api.eliminarImagen(widget.producto!.id);

      if (!mounted) return;

      setState(() {
        imagenActual = null;
        eliminandoImagen = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Imagen eliminada"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("ERROR ELIMINANDO IMAGEN: $e");

      if (!mounted) return;

      setState(() {
        eliminandoImagen = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo eliminar la imagen"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void> guardar() async {
    final nombre = nombreController.text.trim();
    final codigo = codigoController.text.trim();

    if (nombre.isEmpty) {
      _mostrarError("Ingrese el nombre del producto");
      return;
    }

    if (codigo.isEmpty) {
      _mostrarError("Ingrese el código del producto");
      return;
    }

    final empresaId = await storage.getEmpresaId();

    if (empresaId == null || empresaId.isEmpty) {
      _mostrarError("No se encontró la empresa asociada");
      return;
    }

    final precioCompra = _parseDouble(precioCompraController.text);
    final precioVenta = _parseDouble(precioVentaController.text);
    final stockMinimo = int.tryParse(stockMinimoController.text.trim());

    if (!mounted) return;

    setState(() {
      loading = true;
    });

    try {
      final api = ProductosApi(ApiClient(storage: storage));

      final request = ProductoRequest(
        empresaId: empresaId,
        categoriaId: categoriaSeleccionada,
        proveedorId: proveedorSeleccionado,
        codigo: codigo,
        nombre: nombre,
        descripcion: descripcionController.text.trim(),
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        stockMinimo: stockMinimo,
      );

      Producto producto;

      if (widget.editando) {
        producto = await api.actualizar(widget.producto!.id, request);
      } else {
        producto = await api.crear(request);
      }

      if (imagenSeleccionada != null) {
        producto = await api.subirImagen(producto.id, imagenSeleccionada!);
      }

      if (!mounted) return;

      Navigator.pop(context, producto);
    } catch (e) {
      debugPrint("ERROR GUARDANDO PRODUCTO: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo guardar el producto"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  double? _parseDouble(String value) {
    final texto = value.trim().replaceAll(".", "").replaceAll(",", ".");

    if (texto.isEmpty) {
      return null;
    }

    return double.tryParse(texto);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final editar = widget.editando;
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                        editar ? Icons.edit_rounded : Icons.inventory_2_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      editar ? "Editar producto" : "Nuevo producto",
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
          loadingDatos
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tituloSeccion(
                          "Información básica",
                          Icons.info_outline_rounded,
                          primaryBlue,
                        ),

                        const SizedBox(height: 12),

                        _campo(
                          controller: nombreController,
                          label: "Nombre del producto",
                          hint: "Ej. Coca Cola 2L",
                          icon: Icons.inventory_2_outlined,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          obligatorio: true,
                        ),

                        const SizedBox(height: 12),

                        _campo(
                          controller: codigoController,
                          label: "Código de producto",
                          hint: "Ej. PROD-001",
                          icon: Icons.qr_code_2_rounded,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          obligatorio: true,
                        ),

                        const SizedBox(height: 12),

                        _campo(
                          controller: descripcionController,
                          label: "Descripción",
                          hint: "Escribe detalles sobre el producto...",
                          icon: Icons.description_outlined,
                          maxLines: 3,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        const SizedBox(height: 20),

                        _tituloSeccion(
                          "Clasificación",
                          Icons.category_outlined,
                          primaryBlue,
                        ),

                        const SizedBox(height: 12),

                        _categoriaDropdown(
                          inputBg,
                          borderColor,
                          textPrimary,
                          textSecondary,
                          primaryBlue,
                        ),

                        const SizedBox(height: 12),

                        _proveedorDropdown(
                          inputBg,
                          borderColor,
                          textPrimary,
                          textSecondary,
                          primaryBlue,
                        ),

                        const SizedBox(height: 20),

                        _tituloSeccion(
                          "Precios",
                          Icons.payments_outlined,
                          primaryBlue,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _campo(
                                controller: precioCompraController,
                                label: "Precio compra",
                                hint: "0",
                                icon: Icons.shopping_cart_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputBg: inputBg,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _campo(
                                controller: precioVentaController,
                                label: "Precio venta",
                                hint: "0",
                                icon: Icons.sell_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputBg: inputBg,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _tituloSeccion(
                          "Inventario",
                          Icons.warehouse_outlined,
                          primaryBlue,
                        ),

                        const SizedBox(height: 12),

                        _campo(
                          controller: stockMinimoController,
                          label: "Stock mínimo",
                          hint: "Ej. 5",
                          icon: Icons.inventory_outlined,
                          keyboardType: TextInputType.number,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        const SizedBox(height: 20),

                        _tituloSeccion(
                          "Imagen del producto",
                          Icons.image_outlined,
                          primaryBlue,
                        ),

                        const SizedBox(height: 12),

                        _imagenSelector(
                          inputBg,
                          borderColor,
                          textPrimary,
                          textSecondary,
                          primaryBlue,
                        ),

                        const SizedBox(height: 24),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                        editar
                                            ? "Guardar cambios"
                                            : "Crear producto",
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
  // IMAGEN SELECTOR
  // ============================================================

  Widget _imagenSelector(
    Color inputBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    final tieneImagenNueva = imagenSeleccionada != null;
    final tieneImagenActual = imagenActual != null && imagenActual!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          if (tieneImagenNueva)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imagenSeleccionada!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else if (tieneImagenActual)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _resolverImagenUrl(imagenActual!),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _imagenPlaceholder(primaryBlue);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }

                  return Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    ),
                  );
                },
              ),
            )
          else
            _imagenPlaceholder(primaryBlue),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading || eliminandoImagen
                      ? null
                      : mostrarOpcionesImagen,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(
                    tieneImagenNueva || tieneImagenActual
                        ? "Cambiar"
                        : "Agregar imagen",
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (tieneImagenNueva || tieneImagenActual) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 40,
                  child: IconButton(
                    onPressed: loading || eliminandoImagen
                        ? null
                        : quitarImagen,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withOpacity(.1),
                      foregroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: eliminandoImagen
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagenPlaceholder(Color primaryBlue) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: primaryBlue,
            size: 40,
          ),
          const SizedBox(height: 6),
          Text(
            "Sin imagen asignada",
            style: TextStyle(
              color: primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _resolverImagenUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }

    String baseUrl = ApiClient(storage: storage).dio.options.baseUrl;

    if (baseUrl.endsWith("/api")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }

    if (url.startsWith("/")) {
      return "$baseUrl$url";
    }

    return "$baseUrl/$url";
  }

  // ============================================================
  // TITULO SECCIÓN
  // ============================================================

  Widget _tituloSeccion(String texto, IconData icon, Color primaryBlue) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryBlue),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ],
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
    int maxLines = 1,
    TextInputType? keyboardType,
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
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: TextStyle(fontSize: 13, color: textPrimary),
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

  // ============================================================
  // CATEGORIA DROPDOWN
  // ============================================================

  Widget _categoriaDropdown(
    Color inputBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Categoría",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: categorias.any((c) => c.id == categoriaSeleccionada)
                  ? categoriaSeleccionada
                  : null,
              dropdownColor: inputBg,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: textSecondary,
                  size: 18,
                ),
              ),
              hint: Text(
                "Seleccionar categoría",
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              style: TextStyle(color: textPrimary, fontSize: 13),
              items: categorias
                  .where((c) => c.activo)
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: loading
                  ? null
                  : (value) {
                      setState(() {
                        categoriaSeleccionada = value;
                      });
                    },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROVEEDOR DROPDOWN
  // ============================================================

  Widget _proveedorDropdown(
    Color inputBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryBlue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Proveedor",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: proveedores.any((p) => p.id == proveedorSeleccionado)
                  ? proveedorSeleccionado
                  : null,
              dropdownColor: inputBg,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.business_outlined,
                  color: textSecondary,
                  size: 18,
                ),
              ),
              hint: Text(
                "Seleccionar proveedor",
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
              style: TextStyle(color: textPrimary, fontSize: 13),
              items: proveedores
                  .where((p) => p.activo)
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: loading
                  ? null
                  : (value) {
                      setState(() {
                        proveedorSeleccionado = value;
                      });
                    },
            ),
          ),
        ),
      ],
    );
  }
}
