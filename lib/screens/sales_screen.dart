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

  _CartItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;
}

class _SalesScreenState extends State<SalesScreen> {
  final Map<String, _CartItem> _cart = <String, _CartItem>{};

  bool _isSaving = false;

  String? _selectedCustomerId;
  String? _selectedCustomerName;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance.collection('products');

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      FirebaseFirestore.instance.collection('sales');

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      FirebaseFirestore.instance.collection('customers');

  CollectionReference<Map<String, dynamic>> get _stockMovementsRef =>
      FirebaseFirestore.instance.collection('stock_movements');

  double get _total => _cart.values.fold<double>(
        0,
        (total, item) => total + item.subtotal,
      );

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  String _string(dynamic value, String fallback) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  Future<void> _addProductToCart(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    final name = _string(data['name'], 'Sin nombre');
    final unit = _string(data['unit'], 'unidad');

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

      if (!mounted) return;

      setState(() {
        existingItem.quantity += 1;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _cart[document.id] = _CartItem(
        productId: document.id,
        productName: name,
        unit: unit,
        unitPrice: price,
        quantity: 1,
      );
    });
  }

  void _removeFromCart(String productId) {
    if (!mounted) return;

    setState(() {
      _cart.remove(productId);
    });
  }

  Future<void> _selectCustomer() async {
    final snapshot = await _customersRef
        .where('businessId', isEqualTo: widget.businessId)
        .get();

    if (!mounted) return;

    final customers =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(snapshot.docs);

    customers.sort((a, b) {
      final nameA = _string(a.data()['name'], '').toLowerCase();
      final nameB = _string(b.data()['name'], '').toLowerCase();

      return nameA.compareTo(nameB);
    });

    if (customers.isEmpty) {
      _showMessage('No hay clientes registrados todavía.');
      return;
    }

    final selected =
        await showDialog<QueryDocumentSnapshot<Map<String, dynamic>>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Seleccionar cliente'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = customers[index];
                final data = customer.data();

                final name = _string(data['name'], 'Sin nombre');
                final phone = _string(data['phone'], '');

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(name),
                  subtitle: phone.isEmpty ? null : Text(phone),
                  onTap: () => Navigator.of(dialogContext).pop(customer),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (!mounted || selected == null) return;

    final data = selected.data();

    setState(() {
      _selectedCustomerId = selected.id;
      _selectedCustomerName = _string(data['name'], 'Sin nombre');
    });
  }

