import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesScreen extends StatefulWidget {
  final String businessId;

  const SalesScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _CartItem {
  final String productId;
  final String productName;
  final String unit;
  final double unitPrice;
  double quantity;
  double availableStock;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
    required this.availableStock,
  });

  double get subtotal => unitPrice * quantity;
}

class _SalesScreenState extends State<SalesScreen> {
  final Map<String, _CartItem> _cart = {};

  bool _isSaving = false;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance.collection('products');

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      FirebaseFirestore.instance.collection('sales');

  double get _total {
    return _cart.values.fold(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  Future<void> _addProductToCart(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    final name = data['name'] as String? ?? 'Sin nombre';
    final unit = data['unit'] as String? ?? 'unidad';

    final priceValue = data['price'];
    final stockValue = data['stock'];

    if (priceValue is! num || stockValue is! num) {
      _showMessage('El producto tiene precio o stock inválido.');
      return;
    }

    final price = priceValue.toDouble();
    final stock = stockValue.toDouble();

    if (stock <= 0) {
      _showMessage('No hay stock disponible de "$name".');
      return;
    }

    final existingItem = _cart[document.id];

    if (existingItem != null) {
      if (existingItem.quantity + 1 > stock) {
        _showMessage('No hay suficiente stock de "$name".');
        return;
      }

      setState(() {
        existingItem.quantity += 1;
      });

      return;
    }

    setState(() {
      _cart[document.id] = _CartItem(
        productId: document.id,
        productName: name,
        unit: unit,
        unitPrice: price,
        quantity: 1,
        availableStock: stock,
      );
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) {
      _showMessage('Agregá al menos un producto a la venta.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar venta'),
          content: Text(
            '¿Querés confirmar la venta por '
            '\$${_total.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final cartItems = _cart.values.toList();

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final productSnapshots = <String,
              DocumentSnapshot<Map<String, dynamic>>>{};

          for (final item in cartItems) {
            final productRef = _productsRef.doc(item.productId);

            final productSnapshot = await transaction.get(productRef);

            productSnapshots[item.productId] = productSnapshot;
          }

          final saleItems = <Map<String, dynamic>>[];
          var saleTotal = 0.0;

          for (final item in cartItems) {
            final productSnapshot = productSnapshots[item.productId];

            if (productSnapshot == null || !productSnapshot.exists) {
              throw Exception(
                'El producto "${item.productName}" ya no existe.',
              );
            }

            final productData = productSnapshot.data();

            if (productData == null) {
              throw Exception(
                'No se pudieron obtener los datos de '
                '"${item.productName}".',
              );
            }

            final businessId = productData['businessId'];

            if (businessId != widget.businessId) {
              throw Exception(
                'El producto "${item.productName}" no pertenece '
                'a este negocio.',
              );
            }

            final active = productData['active'] != false;

            if (!active) {
              throw Exception(
                'El producto "${item.productName}" está inactivo.',
              );
            }

            final priceValue = productData['price'];
            final stockValue = productData['stock'];

            if (priceValue is! num || stockValue is! num) {
              throw Exception(
                'El producto "${item.productName}" tiene datos inválidos.',
              );
            }

            final currentPrice = priceValue.toDouble();
            final currentStock = stockValue.toDouble();

            if (item.quantity > currentStock) {
              throw Exception(
                'No hay suficiente stock de "${item.productName}". '
                'Stock disponible: ${currentStock.toString()} ${item.unit}.',
              );
            }

            final subtotal = currentPrice * item.quantity;
            final newStock = currentStock - item.quantity;

            final productRef = _productsRef.doc(item.productId);

            transaction.update(productRef, {
              'stock': newStock,
            });

            saleItems.add({
              'productId': item.productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'unit': item.unit,
              'unitPrice': currentPrice,
              'subtotal': subtotal,
            });

            saleTotal += subtotal;
          }

          final saleRef = _salesRef.doc();

          transaction.set(saleRef, {
            'businessId': widget.businessId,
            'items': saleItems,
            'total': saleTotal,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cart.clear();
      });

      _showMessage('Venta registrada correctamente.');
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'No se pudo registrar la venta: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatStock(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productsRef
                  .where(
                    'businessId',
                    isEqualTo: widget.businessId,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar productos:\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final documents = snapshot.data?.docs.toList() ?? [];

                documents.sort((a, b) {
                  final nameA =
                      a.data()['name'] as String? ?? '';
                  final nameB =
                      b.data()['name'] as String? ?? '';

                  return nameA
                      .toLowerCase()
                      .compareTo(nameB.toLowerCase());
                });

                if (documents.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no tenés productos.\n\n'
                        'Creá productos antes de registrar una venta.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final data = document.data();

                    final name =
                        data['name'] as String? ?? 'Sin nombre';
                    final category =
                        data['categoryName'] as String? ??
                            'Sin categoría';
                    final unit =
                        data['unit'] as String? ?? 'unidad';

                    final priceValue = data['price'];
                    final stockValue = data['stock'];

                    final price = priceValue is num
                        ? priceValue.toDouble()
                        : 0.0;

                    final stock = stockValue is num
                        ? stockValue.toDouble()
                        : 0.0;

                    final active = data['active'] != false;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.inventory_2_outlined,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '$category\n'
                          'Precio: \$${price.toStringAsFixed(2)}\n'
                          'Stock: ${_formatStock(stock)} $unit',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: !active || stock <= 0 || _isSaving
                              ? null
                              : () => _addProductToCart(
                                    document,
                                  ),
                          child: const Text('Agregar'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_cart.isNotEmpty) _buildCart(),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Venta actual',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._cart.values.map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} '
                            '(${item.quantity} ${item.unit})',
                          ),
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                        ),
                        IconButton(
                          tooltip: 'Quitar',
                          onPressed: _isSaving
                              ? null
                              : () => _removeFromCart(
                                    item.productId,
                                  ),
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _confirmSale,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSaving
                        ? 'Registrando...'
                        : 'Confirmar venta',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}