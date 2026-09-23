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

  static const Color _pink = Color(0xFFE8A6B8);
  static const Color _green = Color(0xFF4CAF7D);
  static const Color _orange = Color(0xFFE39A3B);
  static const Color _red = Color(0xFFE45858);

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance.collection('products');

  CollectionReference<Map<String, dynamic>> get _stockMovementsRef =>
      FirebaseFirestore.instance.collection('stock_movements');

  Color _surface(ThemeData theme) => theme.colorScheme.surface;

  Color _card(ThemeData theme) =>
      theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.35 : 0.55,
      );

  Color _muted(ThemeData theme) =>
      theme.colorScheme.onSurface.withValues(alpha: 0.62);

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
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Agregar stock',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _pink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: _pink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock actual: ${_formatNumber(currentStock)} $unit',
                            style: TextStyle(
                              color: _muted(theme),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cantidad a agregar',
                  hintText: 'Ej: 10',
                  suffixText: unit,
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  filled: true,
                  fillColor: _card(theme),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _pink,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresá una cantidad mayor a cero.'),
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

    if (quantity == null || !mounted) return;

    setState(() {
      _updatingProducts[productId] = true;
    });

    try {
      final productRef = _productsRef.doc(productId);
      final movementRef = _stockMovementsRef.doc();

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw Exception('El producto "$productName" ya no existe.');
          }

          final data = snapshot.data();

          if (data == null) {
            throw Exception(
              'No se pudieron obtener los datos del producto.',
            );
          }

          if (data['businessId']?.toString() != widget.businessId) {
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

          transaction.set(movementRef, {
            'businessId': widget.businessId,
            'productId': productId,
            'type': 'entry',
            'quantity': quantity,
            'stockAfter': newStock,
            'createdAt': FieldValue.serverTimestamp(),
            'note': 'Entrada manual de stock',
          });
        },
      );

      if (!mounted) return;

      _showMessage(
        'Se agregaron ${_formatNumber(quantity)} $unit de "$productName".',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'No se pudo actualizar el stock: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingProducts.remove(productId);
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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  Color _stockColor(double stock) {
    if (stock <= 0) return _red;
    if (stock <= 5) return _orange;
    return _green;
  }

  Color _stockBackgroundColor(double stock) {
    if (stock <= 0) return _red.withValues(alpha: 0.10);
    if (stock <= 5) return _orange.withValues(alpha: 0.10);
    return _green.withValues(alpha: 0.10);
  }

  String _stockLabel(double stock, String unit) {
    if (stock <= 0) return 'Sin stock';
    if (stock <= 5) return 'Stock bajo';
    return '${_formatNumber(stock)} $unit';
  }

  IconData _stockIcon(double stock) {
    if (stock <= 0) return Icons.remove_shopping_cart_outlined;
    if (stock <= 5) return Icons.warning_amber_rounded;
    return Icons.inventory_2_outlined;
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Controlá y actualizá el inventario de tu negocio.',
                  style: TextStyle(
                    color: _muted(theme),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _pink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    ThemeData theme,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    final totalProducts = products.length;
    int withoutStock = 0;
    int lowStock = 0;
    int available = 0;

    for (final product in products) {
      final value = product.data()['stock'];
      final stock = value is num ? value.toDouble() : 0.0;

      if (stock <= 0) {
        withoutStock++;
      } else if (stock <= 5) {
        lowStock++;
      } else {
        available++;
      }
    }

    final cards = [
      _SummaryCard(
        title: 'Productos',
        value: totalProducts.toString(),
        icon: Icons.inventory_2_outlined,
        iconColor: const Color(0xFF6C63A8),
      ),
      _SummaryCard(
        title: 'Disponibles',
        value: available.toString(),
        icon: Icons.check_circle_outline,
        iconColor: _green,
      ),
      _SummaryCard(
        title: 'Stock bajo',
        value: lowStock.toString(),
        icon: Icons.warning_amber_rounded,
        iconColor: _orange,
      ),
      _SummaryCard(
        title: 'Sin stock',
        value: withoutStock.toString(),
        icon: Icons.remove_shopping_cart_outlined,
        iconColor: _red,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;

          if (isWide) {
            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1)
                    const SizedBox(width: 12),
                ],
              ],
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    ThemeData theme,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final productName =
        data['name']?.toString().trim().isNotEmpty == true
            ? data['name'].toString()
            : 'Sin nombre';

    final category =
        data['categoryName']?.toString().trim().isNotEmpty == true
            ? data['categoryName'].toString()
            : 'Sin categoría';

    final unit =
        data['unit']?.toString().trim().isNotEmpty == true
            ? data['unit'].toString()
            : 'unidad';

    final stockValue = data['stock'];
    final stock = stockValue is num ? stockValue.toDouble() : 0.0;

    final isUpdating = _updatingProducts[document.id] == true;
    final stockColor = _stockColor(stock);
    final stockBackground = _stockBackgroundColor(stock);

    return Container(
      decoration: BoxDecoration(
        color: _surface(theme),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    color: stockBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _stockIcon(stock),
                    color: stockColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: _muted(theme),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _muted(theme),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: stockBackground,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _stockLabel(stock, unit),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: stockColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card(theme),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cantidad actual',
                          style: TextStyle(
                            color: _muted(theme),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatNumber(stock),
                              style: TextStyle(
                                color: stockColor,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Text(
                                unit,
                                style: TextStyle(
                                  color: _muted(theme),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _surface(theme),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      stock <= 5
                          ? Icons.priority_high_rounded
                          : Icons.trending_up_rounded,
                      color: stockColor,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isUpdating
                    ? null
                    : () => _addStock(
                          productId: document.id,
                          productName: productName,
                          currentStock: stock,
                          unit: unit,
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _pink.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.add_circle_outline,
                        size: 19,
                      ),
                label: Text(
                  isUpdating ? 'Actualizando...' : 'Agregar stock',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _surface(theme),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 34,
                  color: _pink,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Todavía no tenés productos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Creá productos para comenzar a administrar el stock de tu negocio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted(theme),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
    ThemeData theme,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 1200) {
          columns = 3;
        } else if (constraints.maxWidth >= 750) {
          columns = 2;
        }

        const spacing = 14.0;

        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: products
                .map(
                  (product) => SizedBox(
                    width: itemWidth,
                    child: _buildProductCard(theme, product),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Stock',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
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
              child: CircularProgressIndicator(color: _pink),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface(theme),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _red.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: _red,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No se pudo cargar el stock',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted(theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final products = snapshot.data?.docs.toList() ?? [];

          products.sort((a, b) {
            final nameA = a.data()['name']?.toString() ?? '';
            final nameB = b.data()['name']?.toString() ?? '';

            return nameA.toLowerCase().compareTo(
                  nameB.toLowerCase(),
                );
          });

          if (products.isEmpty) {
            return Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: _buildEmptyState(theme),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                _buildSummary(theme, products),
                _buildProductGrid(theme, products),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.62,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
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