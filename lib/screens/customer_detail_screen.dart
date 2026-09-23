import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String businessId;
  final String customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.businessId,
    required this.customerId,
    required this.customerName,
  });

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year · $hour:$minute';
    }
    return 'Fecha pendiente';
  }

  Future<void> _showSaleDetail(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> sale,
  ) async {
    final data = sale.data() ?? <String, dynamic>{};
    final items = List<dynamic>.from(data['items'] as List? ?? const []);
    final total = _number(data['total']);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Detalle de compra'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatDate(data['createdAt']),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(
                        items[index] as Map,
                      );
                      final name = item['productName']?.toString() ?? 'Producto';
                      final quantity = _number(item['quantity']);
                      final unit = item['unit']?.toString() ?? 'unidad';
                      final subtotal = _number(item['subtotal']);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${quantity % 1 == 0 ? quantity.toInt() : quantity} $unit',
                        ),
                        trailing: Text(
                          _formatMoney(subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        _formatMoney(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId);

    final salesStream = FirebaseFirestore.instance
        .collection('sales')
        .where('businessId', isEqualTo: businessId)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Detalle del cliente',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: customerRef.snapshots(),
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customerSnapshot.hasError || !customerSnapshot.hasData) {
            return const Center(
              child: Text('No se pudo cargar el cliente.'),
            );
          }

          final customerData = customerSnapshot.data!.data();
          if (customerData == null ||
              customerData['businessId']?.toString() != businessId) {
            return const Center(
              child: Text('El cliente no pertenece a este negocio.'),
            );
          }

          final name = customerData['name']?.toString() ?? customerName;
          final phone = customerData['phone']?.toString() ?? '';
          final email = customerData['email']?.toString() ?? '';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: salesStream,
            builder: (context, salesSnapshot) {
              if (salesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (salesSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se pudo cargar el historial de compras.\n\n${salesSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final sales = (salesSnapshot.data?.docs ?? [])
                  .where((sale) {
                    final data = sale.data();
                    return data['businessId']?.toString() == businessId &&
                        data['customerId']?.toString() == customerId;
                  })
                  .toList();

              sales.sort((a, b) {
                final dateA = a.data()['createdAt'];
                final dateB = b.data()['createdAt'];
                if (dateA is Timestamp && dateB is Timestamp) {
                  return dateB.compareTo(dateA);
                }
                if (dateA is Timestamp) return -1;
                if (dateB is Timestamp) return 1;
                return 0;
              });

              final totalSpent = sales.fold<double>(
                0,
                (total, sale) => total + _number(sale.data()['total']),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(phone),
                              ],
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(email),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Compras',
                          value: sales.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payments_outlined,
                          title: 'Total comprado',
                          value: _formatMoney(totalSpent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Historial de compras',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  if (sales.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 42),
                          SizedBox(height: 12),
                          Text(
                            'Todavía no hay compras registradas para este cliente.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...sales.map(
                      (sale) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            _formatMoney(_number(sale.data()['total'])),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${_formatDate(sale.data()['createdAt'])} · '
                            '${(sale.data()['items'] as List?)?.length ?? 0} productos',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showSaleDetail(context, sale),
                        ),
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
