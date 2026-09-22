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
    return _startOfToday().add(
      const Duration(days: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final todayStart = Timestamp.fromDate(
      _startOfToday(),
    );

    final tomorrowStart = Timestamp.fromDate(
      _startOfTomorrow(),
    );

    final salesQuery = firestore
        .collection('sales')
        .where('businessId', isEqualTo: businessId)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: todayStart,
        )
        .where(
          'createdAt',
          isLessThan: tomorrowStart,
        );

    final expensesQuery = firestore
        .collection('expenses')
        .where('businessId', isEqualTo: businessId)
        .where(
          'date',
          isGreaterThanOrEqualTo: todayStart,
        )
        .where(
          'date',
          isLessThan: tomorrowStart,
        );

    final productsQuery = firestore
        .collection('products')
        .where('businessId', isEqualTo: businessId);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: salesQuery.snapshots(),
        builder: (context, salesSnapshot) {
          if (salesSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (salesSnapshot.hasError) {
            return _ErrorView(
              message:
                  'Error al cargar las ventas:\n${salesSnapshot.error}',
            );
          }

          final sales = salesSnapshot.data?.docs ?? [];

          double totalSales = 0;

          for (final sale in sales) {
            final total = sale.data()['total'];

            if (total is num) {
              totalSales += total.toDouble();
            }
          }

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: expensesQuery.snapshots(),
            builder: (context, expensesSnapshot) {
              if (expensesSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (expensesSnapshot.hasError) {
                return _ErrorView(
                  message:
                      'Error al cargar los gastos:\n${expensesSnapshot.error}',
                );
              }

              final expenses =
                  expensesSnapshot.data?.docs ?? [];

              double totalExpenses = 0;

              for (final expense in expenses) {
                final amount = expense.data()['amount'];

                if (amount is num) {
                  totalExpenses += amount.toDouble();
                }
              }

              return StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: productsQuery.snapshots(),
                builder: (context, productsSnapshot) {
                  if (productsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (productsSnapshot.hasError) {
                    return _ErrorView(
                      message:
                          'Error al cargar los productos:\n${productsSnapshot.error}',
                    );
                  }

                  final products =
                      productsSnapshot.data?.docs ?? [];

                  int outOfStock = 0;
                  int lowStock = 0;

                  for (final product in products) {
                    final stock = product.data()['stock'];

                    if (stock is num) {
                      if (stock <= 0) {
                        outOfStock++;
                      } else if (stock <= 5) {
                        lowStock++;
                      }
                    }
                  }

                  final result = totalSales - totalExpenses;

                  return _DashboardBody(
                    totalSales: totalSales,
                    totalExpenses: totalExpenses,
                    result: result,
                    salesCount: sales.length,
                    outOfStock: outOfStock,
                    lowStock: lowStock,
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

class _DashboardBody extends StatelessWidget {
  final double totalSales;
  final double totalExpenses;
  final double result;
  final int salesCount;
  final int outOfStock;
  final int lowStock;

  const _DashboardBody({
    required this.totalSales,
    required this.totalExpenses,
    required this.result,
    required this.salesCount,
    required this.outOfStock,
    required this.lowStock,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding =
            constraints.maxWidth >= 900 ? 40.0 : 20.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            padding,
            20,
            padding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(colorScheme: colorScheme),
              const SizedBox(height: 28),
              const Text(
                'Resumen de hoy',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Información de tu negocio en tiempo real.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _MetricsGrid(
                totalSales: totalSales,
                totalExpenses: totalExpenses,
                result: result,
                salesCount: salesCount,
              ),
              const SizedBox(height: 32),
              const Text(
                'Estado del stock',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Productos que necesitan atención.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _StockGrid(
                outOfStock: outOfStock,
                lowStock: lowStock,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme colorScheme;

  const _Header({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu negocio, en un vistazo',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consultá las métricas más importantes de hoy.',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(
                      alpha: 0.85,
                    ),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.insights_rounded,
            color: colorScheme.onPrimary,
            size: 46,
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final double totalSales;
  final double totalExpenses;
  final double result;
  final int salesCount;

  const _MetricsGrid({
    required this.totalSales,
    required this.totalExpenses,
    required this.result,
    required this.salesCount,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        title: 'Ventas de hoy',
        value: '\$${totalSales.toStringAsFixed(2)}',
        icon: Icons.trending_up_rounded,
        color: Colors.blue,
      ),
      _MetricData(
        title: 'Cantidad de ventas',
        value: salesCount.toString(),
        icon: Icons.point_of_sale_rounded,
        color: Colors.indigo,
      ),
      _MetricData(
        title: 'Gastos de hoy',
        value: '\$${totalExpenses.toStringAsFixed(2)}',
        icon: Icons.receipt_long_rounded,
        color: Colors.red,
      ),
      _MetricData(
        title: 'Resultado',
        value: '\$${result.toStringAsFixed(2)}',
        icon: Icons.account_balance_wallet_rounded,
        color: result >= 0 ? Colors.green : Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 900) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 150,
          ),
          itemBuilder: (context, index) {
            return _MetricCard(
              data: cards[index],
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 27,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
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

class _StockGrid extends StatelessWidget {
  final int outOfStock;
  final int lowStock;

  const _StockGrid({
    required this.outOfStock,
    required this.lowStock,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StockData(
        title: 'Sin stock',
        subtitle: 'Productos agotados',
        value: outOfStock,
        icon: Icons.inventory_2_rounded,
        color: Colors.red,
      ),
      _StockData(
        title: 'Stock bajo',
        subtitle: '5 unidades o menos',
        value: lowStock,
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 130,
          ),
          itemBuilder: (context, index) {
            return _StockCard(
              data: cards[index],
            );
          },
        );
      },
    );
  }
}

class _StockCard extends StatelessWidget {
  final _StockData data;

  const _StockCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                data.icon,
                color: data.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              data.value.toString(),
              style: TextStyle(
                color: data.color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StockData {
  final String title;
  final String subtitle;
  final int value;
  final IconData icon;
  final Color color;

  const _StockData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 520,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}