import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExpensesScreen extends StatefulWidget {
  final String businessId;

  const ExpensesScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> _expenseCategories = const [
    'Insumos',
    'Alquiler',
    'Servicios',
    'Transporte',
    'Sueldos',
    'Mantenimiento',
    'Otros',
  ];

  String _selectedCategory = 'Otros';
  DateTime _selectedDate = DateTime.now();
  String _periodFilter = 'Todos';

  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _firestore.collection('expenses');

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatAmount(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  double _getAmount(DocumentSnapshot<Map<String, dynamic>> expense) {
    final value = expense.data()?['amount'];
    if (value is num) return value.toDouble();
    return 0;
  }

  DateTime? _getExpenseDate(DocumentSnapshot<Map<String, dynamic>> expense) {
    final value = expense.data()?['date'];
    if (value is Timestamp) return value.toDate();
    return null;
  }

  bool _isInPeriod(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDay = DateTime(date.year, date.month, date.day);

    switch (_periodFilter) {
      case 'Hoy':
        return expenseDay == today;
      case 'Semana':
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !expenseDay.isBefore(start) && expenseDay.isBefore(end);
      case 'Mes':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  Future<void> _selectDate(
    BuildContext dialogContext,
    void Function(void Function()) setDialogState,
  ) async {
    final pickedDate = await showDatePicker(
      context: dialogContext,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    setDialogState(() => _selectedDate = pickedDate);
  }

  Future<void> _showExpenseDialog({
    DocumentSnapshot<Map<String, dynamic>>? expense,
  }) async {
    final data = expense?.data();
    _descriptionController.text = data?['description']?.toString() ?? '';

    final existingAmount = data?['amount'];
    _amountController.text = existingAmount is num
        ? existingAmount.toString()
        : '';

    final existingCategory = data?['category']?.toString() ?? 'Otros';
    _selectedCategory = _expenseCategories.contains(existingCategory)
        ? existingCategory
        : 'Otros';

    final existingDate = data?['date'];
    _selectedDate = existingDate is Timestamp
        ? existingDate.toDate()
        : DateTime.now();

    final isEditing = expense != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveExpense() async {
              final description = _descriptionController.text.trim();
              final normalizedAmount =
                  _amountController.text.trim().replaceAll(',', '.');
              final amount = double.tryParse(normalizedAmount);

              if (description.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresá una descripción para el gasto.'),
                  ),
                );
                return;
              }

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresá un monto válido mayor a cero.'),
                  ),
                );
                return;
              }

              setDialogState(() => isSaving = true);

              try {
                final expenseData = <String, dynamic>{
                  'businessId': widget.businessId,
                  'description': description,
                  'amount': amount,
                  'category': _selectedCategory,
                  'date': Timestamp.fromDate(_selectedDate),
                };

                if (isEditing) {
                  await _expensesRef.doc(expense.id).update(expenseData);
                } else {
                  expenseData['createdAt'] = FieldValue.serverTimestamp();
                  await _expensesRef.add(expenseData);
                }

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Gasto actualizado correctamente.'
                          : 'Gasto registrado correctamente.',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted || !dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar el gasto: $e'),
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Editar gasto' : 'Nuevo gasto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Descripción *',
                        hintText: 'Ej: Compra de materiales',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto *',
                        hintText: 'Ej: 15000',
                        prefixIcon: const Icon(Icons.attach_money),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: _expenseCategories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() => _selectedCategory = value);
                            },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () => _selectDate(
                                dialogContext,
                                setDialogState,
                              ),
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon:
                              const Icon(Icons.calendar_today_outlined),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_formatDate(_selectedDate)),
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
                  onPressed: isSaving ? null : saveExpense,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Guardar cambios' : 'Registrar gasto',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    _descriptionController.clear();
    _amountController.clear();
  }

  Future<void> _deleteExpense(
    DocumentSnapshot<Map<String, dynamic>> expense,
  ) async {
    final data = expense.data();
    final description = data?['description']?.toString() ?? 'este gasto';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Seguro que querés eliminar "$description"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _expensesRef.doc(expense.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto eliminado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el gasto: $e')),
      );
    }
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required double total,
    required int count,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerHighest],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 1
                          ? '1 movimiento registrado'
                          : '$count movimientos registrados',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Total del período',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAmount(total),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const periods = ['Todos', 'Hoy', 'Semana', 'Mes'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final selected = _periodFilter == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: selected,
              onSelected: (_) => setState(() => _periodFilter = period),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? colors.onPrimary : colors.onSurface,
              ),
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySummary(
    BuildContext context,
    List<DocumentSnapshot<Map<String, dynamic>>> expenses,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totals = <String, double>{};

    for (final expense in expenses) {
      final category = expense.data()?['category']?.toString() ?? 'Otros';
      totals[category] = (totals[category] ?? 0) + _getAmount(expense);
    }

    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por categoría',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...ordered.take(4).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _formatAmount(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> expense,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final data = expense.data();
    final description = data?['description']?.toString() ?? '';
    final category = data?['category']?.toString() ?? 'Otros';
    final amount = _getAmount(expense);
    final expenseDate = _getExpenseDate(expense);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.trending_down_rounded,
                color: colors.onErrorContainer,
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
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (expenseDate != null)
                        Text(
                          _formatDate(expenseDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.error,
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showExpenseDialog(expense: expense);
                    } else if (value == 'delete') {
                      _deleteExpense(expense);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 42,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Todavía no tenés gastos',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Registrá los gastos de tu negocio para llevar un mejor control.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _showExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar gasto'),
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
          'Gastos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _expensesRef
            .where('businessId', isEqualTo: widget.businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ocurrió un error al cargar los gastos.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allExpenses = snapshot.data?.docs.toList() ??
              <DocumentSnapshot<Map<String, dynamic>>>[];

          allExpenses.sort((a, b) {
            final dateA = _getExpenseDate(a) ?? DateTime(2000);
            final dateB = _getExpenseDate(b) ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          final filteredExpenses = allExpenses.where((expense) {
            final date = _getExpenseDate(expense);
            return date != null && _isInPeriod(date);
          }).toList();

          final totalExpenses = filteredExpenses.fold<double>(
            0,
            (total, expense) => total + _getAmount(expense),
          );

          if (allExpenses.isEmpty) {
            return _buildEmptyState(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 16.0;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  110,
                ),
                children: [
                  _buildSummaryCard(
                    context,
                    total: totalExpenses,
                    count: filteredExpenses.length,
                  ),
                  const SizedBox(height: 18),
                  _buildPeriodFilter(context),
                  const SizedBox(height: 22),
                  if (filteredExpenses.isNotEmpty) ...[
                    _buildCategorySummary(context, filteredExpenses),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Movimientos de gastos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filteredExpenses.isEmpty)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No hay gastos en este período.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredExpenses.map(
                      (expense) => _buildExpenseCard(context, expense),
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
