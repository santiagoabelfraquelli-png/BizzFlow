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

  bool _isSaving = false;

  CollectionReference<Map<String, dynamic>> get _products {
    return FirebaseFirestore.instance.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _categories {
    return FirebaseFirestore.instance.collection('categories');
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final stockText = _stockController.text.trim().replaceAll(',', '.');

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá un nombre para el producto'),
        ),
      );
      return;
    }

    if (_selectedCategoryId == null ||
        _selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná una categoría'),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    final stock = double.tryParse(stockText);

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá un precio válido'),
        ),
      );
      return;
    }

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá un stock válido'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _products.add({
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

      _nameController.clear();
      _priceController.clear();
      _stockController.clear();

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear producto: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(
    String productId,
    String productName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            '¿Querés eliminar el producto "$productName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _products.doc(productId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar producto: $e'),
          ),
        );
      }
    }
  }

  void _showCreateProductDialog() {
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();

    _selectedCategoryId = null;
    _selectedCategoryName = null;
    _selectedUnit = 'unidad';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo producto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Coca Cola',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _categories
                          .where(
                            'businessId',
                            isEqualTo: widget.businessId,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error al cargar categorías:\n${snapshot.error}',
                          );
                        }

                        final categories = snapshot.data?.docs ?? [];

                        categories.sort((a, b) {
                          final nameA =
                              a.data()['name'] as String? ?? '';
                          final nameB =
                              b.data()['name'] as String? ?? '';

                          return nameA
                              .toLowerCase()
                              .compareTo(nameB.toLowerCase());
                        });

                        if (categories.isEmpty) {
                          return const Text(
                            'Primero tenés que crear una categoría.',
                          );
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((document) {
                            final data = document.data();
                            final categoryName =
                                data['name'] as String? ?? 'Sin nombre';

                            return DropdownMenuItem<String>(
                              value: document.id,
                              child: Text(categoryName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            final selectedDocument = categories.firstWhere(
                              (document) => document.id == value,
                            );

                            final categoryName =
                                selectedDocument.data()['name'] as String? ??
                                    'Sin nombre';

                            setDialogState(() {
                              _selectedCategoryId = value;
                              _selectedCategoryName = categoryName;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        hintText: 'Ej: 2500',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _stockController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Stock inicial',
                        hintText: 'Ej: 10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'unidad',
                          child: Text('Unidad'),
                        ),
                        DropdownMenuItem(
                          value: 'kg',
                          child: Text('Kilogramos'),
                        ),
                        DropdownMenuItem(
                          value: 'g',
                          child: Text('Gramos'),
                        ),
                        DropdownMenuItem(
                          value: 'litro',
                          child: Text('Litros'),
                        ),
                        DropdownMenuItem(
                          value: 'ml',
                          child: Text('Mililitros'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          _selectedUnit = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProductDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _products
            .where(
              'businessId',
              isEqualTo: widget.businessId,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar productos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data?.docs ?? [];

          products.sort((a, b) {
            final nameA = a.data()['name'] as String? ?? '';
            final nameB = b.data()['name'] as String? ?? '';

            return nameA
                .toLowerCase()
                .compareTo(nameB.toLowerCase());
          });

          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tenés productos.\n\n'
                  'Presioná el botón + para crear el primero.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document = products[index];
              final data = document.data();

              final name = data['name'] as String? ?? 'Sin nombre';
              final category =
                  data['categoryName'] as String? ?? 'Sin categoría';
              final unit = data['unit'] as String? ?? 'unidad';

              final price = data['price'];
              final stock = data['stock'];

              String priceText;

              if (price is num) {
                priceText = '\$${price.toStringAsFixed(2)}';
              } else {
                priceText = '\$0.00';
              }

              String stockText;

              if (stock is num) {
                stockText = stock.toString();
              } else {
                stockText = '0';
              }

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$category\n'
                    'Precio: $priceText\n'
                    'Stock: $stockText $unit',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar',
                    onPressed: () {
                      _deleteProduct(
                        document.id,
                        name,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}