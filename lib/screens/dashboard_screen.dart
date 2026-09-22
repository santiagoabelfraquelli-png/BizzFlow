import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final String businessId;

  const DashboardScreen({
    super.key,
    required this.businessId,
  });

  DateTime _startOfToday() {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  DateTime _startOfTomorrow() {
    final today = _startOfToday();

    return today.add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final todayStart = Timestamp.fromDate(_startOfToday());
    final tomorrowStart = Timestamp.fromDate(_startOfTomorrow());

    final salesQuery = firestore
        .collection('sales')
        .where('businessId', isEqualTo: businessId)
        .where('createdAt', isGreaterThanOrEqualTo: todayStart)
        .where('createdAt', isLessThan: tomorrowStart);

    final expensesQuery = firestore
        .collection('expenses')
        .where('businessId', isEqualTo: businessId)
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .where('date', isLessThan: tomorrowStart);

    final productsQuery = firestore
        .collection('products')
        .where('businessId', isEqualTo: businessId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: salesQuery.snapshots(),
        builder: (context, salesSnapshot) {
          if (salesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (salesSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar las ventas:\n${salesSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final sales = salesSnapshot.data?.docs ?? [];

          double totalSales = 0;
          int salesCount = sales.length;

          for (final sale in sales) {
            final data = sale.data();
            final total = data['total'];

            if (total is num) {
              totalSales += total.toDouble();
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: expensesQuery.snapshots(),
            builder: (context, expensesSnapshot) {
              if (expensesSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (expensesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar los gastos:\n'
                    '${expensesSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final expenses = expensesSnapshot.data?.docs ?? [];

              double totalExpenses = 0;

              for (final expense in expenses) {
                final data = expense.data();
                final amount = data['amount'];

                if (amount is num) {
                  totalExpenses += amount.toDouble();
                }
              }

              final result = totalSales - totalExpenses;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: productsQuery.snapshots(),
                builder: (context, productsSnapshot) {
                  if (productsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (productsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar los productos:\n'
                        '${productsSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final products = productsSnapshot.data?.docs ?? [];

                  int outOfStock = 0;
                  int lowStock = 0;

                  for (final product in products) {
                    final data = product.data();
                    final stock = data['stock'];

                    if (stock is num) {
                      if (stock <= 0) {
                        outOfStock++;
                      } else if (stock <= 5) {
                        lowStock++;
                      }
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future<void>.delayed(
                        const Duration(milliseconds: 300),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen de hoy',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Información de tu negocio en tiempo real.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;

                              int columns = 1;

                              if (width >= 900) {
                                columns = 4;
                              } else if (width >= 600) {
                                columns = 2;
                              }

                              return GridView.count(
                                crossAxisCount: columns,
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.8,
                                children: [
                                  _DashboardCard(
                                    title: 'Ventas de hoy',
                                    value:
                                        '\$${totalSales.toStringAsFixed(2)}',
                                    icon: Icons.attach_money,
                                  ),
                                  _DashboardCard(
                                    title: 'Cantidad de ventas',
                                    value: salesCount.toString(),
                                    icon: Icons.point_of_sale_outlined,
                                  ),
                                  _DashboardCard(
                                    title: 'Gastos de hoy',
                                    value:
                                        '\$${totalExpenses.toStringAsFixed(2)}',
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                  _DashboardCard(
                                    title: 'Resultado',
                                    value:
                                        '\$${result.toStringAsFixed(2)}',
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'Estado del stock',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _StockStatusCard(
                                  title: 'Sin stock',
                                  value: outOfStock.toString(),
                                  icon: Icons.inventory_2_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StockStatusCard(
                                  title: 'Stock bajo',
                                  value: lowStock.toString(),
                                  icon: Icons.warning_amber_outlined,
                                ),
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
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StockStatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}