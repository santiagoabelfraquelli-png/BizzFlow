import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockScreen extends StatefulWidget {
  final String businessId;

  const StockScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final Map<String, bool> _updatingProducts = {};

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance.collection('products');

  Future<void> _addStock({
    required String productId,
    required String productName,
    required double currentStock,
    required String unit,
  }) async {
    final controller = TextEditingController();

    final quantity = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Agregar stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stock actual: ${_formatNumber(currentStock)} $unit',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Cantidad a agregar',
                  hintText: 'Ej: 10',
                  suffixText: unit,
                  border: const OutlineInputBorder(),
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
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ingresá una cantidad mayor a cero.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (quantity == null) {
      return;
    }

    setState(() {
      _updatingProducts[productId] = true;
    });

    try {
      final productRef = _productsRef.doc(productId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw Exception(
              'El producto "$productName" ya no existe.',
            );
          }

          final data = snapshot.data();

          if (data == null) {
            throw Exception(
              'No se pudieron obtener los datos del producto.',
            );
          }

          if (data['businessId'] != widget.businessId) {
            throw Exception(
              'El producto no pertenece a este negocio.',
            );
          }

          final stockValue = data['stock'];

          if (stockValue is! num) {
            throw Exception(
              'El stock actual del producto no es válido.',
            );
          }

          final newStock = stockValue.toDouble() + quantity;

          transaction.update(productRef, {
            'stock': newStock,
          });
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se agregaron ${_formatNumber(quantity)} $unit de '
            '"$productName".',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar el stock: '
            '${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingProducts.remove(productId);
        });
      }
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  Color _stockColor(double stock) {
    if (stock <= 0) {
      return Colors.red;
    }

    if (stock <= 5) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _stockLabel(double stock, String unit) {
    if (stock <= 0) {
      return 'Sin stock';
    }

    if (stock <= 5) {
      return 'Stock bajo';
    }

    return '${_formatNumber(stock)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productsRef
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
                  'Error al cargar el stock:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data?.docs.toList() ?? [];

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
                  'Creá productos para comenzar a administrar el stock.',
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

              final productName =
                  data['name'] as String? ?? 'Sin nombre';

              final category =
                  data['categoryName'] as String? ?? 'Sin categoría';

              final unit =
                  data['unit'] as String? ?? 'unidad';

              final stockValue = data['stock'];

              final stock = stockValue is num
                  ? stockValue.toDouble()
                  : 0.0;

              final isUpdating =
                  _updatingProducts[document.id] == true;

              final stockColor = _stockColor(stock);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Icon(
                              stock <= 5
                                  ? Icons.warning_amber_outlined
                                  : Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(category),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatNumber(stock),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: stockColor,
                                ),
                              ),
                              Text(unit),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _stockLabel(stock, unit),
                              style: TextStyle(
                                color: stockColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: isUpdating
                                ? null
                                : () => _addStock(
                                      productId: document.id,
                                      productName: productName,
                                      currentStock: stock,
                                      unit: unit,
                                    ),
                            icon: isUpdating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Agregar stock'),
                          ),
                        ],
                      ),
                    ],
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