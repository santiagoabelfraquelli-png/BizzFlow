import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomersScreen extends StatefulWidget {
  final String businessId;

  const CustomersScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection('customers');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showCustomerDialog({
    DocumentSnapshot<Map<String, dynamic>>? customer,
  }) async {
    final data = customer?.data();

    _nameController.text = data?['name']?.toString() ?? '';
    _phoneController.text = data?['phone']?.toString() ?? '';
    _emailController.text = data?['email']?.toString() ?? '';

    final isEditing = customer != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveCustomer() async {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();
              final email = _emailController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresá el nombre del cliente.'),
                  ),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                final customerData = <String, dynamic>{
                  'businessId': widget.businessId,
                  'name': name,
                  'phone': phone,
                  'email': email,
                };

                if (isEditing) {
                  await _customersRef
                      .doc(customer.id)
                      .update(customerData);
                } else {
                  customerData['createdAt'] =
                      FieldValue.serverTimestamp();

                  await _customersRef.add(customerData);
                }

                if (!mounted || !dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Cliente actualizado correctamente.'
                          : 'Cliente creado correctamente.',
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
                      'Error al guardar el cliente: $e',
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
                isEditing ? 'Editar cliente' : 'Nuevo cliente',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
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
                  onPressed: isSaving ? null : saveCustomer,
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
                              : 'Crear cliente',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
  }

  Future<void> _deleteCustomer(
    DocumentSnapshot<Map<String, dynamic>> customer,
  ) async {
    final data = customer.data();
    final name = data?['name']?.toString() ?? 'este cliente';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cliente'),
          content: Text(
            '¿Seguro que querés eliminar a "$name"?',
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
      await _customersRef.doc(customer.id).delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente eliminado correctamente.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al eliminar el cliente: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCustomerDialog();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _customersRef
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
                  'Ocurrió un error al cargar los clientes.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final customers = snapshot.data?.docs.toList() ?? [];

          customers.sort((a, b) {
            final nameA =
                a.data()['name']?.toString().toLowerCase() ?? '';
            final nameB =
                b.data()['name']?.toString().toLowerCase() ?? '';

            return nameA.compareTo(nameB);
          });

          if (customers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 72,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Todavía no tenés clientes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Agregá clientes para empezar a llevar '
                      'un registro de tu negocio.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        _showCustomerDialog();
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Agregar cliente'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final data = customer.data();

              final name = data['name']?.toString() ?? '';
              final phone = data['phone']?.toString() ?? '';
              final email = data['email']?.toString() ?? '';

              final hasContactData =
                  phone.isNotEmpty || email.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty
                          ? name.substring(0, 1).toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: hasContactData
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (phone.isNotEmpty)
                                Text('Teléfono: $phone'),
                              if (email.isNotEmpty)
                                Text('Email: $email'),
                            ],
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Sin datos de contacto',
                          ),
                        ),
                  isThreeLine:
                      phone.isNotEmpty && email.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCustomerDialog(
                          customer: customer,
                        );
                      } else if (value == 'delete') {
                        _deleteCustomer(customer);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}