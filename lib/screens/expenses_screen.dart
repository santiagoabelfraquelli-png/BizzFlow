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
  final TextEditingController _amountController =
      TextEditingController();

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

  CollectionReference<Map<String, dynamic>> get _expensesRef {
    return _firestore.collection('expenses');
  }

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

  double _getAmount(
    DocumentSnapshot<Map<String, dynamic>> expense,
  ) {
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

    if (pickedDate == null) {
      return;
    }

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

    final existingCategory =
        data?['category']?.toString() ?? 'Otros';

    if (_expenseCategories.contains(existingCategory)) {
      _selectedCategory = existingCategory;
    } else {
      _selectedCategory = 'Otros';
    }

    final existingDate = data?['date'];

    if (existingDate is Timestamp) {
      _selectedDate = existingDate.toDate();
    } else {
      _selectedDate = DateTime.now();
    }

    final bool isEditing = expense != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            Future<void> saveExpense() async {
              final description =
                  _descriptionController.text.trim();

              final normalizedAmount =
                  _amountController.text.trim().replaceAll(',', '.');

              final double? amount =
                  double.tryParse(normalizedAmount);

              if (description.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ingresá una descripción para el gasto.',
                    ),
                  ),
                );
                return;
              }

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ingresá un monto válido mayor a cero.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final Map<String, dynamic> expenseData = {
                  'businessId': widget.businessId,
                  'description': description,
                  'amount': amount,
                  'category': _selectedCategory,
                  'date': Timestamp.fromDate(_selectedDate),
                };

                if (isEditing) {
                  await _expensesRef
                      .doc(expense.id)
                      .update(expenseData);
                } else {
                  expenseData['createdAt'] =
                      FieldValue.serverTimestamp();

                  await _expensesRef.add(expenseData);
                }

                if (!mounted || !dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted) {
                  return;
                }

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
                if (!mounted || !dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error al guardar el gasto: $e',
                    ),
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
              title: Text(
                isEditing ? 'Editar gasto' : 'Nuevo gasto',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText: 'Ej: Compra de materiales',
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto *',
                        hintText: 'Ej: 15000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.category_outlined),
                      ),
                      items: _expenseCategories.map(
                        (category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        },
                      ).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setDialogState(() {
                                _selectedCategory = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () {
                              _selectDate(
                                dialogContext,
                                setDialogState,
                              );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : saveExpense,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing
                              ? 'Guardar cambios'
                              : 'Registrar gasto',
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

    final String description =
        data?['description']?.toString() ?? 'este gasto';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar gasto'),
          content: Text(
            '¿Seguro que querés eliminar "$description"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _expensesRef.doc(expense.id).delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gasto eliminado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al eliminar el gasto: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showExpenseDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _expensesRef
            .where(
              'businessId',
              isEqualTo: widget.businessId,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ocurrió un error al cargar los gastos.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<DocumentSnapshot<Map<String, dynamic>>>
              expenses = snapshot.data?.docs.toList() ?? [];

          expenses.sort((a, b) {
            final dateA = a.data()?['date'];
            final dateB = b.data()?['date'];

            DateTime parsedA = DateTime(2000);
            DateTime parsedB = DateTime(2000);

            if (dateA is Timestamp) {
              parsedA = dateA.toDate();
            }

            if (dateB is Timestamp) {
              parsedB = dateB.toDate();
            }

            return parsedB.compareTo(parsedA);
          });

          final double totalExpenses = expenses.fold<double>(
            0,
            (total, expense) {
              return total + _getAmount(expense);
            },
          );

          if (expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 72,
                      color:
                          Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Todavía no tenés gastos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Registrá los gastos de tu negocio '
                      'para llevar un mejor control.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        _showExpenseDialog();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar gasto'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total de gastos',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(totalExpenses),
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
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    100,
                  ),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final data = expense.data();

                    final String description =
                        data?['description']?.toString() ?? '';

                    final String category =
                        data?['category']?.toString() ?? 'Otros';

                    final double amount =
                        _getAmount(expense);

                    final dynamic date = data?['date'];

                    DateTime? expenseDate;

                    if (date is Timestamp) {
                      expenseDate = date.toDate();
                    }

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.receipt_long_outlined,
                          ),
                        ),
                        title: Text(
                          description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                              const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(category),
                              if (expenseDate != null)
                                Text(
                                  _formatDate(expenseDate),
                                ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatAmount(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showExpenseDialog(
                                    expense: expense,
                                  );
                                }

                                if (value == 'delete') {
                                  _deleteExpense(expense);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Eliminar'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