  void _clearCustomer() {
    if (!mounted) return;

    setState(() {
      _selectedCustomerId = null;
      _selectedCustomerName = null;
    });
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) {
      _showMessage('Agregá al menos un producto a la venta.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar venta'),
          content: Text(
            '¿Querés confirmar la venta por '
            '\$${_total.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final cartItems = List<_CartItem>.of(_cart.values);

      final selectedCustomerId = _selectedCustomerId;
      final selectedCustomerName = _selectedCustomerName;

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          DocumentSnapshot<Map<String, dynamic>>? customerSnapshot;

          if (selectedCustomerId != null) {
            final customerRef = _customersRef.doc(selectedCustomerId);

            customerSnapshot = await transaction.get(customerRef);

            if (!customerSnapshot.exists) {
              throw Exception('El cliente seleccionado ya no existe.');
            }

            final customerData = customerSnapshot.data();

            if (customerData == null ||
                customerData['businessId'] != widget.businessId) {
              throw Exception(
                'El cliente seleccionado no pertenece a este negocio.',
              );
            }
          }

          final productSnapshots =
              <String, DocumentSnapshot<Map<String, dynamic>>>{};

          for (final item in cartItems) {
            final productRef = _productsRef.doc(item.productId);

            final productSnapshot = await transaction.get(productRef);

            productSnapshots[item.productId] = productSnapshot;
          }

          final saleItems = <Map<String, dynamic>>[];

          var saleTotal = 0.0;

          // Primero validamos todos los productos y calculamos los cambios.
          final newStocks = <String, double>{};

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

            final productBusinessId = productData['businessId']?.toString();

            if (productBusinessId != widget.businessId) {
              throw Exception(
                'El producto "${item.productName}" '
                'no pertenece a este negocio.',
              );
            }

            if (productData['active'] == false) {
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
                'Stock disponible: '
                '${_formatStock(currentStock)} ${item.unit}.',
              );
            }

            final subtotal = currentPrice * item.quantity;
            final newStock = currentStock - item.quantity;

            newStocks[item.productId] = newStock;

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

          final saleData = <String, dynamic>{
            'businessId': widget.businessId,
            'items': saleItems,
            'total': saleTotal,
            'createdAt': FieldValue.serverTimestamp(),
          };

          if (selectedCustomerId != null &&
              customerSnapshot != null) {
            final customerData = customerSnapshot.data();

            saleData['customerId'] = selectedCustomerId;

            saleData['customerName'] = _string(
              customerData?['name'],
              selectedCustomerName ?? 'Cliente',
            );
          }

          // Actualizamos stock y registramos cada movimiento de venta.
          for (final item in cartItems) {
            final productRef = _productsRef.doc(item.productId);
            final movementRef = _stockMovementsRef.doc();

            final newStock = newStocks[item.productId]!;

            transaction.update(productRef, {
              'stock': newStock,
            });

            transaction.set(movementRef, {
              'businessId': widget.businessId,
              'productId': item.productId,
              'type': 'sale',
              'quantity': item.quantity,
              'stockAfter': newStock,
              'createdAt': FieldValue.serverTimestamp(),
              'note': 'Venta',
            });
          }

          // Guardamos la venta en la misma transacción.
          transaction.set(saleRef, saleData);
        },
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _selectedCustomerId = null;
        _selectedCustomerName = null;
      });

      _showMessage('Venta registrada correctamente.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'No se pudo registrar la venta: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) return;

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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
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

  Color _stockColor(double stock, ThemeData theme) {
    if (stock <= 0) return theme.colorScheme.error;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.point_of_sale_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ventas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productsRef
                  .where('businessId', isEqualTo: widget.businessId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(
                    theme,
                    snapshot.error.toString(),
                  );
                }

                final documents =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(
                  snapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                );

                documents.sort((a, b) {
                  final nameA = _string(a.data()['name'], '');
                  final nameB = _string(b.data()['name'], '');

                  return nameA
                      .toLowerCase()
                      .compareTo(nameB.toLowerCase());
                });

                if (documents.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    if (isWide) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          24,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 470,
                          mainAxisExtent: 205,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: documents.length,
                        itemBuilder: (context, index) =>
                            _buildProductCard(
                          documents[index],
                          theme,
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        24,
                      ),
                      itemCount: documents.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildProductCard(
                        documents[index],
                        theme,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_cart.isNotEmpty) _buildCart(theme),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar los productos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todavía no tenés productos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creá productos antes de registrar una venta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    ThemeData theme,
  ) {
    final data = document.data();

    final name = _string(data['name'], 'Sin nombre');
    final category = _string(data['categoryName'], 'Sin categoría');
    final unit = _string(data['unit'], 'unidad');
    final price = _number(data['price']);
    final stock = _number(data['stock']);
    final active = data['active'] != false;

    final alreadyInCart = _cart.containsKey(document.id);
    final stockColor = _stockColor(stock, theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildProductIcon(theme),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          _buildStockBadge(
                            stock,
                            unit,
                            stockColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: _buildAddButton(
                          document,
                          active,
                          stock,
                          alreadyInCart,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildProductIcon(theme),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '\$${price.toStringAsFixed(2)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _buildStockBadge(
                                    stock,
                                    unit,
                                    stockColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _buildAddButton(
                        document,
                        active,
                        stock,
                        alreadyInCart,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProductIcon(ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: theme.colorScheme.primary,
        size: 28,
      ),
    );
  }

  Widget _buildStockBadge(
    double stock,
    String unit,
    Color stockColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: stockColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Stock: ${_formatStock(stock)} $unit',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: stockColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAddButton(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    bool active,
    double stock,
    bool alreadyInCart,
  ) {
    return FilledButton.icon(
      onPressed: !active || stock <= 0 || _isSaving
          ? null
          : () => _addProductToCart(document),
      icon: Icon(
        alreadyInCart
            ? Icons.add_circle_outline_rounded
            : Icons.add_rounded,
        size: 18,
      ),
      label: Text(
        alreadyInCart ? 'Sumar' : 'Agregar',
      ),
    );
  }

  Widget _buildCustomerSelector(ThemeData theme) {
    final hasCustomer = _selectedCustomerId != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasCustomer
                                ? 'Cliente'
                                : 'Cliente opcional',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasCustomer
                                ? (_selectedCustomerName ??
                                    'Cliente seleccionado')
                                : 'Consumidor final',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasCustomer)
                      IconButton(
                        tooltip: 'Quitar cliente',
                        onPressed:
                            _isSaving ? null : _clearCustomer,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectCustomer,
                  icon: Icon(
                    hasCustomer
                        ? Icons.swap_horiz_rounded
                        : Icons.person_search_outlined,
                  ),
                  label: Text(
                    hasCustomer
                        ? 'Cambiar cliente'
                        : 'Elegir cliente',
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCustomer
                          ? 'Cliente'
                          : 'Cliente opcional',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCustomer
                          ? (_selectedCustomerName ??
                              'Cliente seleccionado')
                          : 'Consumidor final',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCustomer)
                IconButton(
                  tooltip: 'Quitar cliente',
                  onPressed: _isSaving ? null : _clearCustomer,
                  icon: const Icon(Icons.close_rounded),
                ),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _selectCustomer,
                icon: Icon(
                  hasCustomer
                      ? Icons.swap_horiz_rounded
                      : Icons.person_search_outlined,
                ),
                label: Text(
                  hasCustomer ? 'Cambiar' : 'Elegir',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCart(ThemeData theme) {
    final cartHeight =
        (_cart.length * 58.0 + 235.0).clamp(295.0, 440.0);

    return Material(
      elevation: 16,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: cartHeight,
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            18,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Venta actual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _cart.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color:
                        theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                  itemBuilder: (context, index) {
                    final item = _cart.values.elementAt(index);

                    return SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${_formatStock(item.quantity)} '
                                  '${item.unit} × '
                                  '\$${item.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar',
                            onPressed: _isSaving
                                ? null
                                : () =>
                                    _removeFromCart(item.productId),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _buildCustomerSelector(theme),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _confirmSale,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                        ),
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