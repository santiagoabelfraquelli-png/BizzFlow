import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CashScreen extends StatefulWidget {
  final String businessId;

  const CashScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;
  double _salesTotal = 0;
  double _expensesTotal = 0;
  double _manualIncomeTotal = 0;
  double _manualExpenseTotal = 0;
  List<Map<String, dynamic>> _movements = [];

  @override
  void initState() {
    super.initState();
    _loadCash();
  }

  Future<void> _loadCash() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final salesSnapshot = await _firestore
          .collection('sales')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      final cashSnapshot = await _firestore
          .collection('cash_movements')
          .where('businessId', isEqualTo: widget.businessId)
          .get();

      double salesTotal = 0;
      double expensesTotal = 0;
      double manualIncomeTotal = 0;
      double manualExpenseTotal = 0;
      final movements = <Map<String, dynamic>>[];

      for (final doc in salesSnapshot.docs) {
        final data = doc.data();
        final total = _toDouble(data['total']);
        salesTotal += total;

        movements.add({
          'type': 'income',
          'amount': total,
          'description': 'Venta',
          'date': data['createdAt'],
          'source': 'sale',
        });
      }

      for (final doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = _toDouble(data['amount']);
        expensesTotal += amount;

        movements.add({
          'type': 'expense',
          'amount': amount,
          'description': data['description'] ?? 'Gasto',
          'date': data['date'] ?? data['createdAt'],
          'source': 'expense',
        });
      }

      for (final doc in cashSnapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString() ?? 'income';
        final amount = _toDouble(data['amount']);

        if (type == 'income') {
          manualIncomeTotal += amount;
        } else {
          manualExpenseTotal += amount;
        }

        movements.add({
          'type': type,
          'amount': amount,
          'description': data['description'] ?? 'Movimiento',
          'date': data['date'] ?? data['createdAt'],
          'source': 'manual',
        });
      }

      movements.sort((a, b) {
        final dateA = _toDateTime(a['date']);
        final dateB = _toDateTime(b['date']);
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        _salesTotal = salesTotal;
        _expensesTotal = expensesTotal;
        _manualIncomeTotal = manualIncomeTotal;
        _manualExpenseTotal = manualExpenseTotal;
        _movements = movements;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la caja.';
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime(1970);
  }

  double get _totalIncome => _salesTotal + _manualIncomeTotal;

  double get _totalExpense => _expensesTotal + _manualExpenseTotal;

  double get _balance => _totalIncome - _totalExpense;

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    final date = _toDateTime(value);

    if (date.year == 1970) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Future<void> _showAddMovementDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'income';
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveMovement() async {
              final description = descriptionController.text.trim();
              final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );

              if (description.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ingresá una descripción y un monto válido.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await _firestore.collection('cash_movements').add({
                  'businessId': widget.businessId,
                  'type': type,
                  'amount': amount,
                  'description': description,
                  'date': Timestamp.fromDate(selectedDate),
                  'createdAt': FieldValue.serverTimestamp(),
                  'source': 'manual',
                });

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Movimiento agregado correctamente.',
                      ),
                    ),
                  );
                }

                await _loadCash();
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  isSaving = false;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se pudo guardar el movimiento.',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Nuevo movimiento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(
                          type == 'income'
                              ? Icons.trending_up
                              : Icons.trending_down,
                        ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Ingreso'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Egreso'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                type = value;
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Ej: Dinero inicial',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: const Icon(Icons.attach_money),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_formatDate(selectedDate)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : saveMovement,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();
    amountController.dispose();
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final positive = _balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.onPrimary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Saldo actual',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatMoney(_balance),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            positive ? 'Saldo disponible' : 'Saldo negativo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: theme.textTheme.titleLarge?.copyWith(
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

  Widget _buildMovementTile(
    BuildContext context,
    Map<String, dynamic> movement,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final type = movement['type']?.toString() ?? 'income';
    final amount = _toDouble(movement['amount']);
    final description =
        movement['description']?.toString() ?? 'Movimiento';
    final source = movement['source']?.toString() ?? 'manual';
    final isIncome = type == 'income';

    String sourceLabel;
    switch (source) {
      case 'sale':
        sourceLabel = 'Venta';
        break;
      case 'expense':
        sourceLabel = 'Gasto';
        break;
      default:
        sourceLabel = 'Manual';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isIncome
                    ? colors.secondaryContainer
                    : colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIncome
                    ? colors.onSecondaryContainer
                    : colors.onErrorContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$sourceLabel · ${_formatDate(movement['date'])}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isIncome ? '+' : '-'}${_formatMoney(amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMovements(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: colors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Todavía no hay movimientos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Los ingresos y egresos aparecerán acá.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Caja',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCash,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showAddMovementDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Movimiento'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 52,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _loadCash,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCash,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding =
                          constraints.maxWidth >= 900 ? 32.0 : 16.0;

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          110,
                        ),
                        children: [
                          _buildBalanceCard(context),
                          const SizedBox(height: 16),
                          Text(
                            'Resumen',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, summaryConstraints) {
                              if (summaryConstraints.maxWidth >= 650) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context: context,
                                        title: 'Ingresos',
                                        amount: _formatMoney(_totalIncome),
                                        icon: Icons.trending_up_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        context: context,
                                        title: 'Egresos',
                                        amount: _formatMoney(_totalExpense),
                                        icon: Icons.trending_down_rounded,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  _buildSummaryCard(
                                    context: context,
                                    title: 'Ingresos',
                                    amount: _formatMoney(_totalIncome),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryCard(
                                    context: context,
                                    title: 'Egresos',
                                    amount: _formatMoney(_totalExpense),
                                    icon: Icons.trending_down_rounded,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Movimientos',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_movements.isEmpty)
                            _buildEmptyMovements(context)
                          else
                            ..._movements.map(
                              (movement) => _buildMovementTile(
                                context,
                                movement,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}
