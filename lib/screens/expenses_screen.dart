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
  final TextEditingController _descriptionController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> _expenseCategories = [
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
    if (value is num) {
      return value.toDouble();
    }
    return 0;
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

    setDialogState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _showExpenseDialog({
    DocumentSnapshot<Map<String, dynamic>>? expense,
  }) async {
    final data = expense?.data();

    _descriptionController.text =
        data?['description']?.toString() ?? '';

    final existingAmount = data?['amount'];
    if (existingAmount is num) {
      _amountController.text = existingAmount.toString();
    } else {
      _amountController.clear();
    }

    final existingCategory = data?['category']?.toString() ?? 'Otros';
    _selectedCategory = _expenseCategories.contains(existingCategory)
        ? existingCategory
        : 'Otros';

    final existingDate = data?['date'];
    if (existingDate is Timestamp) {
      _selectedDate = existingDate.toDate();
    } else {
      _selectedDate = DateTime.now();
    }

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

              setDialogState(() {
                isSaving = true;
              });

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
                  setDialogState(() {
                    isSaving = false;
                  });
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
                      items: _expenseCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                _selectedCategory = value;
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () {
                              _selectDate(
                                dialogContext,
                                setDialogState,
                              );
                            },
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
    final description =
        data?['description']?.toString() ?? 'este gasto';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _expensesRef.doc(expense.id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto eliminado correctamente.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el gasto: $e'),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context, double totalExpenses, int count) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: colors.onPrimary,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gastos',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  count == 1
                      ? '1 gasto registrado'
                      : '$count gastos registrados',
                ),
                const SizedBox(height: 10),
                Text(
                  _formatAmount(totalExpenses),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final date = data?['date'];

    DateTime? expenseDate;
    if (date is Timestamp) {
      expenseDate = date.toDate();
    }

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
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: colors.onSecondaryContainer,
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

          final expenses = snapshot.data?.docs.toList() ??
              <DocumentSnapshot<Map<String, dynamic>>>[];

          expenses.sort((a, b) {
            final dateA = a.data()?['date'];
            final dateB = b.data()?['date'];
            var parsedA = DateTime(2000);
            var parsedB = DateTime(2000);

            if (dateA is Timestamp) {
              parsedA = dateA.toDate();
            }
            if (dateB is Timestamp) {
              parsedB = dateB.toDate();
            }

            return parsedB.compareTo(parsedA);
          });

          final totalExpenses = expenses.fold<double>(
            0,
            (total, expense) => total + _getAmount(expense),
          );

          if (expenses.isEmpty) {
            return _buildEmptyState(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth >= 900 ? 32.0 : 16.0;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  110,
                ),
                children: [
                  _buildHeader(
                    context,
                    totalExpenses,
                    expenses.length,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Movimientos de gastos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...expenses.map(
                    (expense) => _buildExpenseCard(
                      context,
                      expense,
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
