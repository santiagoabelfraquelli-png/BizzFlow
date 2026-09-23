import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesHistoryScreen extends StatelessWidget {
  final String businessId;

  const SalesHistoryScreen({
    super.key,
    required this.businessId,
  });

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      FirebaseFirestore.instance.collection('sales');

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return 'Fecha pendiente';
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} · '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  double _number(dynamic value) => value is num ? value.toDouble() : 0;

  int _itemCount(dynamic value) {
    if (value is! List) return 0;
    return value.fold<int>(0, (total, item) {
      if (item is Map && item['quantity'] is num) {
        return total + (item['quantity'] as num).toInt();
      }
      return total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.history_rounded, color: colors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Historial de ventas',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _salesRef.where('businessId', isEqualTo: businessId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(theme, snapshot.error.toString());
          }

          final sales = List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          );

          sales.sort((a, b) {
            final aDate = a.data()['createdAt'];
            final bDate = b.data()['createdAt'];
            if (aDate is Timestamp && bDate is Timestamp) {
              return bDate.compareTo(aDate);
            }
            if (aDate is Timestamp) return -1;
            if (bDate is Timestamp) return 1;
            return 0;
          });

          if (sales.isEmpty) return _buildEmptyState(theme);

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 900 ? 40.0 : 16.0;
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  28,
                ),
                itemCount: sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = sales[index].data();
                  return _SaleCard(
                    dateText: _formatDate(data['createdAt']),
                    itemCount: _itemCount(data['items']),
                    total: _number(data['total']),
                    onTap: () => _showSaleDetail(context, data),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showSaleDetail(BuildContext context, Map<String, dynamic> data) {
    final items = data['items'] is List
        ? List<dynamic>.of(data['items'] as List)
        : <dynamic>[];
    final total = _number(data['total']);
    final dateText = _formatDate(data['createdAt']);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = theme.colorScheme;

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Detalle de venta',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dateText,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Esta venta no tiene productos registrados.'),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => Divider(
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, index) {
                          final raw = items[index];
                          final item = raw is Map
                              ? Map<String, dynamic>.from(raw)
                              : <String, dynamic>{};
                          final name = item['productName']?.toString().trim();
                          final quantity = _number(item['quantity']);
                          final unit = item['unit']?.toString() ?? 'unidad';
                          final unitPrice = _number(item['unitPrice']);
                          final subtotal = _number(item['subtotal']);

                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name == null || name.isEmpty ? 'Producto' : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatQuantity(quantity)} $unit × \$${unitPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '\$${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colors.primary),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colors = theme.colorScheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 38, color: colors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todavía no hay ventas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Las ventas que registres aparecerán acá.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    final colors = theme.colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar el historial',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final String dateText;
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const _SaleCard({
    required this.dateText,
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: colors.surfaceContainerHighest,
      shadowColor: colors.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 500;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _icon(colors),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            dateText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$itemCount ${itemCount == 1 ? 'producto' : 'productos'}',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.onSurfaceVariant),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  _icon(colors),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'producto' : 'productos'}',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(color: colors.primary, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15, color: colors.onSurfaceVariant),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _icon(ColorScheme colors) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.receipt_long_rounded, color: colors.primary),
    );
  }
}
