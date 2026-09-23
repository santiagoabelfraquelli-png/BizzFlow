import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductsScreen extends StatefulWidget {
  final String businessId;

  const ProductsScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String _selectedUnit = 'unidad';
  bool _selectedActive = true;
  bool _isSaving = false;

  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  CollectionReference<Map<String, dynamic>> get _categories =>
      FirebaseFirestore.instance.collection('categories');

  CollectionReference<Map<String, dynamic>> get _stockMovements =>
      FirebaseFirestore.instance.collection('stock_movements');

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _background = Color(0xFFF7F7FB);
  static const Color _textPrimary = Color(0xFF202124);
  static const Color _textSecondary = Color(0xFF737373);

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Future<void> _saveNewProduct() async {
    final name = _nameController.text.trim();
    final price = _parseNumber(_priceController.text);
    final stock = _parseNumber(_stockController.text);

    if (name.isEmpty) {
      _showMessage('Ingresá un nombre para el producto');
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      _showMessage('Seleccioná una categoría');
      return;
    }
    if (price == null || price < 0) {
      _showMessage('Ingresá un precio válido');
      return;
    }
    if (stock == null || stock < 0) {
      _showMessage('Ingresá un stock válido');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final productRef = _products.doc();
      final movementRef = _stockMovements.doc();
      final batch = FirebaseFirestore.instance.batch();

      batch.set(productRef, {
        'businessId': widget.businessId,
        'name': name,
        'categoryId': _selectedCategoryId,
        'categoryName': _selectedCategoryName,
        'price': price,
        'stock': stock,
        'unit': _selectedUnit,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (stock > 0) {
        batch.set(movementRef, {
          'businessId': widget.businessId,
          'productId': productRef.id,
          'productName': name,
          'type': 'initial',
          'quantity': stock,
          'stockBefore': 0,
          'stockAfter': stock,
          'note': 'Stock inicial',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _clearForm();
      if (mounted) {
        Navigator.of(context).pop();
        _showMessage('Producto creado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error al crear producto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateProduct(String productId) async {
    final name = _nameController.text.trim();
    final price = _parseNumber(_priceController.text);
    final newStock = _parseNumber(_stockController.text);

    if (name.isEmpty) {
      _showMessage('Ingresá un nombre para el producto');
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      _showMessage('Seleccioná una categoría');
      return;
    }
    if (price == null || price < 0) {
      _showMessage('Ingresá un precio válido');
      return;
    }
    if (newStock == null || newStock < 0) {
      _showMessage('Ingresá un stock válido');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final productRef = _products.doc(productId);
      final movementRef = _stockMovements.doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) {
          throw StateError('El producto ya no existe');
        }

        final data = snapshot.data() ?? {};
        final oldStockValue = data['stock'];
        final oldStock = oldStockValue is num
            ? oldStockValue.toDouble()
            : 0.0;

        transaction.update(productRef, {
          'name': name,
          'categoryId': _selectedCategoryId,
          'categoryName': _selectedCategoryName,
          'price': price,
          'stock': newStock,
          'unit': _selectedUnit,
          'active': _selectedActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (oldStock != newStock) {
          final difference = newStock - oldStock;
          transaction.set(movementRef, {
            'businessId': widget.businessId,
            'productId': productId,
            'productName': name,
            'type': difference > 0 ? 'adjustment_in' : 'adjustment_out',
            'quantity': difference.abs(),
            'stockBefore': oldStock,
            'stockAfter': newStock,
            'note': 'Ajuste manual de stock',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showMessage('Producto actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error al actualizar producto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addStock(
    String productId,
    String productName,
    double currentStock,
    String unit,
  ) async {
    final controller = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('Agregar stock', style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$productName · Stock actual: ${_formatNumber(currentStock)} $unit',
                  style: const TextStyle(color: _textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cantidad a agregar',
                  prefixIcon: const Icon(Icons.add_box_outlined),
                  filled: true,
                  fillColor: _background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ej: Compra al proveedor',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  filled: true,
                  fillColor: _background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                final quantity = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                if (quantity == null || quantity <= 0) {
                  return;
                }
                Navigator.of(dialogContext).pop({
                  'quantity': quantity,
                  'note': noteController.text.trim(),
                });
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    noteController.dispose();

    if (result == null) return;

    final quantity = result['quantity'] as double;
    final note = result['note'] as String;

    try {
      final productRef = _products.doc(productId);
      final movementRef = _stockMovements.doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) {
          throw StateError('El producto ya no existe');
        }
        final data = snapshot.data() ?? {};
        final stockValue = data['stock'];
        final stockBefore = stockValue is num ? stockValue.toDouble() : 0.0;
        final stockAfter = stockBefore + quantity;

        transaction.update(productRef, {
          'stock': stockAfter,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(movementRef, {
          'businessId': widget.businessId,
          'productId': productId,
          'productName': productName,
          'type': 'entry',
          'quantity': quantity,
          'stockBefore': stockBefore,
          'stockAfter': stockAfter,
          'note': note.isEmpty ? 'Ingreso de stock' : note,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        _showMessage('Stock actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error al agregar stock: $e');
      }
    }
  }

  Future<void> _toggleActive(
    String productId,
    String productName,
    bool active,
  ) async {
    try {
      await _products.doc(productId).update({
        'active': !active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showMessage(
          !active
              ? '$productName activado'
              : '$productName desactivado',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error al cambiar el estado: $e');
      }
    }
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Eliminar producto',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '¿Querés eliminar "$productName"? Esta acción elimina el producto del catálogo, pero no borra las ventas históricas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _products.doc(productId).delete();
      if (mounted) {
        _showMessage('Producto eliminado');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error al eliminar producto: $e');
      }
    }
  }

  void _showCreateProductDialog() {
    _clearForm();
    _showProductDialog(isEditing: false);
  }

  void _showEditProductDialog(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    _nameController.text = data['name'] as String? ?? '';
    _priceController.text = _formatNumber(
      (data['price'] is num ? (data['price'] as num).toDouble() : 0),
    );
    _stockController.text = _formatNumber(
      (data['stock'] is num ? (data['stock'] as num).toDouble() : 0),
    );
    _selectedCategoryId = data['categoryId'] as String?;
    _selectedCategoryName = data['categoryName'] as String?;
    _selectedUnit = data['unit'] as String? ?? 'unidad';
    _selectedActive = data['active'] as bool? ?? true;
    _showProductDialog(isEditing: true, productId: document.id);
  }

  void _showProductDialog({required bool isEditing, String? productId}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: _primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Editar producto' : 'Nuevo producto',
                                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isEditing
                                      ? 'Actualizá la información del producto'
                                      : 'Completá los datos del producto',
                                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isSaving ? null : () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Información', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _nameController,
                        label: 'Nombre',
                        hint: 'Ej: Coca Cola',
                        icon: Icons.inventory_2_outlined,
                        autofocus: !isEditing,
                      ),
                      const SizedBox(height: 14),
                      _categoryField(setDialogState),
                      const SizedBox(height: 24),
                      const Text('Valores', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _textField(
                              controller: _priceController,
                              label: 'Precio',
                              hint: '2500',
                              icon: Icons.attach_money,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              controller: _stockController,
                              label: 'Stock',
                              hint: '10',
                              icon: Icons.inventory_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: _inputDecoration('Unidad', Icons.straighten_outlined),
                        items: const [
                          DropdownMenuItem(value: 'unidad', child: Text('Unidad')),
                          DropdownMenuItem(value: 'kg', child: Text('Kilogramos')),
                          DropdownMenuItem(value: 'g', child: Text('Gramos')),
                          DropdownMenuItem(value: 'litro', child: Text('Litros')),
                          DropdownMenuItem(value: 'ml', child: Text('Mililitros')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => _selectedUnit = value);
                        },
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 14),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: const Text('Producto activo', style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            _selectedActive
                                ? 'Disponible para nuevas ventas'
                                : 'Oculto para nuevas ventas',
                            style: const TextStyle(color: _textSecondary),
                          ),
                          value: _selectedActive,
                          activeThumbColor: _primary,
                          onChanged: (value) => setDialogState(() => _selectedActive = value),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => isEditing
                                      ? _updateProduct(productId!)
                                      : _saveNewProduct(),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      isEditing ? 'Guardar cambios' : 'Crear producto',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _categoryField(StateSetter setDialogState) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _categories.where('businessId', isEqualTo: widget.businessId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(16)),
            child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Error al cargar categorías:\n${snapshot.error}',
            style: const TextStyle(color: Colors.redAccent),
          );
        }

        final categories = [...(snapshot.data?.docs ?? [])];
        categories.sort((a, b) {
          final nameA = a.data()['name'] as String? ?? '';
          final nameB = b.data()['name'] as String? ?? '';
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });

        if (categories.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(child: Text('Primero tenés que crear una categoría.')),
              ],
            ),
          );
        }

        final validSelectedId = categories.any((doc) => doc.id == _selectedCategoryId)
            ? _selectedCategoryId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: validSelectedId,
          decoration: _inputDecoration('Categoría', Icons.category_outlined),
          items: categories.map((document) {
            final name = document.data()['name'] as String? ?? 'Sin nombre';
            return DropdownMenuItem<String>(value: document.id, child: Text(name));
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            final selected = categories.firstWhere((document) => document.id == value);
            final name = selected.data()['name'] as String? ?? 'Sin nombre';
            setDialogState(() {
              _selectedCategoryId = value;
              _selectedCategoryName = name;
            });
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: _background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool autofocus = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _selectedCategoryId = null;
    _selectedCategoryName = null;
    _selectedUnit = 'unidad';
    _selectedActive = true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos',
              style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 24),
            ),
            SizedBox(height: 2),
            Text(
              'Gestioná el catálogo de tu negocio',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _showCreateProductDialog,
              style: IconButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(46, 46),
              ),
              icon: const Icon(Icons.add),
              tooltip: 'Nuevo producto',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProductDialog,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _products.where('businessId', isEqualTo: widget.businessId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final products = [...(snapshot.data?.docs ?? [])];
          products.sort((a, b) {
            final nameA = a.data()['name'] as String? ?? '';
            final nameB = b.data()['name'] as String? ?? '';
            return nameA.toLowerCase().compareTo(nameB.toLowerCase());
          });

          if (products.isEmpty) return _emptyState();

          int lowStockProducts = 0;
          int outOfStockProducts = 0;
          int inactiveProducts = 0;
          for (final product in products) {
            final data = product.data();
            final stockValue = data['stock'];
            final stock = stockValue is num ? stockValue.toDouble() : 0.0;
            final active = data['active'] as bool? ?? true;
            if (!active) inactiveProducts++;
            if (stock <= 0) {
              outOfStockProducts++;
            } else if (stock <= 5) {
              lowStockProducts++;
            }
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  _buildSummary(
                    products.length,
                    lowStockProducts,
                    outOfStockProducts,
                    inactiveProducts,
                    isWide,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Catálogo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (isWide)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisExtent: 250,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) => _buildProductCard(products[index]),
                    )
                  else
                    ...products.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProductCard(product),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.redAccent.shade100),
              const SizedBox(height: 14),
              const Text(
                'No se pudieron cargar los productos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.inventory_2_outlined, size: 44, color: _primary),
            ),
            const SizedBox(height: 22),
            const Text(
              'Todavía no tenés productos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Creá tu primer producto para empezar a administrar tu catálogo y stock.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateProductDialog,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear producto', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
    int total,
    int lowStock,
    int outOfStock,
    int inactive,
    bool isWide,
  ) {
    final cards = [
      _summaryCard(
        icon: Icons.inventory_2_outlined,
        title: 'Productos',
        value: '$total',
        subtitle: 'en catálogo',
        iconColor: _primary,
      ),
      _summaryCard(
        icon: Icons.warning_amber_rounded,
        title: 'Stock bajo',
        value: '$lowStock',
        subtitle: 'hasta 5 unidades',
        iconColor: Colors.orange,
      ),
      _summaryCard(
        icon: Icons.remove_shopping_cart_outlined,
        title: 'Sin stock',
        value: '$outOfStock',
        subtitle: 'requieren reposición',
        iconColor: Colors.redAccent,
      ),
      _summaryCard(
        icon: Icons.pause_circle_outline,
        title: 'Inactivos',
        value: '$inactive',
        subtitle: 'no disponibles',
        iconColor: Colors.grey,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(padding: const EdgeInsets.only(right: 12), child: card),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                Text(subtitle, style: const TextStyle(color: _textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final name = data['name'] as String? ?? 'Sin nombre';
    final category = data['categoryName'] as String? ?? 'Sin categoría';
    final unit = data['unit'] as String? ?? 'unidad';
    final price = data['price'];
    final stock = data['stock'];
    final active = data['active'] as bool? ?? true;
    final stockValue = stock is num ? stock.toDouble() : 0.0;
    final priceValue = price is num ? price.toDouble() : 0.0;

    final outOfStock = stockValue <= 0;
    final lowStock = stockValue > 0 && stockValue <= 5;
    final statusColor = outOfStock
        ? Colors.redAccent
        : lowStock
            ? Colors.orange
            : Colors.green;
    final statusText = outOfStock
        ? 'Sin stock'
        : lowStock
            ? 'Stock bajo'
            : 'Disponible';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (active ? _primary : Colors.grey).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.inventory_2_outlined, color: active ? _primary : Colors.grey),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditProductDialog(document);
                      break;
                    case 'stock':
                      _addStock(document.id, name, stockValue, unit);
                      break;
                    case 'toggle':
                      _toggleActive(document.id, name, active);
                      break;
                    case 'history':
                      _showStockHistory(document.id, name, unit);
                      break;
                    case 'delete':
                      _deleteProduct(document.id, name);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 10), Text('Editar')]),
                  ),
                  const PopupMenuItem(
                    value: 'stock',
                    child: Row(children: [Icon(Icons.add_box_outlined), SizedBox(width: 10), Text('Agregar stock')]),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(active ? Icons.pause_circle_outline : Icons.play_circle_outline),
                        const SizedBox(width: 10),
                        Text(active ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(children: [Icon(Icons.history), SizedBox(width: 10), Text('Historial de stock')]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _productInfo(icon: Icons.sell_outlined, label: 'Precio', value: '\$${priceValue.toStringAsFixed(2)}')),
              const SizedBox(width: 10),
              Expanded(child: _productInfo(icon: Icons.inventory_outlined, label: 'Stock', value: '${_formatNumber(stockValue)} $unit')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(statusText, overflow: TextOverflow.ellipsis, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: (active ? Colors.green : Colors.grey).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  active ? 'Activo' : 'Inactivo',
                  style: TextStyle(color: active ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showStockHistory(String productId, String productName, String unit) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: _primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(productName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Movimientos de stock', style: TextStyle(color: _textSecondary)),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _stockMovements
                          .where('businessId', isEqualTo: widget.businessId)
                          .where('productId', isEqualTo: productId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('No se pudo cargar el historial:\n${snapshot.error}', textAlign: TextAlign.center));
                        }

                        final movements = [...(snapshot.data?.docs ?? [])];
                        movements.sort((a, b) {
                          final aDate = _dateFromValue(a.data()['createdAt']);
                          final bDate = _dateFromValue(b.data()['createdAt']);
                          if (aDate == null && bDate == null) return 0;
                          if (aDate == null) return 1;
                          if (bDate == null) return -1;
                          return bDate.compareTo(aDate);
                        });

                        if (movements.isEmpty) {
                          return const Center(child: Text('Todavía no hay movimientos de stock.'));
                        }

                        return ListView.separated(
                          itemCount: movements.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final data = movements[index].data();
                            final type = data['type'] as String? ?? 'movement';
                            final quantityValue = data['quantity'];
                            final quantity = quantityValue is num ? quantityValue.toDouble() : 0.0;
                            final afterValue = data['stockAfter'];
                            final stockAfter = afterValue is num ? afterValue.toDouble() : 0.0;
                            final date = _dateFromValue(data['createdAt']);
                            final isOut = type == 'adjustment_out' || type == 'sale';
                            final color = isOut ? Colors.redAccent : Colors.green;
                            final title = switch (type) {
                              'initial' => 'Stock inicial',
                              'entry' => 'Entrada de stock',
                              'adjustment_in' => 'Ajuste de entrada',
                              'adjustment_out' => 'Ajuste de salida',
                              'sale' => 'Venta',
                              _ => 'Movimiento',
                            };

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
                                    child: Icon(isOut ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 3),
                                        Text(
                                          data['note'] as String? ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: _textSecondary, fontSize: 12),
                                        ),
                                        if (date != null)
                                          Text(
                                            _formatDateTime(date),
                                            style: const TextStyle(color: _textSecondary, fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isOut ? '-' : '+'}${_formatNumber(quantity)} $unit',
                                        style: TextStyle(color: color, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 3),
                                      Text('Stock: ${_formatNumber(stockAfter)}', style: const TextStyle(color: _textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  Widget _productInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _textSecondary, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
