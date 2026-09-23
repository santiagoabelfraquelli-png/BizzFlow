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
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startOfWeek() {
    final today = _startOfToday();
    return today.subtract(Duration(days: today.weekday - 1));
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final salesQuery = firestore
        .collection('sales')
        .where('businessId', isEqualTo: businessId);
    final expensesQuery = firestore
        .collection('expenses')
        .where('businessId', isEqualTo: businessId);
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
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: salesQuery.snapshots(),
        builder: (context, salesSnapshot) {
          if (salesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (salesSnapshot.hasError) {
            return _ErrorView(
              message: 'Error al cargar las ventas:\n${salesSnapshot.error}',
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: expensesQuery.snapshots(),
            builder: (context, expensesSnapshot) {
              if (expensesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (expensesSnapshot.hasError) {
                return _ErrorView(
                  message:
                      'Error al cargar los gastos:\n${expensesSnapshot.error}',
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: productsQuery.snapshots(),
                builder: (context, productsSnapshot) {
                  if (productsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (productsSnapshot.hasError) {
                    return _ErrorView(
                      message:
                          'Error al cargar los productos:\n${productsSnapshot.error}',
                    );
                  }

                  final now = DateTime.now();
                  final todayStart = _startOfToday();
                  final tomorrowStart = todayStart.add(const Duration(days: 1));
                  final weekStart = _startOfWeek();
                  final monthStart = _startOfMonth();

                  final sales = salesSnapshot.data?.docs ?? [];
                  final expenses = expensesSnapshot.data?.docs ?? [];
                  final products = productsSnapshot.data?.docs ?? [];

                  double salesToday = 0;
                  double salesWeek = 0;
                  double salesMonth = 0;
                  int salesTodayCount = 0;
                  final Map<String, _ProductSales> productSales = {};

                  for (final sale in sales) {
                    final data = sale.data();
                    final createdAt = _dateFromValue(data['createdAt']);
                    final total = _number(data['total']);
                    if (createdAt == null) continue;

                    if (!createdAt.isBefore(tomorrowStart) &&
                        !createdAt.isBefore(todayStart)) {
                      salesToday += total;
                      salesTodayCount++;
                    } else if (createdAt.isAfter(todayStart.subtract(const Duration(microseconds: 1))) &&
                        createdAt.isBefore(tomorrowStart)) {
                      salesToday += total;
                      salesTodayCount++;
                    }

                    if (!createdAt.isBefore(weekStart) &&
                        createdAt.isBefore(now.add(const Duration(days: 1)))) {
                      salesWeek += total;
                    }
                    if (!createdAt.isBefore(monthStart) &&
                        createdAt.isBefore(now.add(const Duration(days: 1)))) {
                      salesMonth += total;
                    }

                    final items = data['items'];
                    if (items is List) {
                      for (final rawItem in items) {
                        if (rawItem is! Map) continue;
                        final name = rawItem['productName']?.toString().trim();
                        final quantity = _number(rawItem['quantity']);
                        if (name == null || name.isEmpty || quantity <= 0) continue;
                        final current = productSales[name] ??
                            _ProductSales(name: name, quantity: 0);
                        current.quantity += quantity;
                        productSales[name] = current;
                      }
                    }
                  }

                  double expensesToday = 0;
                  double expensesWeek = 0;
                  double expensesMonth = 0;

                  for (final expense in expenses) {
                    final data = expense.data();
                    final date = _dateFromValue(data['date']);
                    final amount = _number(data['amount']);
                    if (date == null) continue;

                    if (!date.isBefore(todayStart) && date.isBefore(tomorrowStart)) {
                      expensesToday += amount;
                    }
                    if (!date.isBefore(weekStart) && date.isBefore(now.add(const Duration(days: 1)))) {
                      expensesWeek += amount;
                    }
                    if (!date.isBefore(monthStart) && date.isBefore(now.add(const Duration(days: 1)))) {
                      expensesMonth += amount;
                    }
                  }

                  int outOfStock = 0;
                  int lowStock = 0;
                  for (final product in products) {
                    final stock = _number(product.data()['stock']);
                    if (stock <= 0) {
                      outOfStock++;
                    } else if (stock <= 5) {
                      lowStock++;
                    }
                  }

                  final topProducts = productSales.values.toList()
                    ..sort((a, b) => b.quantity.compareTo(a.quantity));

                  return _DashboardBody(
                    salesToday: salesToday,
                    salesWeek: salesWeek,
                    salesMonth: salesMonth,
                    expensesToday: expensesToday,
                    expensesWeek: expensesWeek,
                    expensesMonth: expensesMonth,
                    resultToday: salesToday - expensesToday,
                    salesTodayCount: salesTodayCount,
                    outOfStock: outOfStock,
                    lowStock: lowStock,
                    topProducts: topProducts.take(5).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class _DashboardBody extends StatelessWidget {
  final double salesToday;
  final double salesWeek;
  final double salesMonth;
  final double expensesToday;
  final double expensesWeek;
  final double expensesMonth;
  final double resultToday;
  final int salesTodayCount;
  final int outOfStock;
  final int lowStock;
  final List<_ProductSales> topProducts;

  const _DashboardBody({
    required this.salesToday,
    required this.salesWeek,
    required this.salesMonth,
    required this.expensesToday,
    required this.expensesWeek,
    required this.expensesMonth,
    required this.resultToday,
    required this.salesTodayCount,
    required this.outOfStock,
    required this.lowStock,
    required this.topProducts,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 900 ? 40.0 : 20.0;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padding, 20, padding, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(colorScheme: colorScheme),
              const SizedBox(height: 28),
              const Text(
                'Resumen de hoy',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Información de tu negocio en tiempo real.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              _MetricsGrid(
                salesToday: salesToday,
                expensesToday: expensesToday,
                resultToday: resultToday,
                salesTodayCount: salesTodayCount,
              ),
              const SizedBox(height: 30),
              _PeriodSummary(
                salesWeek: salesWeek,
                salesMonth: salesMonth,
                expensesWeek: expensesWeek,
                expensesMonth: expensesMonth,
              ),
              const SizedBox(height: 30),
              const Text(
                'Productos más vendidos',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Basado en las ventas registradas.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              _TopProductsCard(products: topProducts),
              const SizedBox(height: 30),
              const Text(
                'Estado del stock',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Productos que necesitan atención.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              _StockGrid(outOfStock: outOfStock, lowStock: lowStock),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Header({required this.colorScheme});

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
                  'Consultá las métricas más importantes de tu negocio.',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.insights_rounded, color: colorScheme.onPrimary, size: 46),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final double salesToday;
  final double expensesToday;
  final double resultToday;
  final int salesTodayCount;

  const _MetricsGrid({
    required this.salesToday,
    required this.expensesToday,
    required this.resultToday,
    required this.salesTodayCount,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        title: 'Ventas de hoy',
        value: '\$${salesToday.toStringAsFixed(2)}',
        icon: Icons.trending_up_rounded,
        color: Colors.blue,
      ),
      _MetricData(
        title: 'Cantidad de ventas',
        value: salesTodayCount.toString(),
        icon: Icons.point_of_sale_rounded,
        color: Colors.indigo,
      ),
      _MetricData(
        title: 'Gastos de hoy',
        value: '\$${expensesToday.toStringAsFixed(2)}',
        icon: Icons.receipt_long_rounded,
        color: Colors.red,
      ),
      _MetricData(
        title: 'Resultado de hoy',
        value: '\$${resultToday.toStringAsFixed(2)}',
        icon: Icons.account_balance_wallet_rounded,
        color: resultToday >= 0 ? Colors.green : Colors.red,
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 150,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  final double salesWeek;
  final double salesMonth;
  final double expensesWeek;
  final double expensesMonth;

  const _PeriodSummary({
    required this.salesWeek,
    required this.salesMonth,
    required this.expensesWeek,
    required this.expensesMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen por período',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Compará rápidamente ventas y gastos acumulados.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            final cards = [
              _PeriodData(
                title: 'Esta semana',
                sales: salesWeek,
                expenses: expensesWeek,
                icon: Icons.date_range_rounded,
              ),
              _PeriodData(
                title: 'Este mes',
                sales: salesMonth,
                expenses: expensesMonth,
                icon: Icons.calendar_month_rounded,
              ),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 170,
              ),
              itemBuilder: (context, index) => _PeriodCard(data: cards[index]),
            );
          },
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final _PeriodData data;
  const _PeriodCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = data.sales - data.expenses;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(data.icon, color: colors.primary),
                const SizedBox(width: 10),
                Text(data.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const Spacer(),
            Text('Ventas  \$${data.sales.toStringAsFixed(2)}'),
            const SizedBox(height: 5),
            Text('Gastos  \$${data.expenses.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'Resultado  \$${result.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: result >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<_ProductSales> products;
  const _TopProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: products.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Todavía no hay ventas registradas.'),
              )
            : Column(
                children: [
                  for (var i = 0; i < products.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        products[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Text(
                        _formatQuantity(products[i].quantity),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
              child: Icon(data.icon, color: data.color, size: 27),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
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
  const _StockGrid({required this.outOfStock, required this.lowStock});

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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 130,
          ),
          itemBuilder: (context, index) => _StockCard(data: cards[index]),
        );
      },
    );
  }
}

class _StockCard extends StatelessWidget {
  final _StockData data;
  const _StockCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
              child: Icon(data.icon, color: data.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              data.value.toString(),
              style: TextStyle(color: data.color, fontSize: 28, fontWeight: FontWeight.w800),
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

class _PeriodData {
  final String title;
  final double sales;
  final double expenses;
  final IconData icon;

  const _PeriodData({
    required this.title,
    required this.sales,
    required this.expenses,
    required this.icon,
  });
}

class _ProductSales {
  final String name;
  double quantity;

  _ProductSales({
    required this.name,
    required this.quantity,
  });
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
        ),
      ),
    );
  }
}
