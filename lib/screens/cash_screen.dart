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

  double get _totalIncome {
    return _salesTotal + _manualIncomeTotal;
  }

  double get _totalExpense {
    return _expensesTotal + _manualExpenseTotal;
  }

  double get _balance {
    return _totalIncome - _totalExpense;
  }

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

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo movimiento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
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
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          type = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
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
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final description =
                        descriptionController.text.trim();

                    final amount = double.tryParse(
                      amountController.text.replaceAll(',', '.'),
                    );

                    if (description.isEmpty ||
                        amount == null ||
                        amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ingresá una descripción y un monto válido.',
                          ),
                        ),
                      );

                      return;
                    }

                    try {
                      await _firestore
                          .collection('cash_movements')
                          .add({
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

                      await _loadCash();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Movimiento agregado correctamente.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo guardar el movimiento.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
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

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 20,
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

  Widget _buildMovementTile(Map<String, dynamic> movement) {
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
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
          ),
        ),
        title: Text(description),
        subtitle: Text(
          '$sourceLabel · ${_formatDate(movement['date'])}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${_formatMoney(amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadCash,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showAddMovementDialog,
        icon: const Icon(Icons.add),
        label: const Text('Movimiento'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCash,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCash,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Saldo actual',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatMoney(_balance),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        title: 'Ingresos',
                        amount: _formatMoney(_totalIncome),
                        icon: Icons.trending_up,
                      ),
                      _buildSummaryCard(
                        title: 'Egresos',
                        amount: _formatMoney(_totalExpense),
                        icon: Icons.trending_down,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Movimientos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_movements.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Todavía no hay movimientos.',
                              ),
                            ),
                          ),
                        )
                      else
                        ..._movements.map(_buildMovementTile),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}