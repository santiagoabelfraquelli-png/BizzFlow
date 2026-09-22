import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  final String businessId;

  const CategoriesScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _nameController = TextEditingController();

  bool _isSaving = false;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      FirebaseFirestore.instance.collection('categories');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _categoriesRef.add({
        'businessId': widget.businessId,
        'name': name,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _nameController.clear();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría creada correctamente.'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear la categoría: ${e.message ?? e.code}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(
    String categoryId,
    String categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text(
            '¿Querés eliminar la categoría "$categoryName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      await _categoriesRef.doc(categoryId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría eliminada.'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la categoría: ${e.message ?? e.code}',
          ),
        ),
      );
    }
  }

  void _showCreateCategoryDialog() {
    _nameController.clear();

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva categoría'),
              content: TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Bebidas',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  setDialogState(() {});
                },
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: _isSaving || _nameController.text.trim().isEmpty
                      ? null
                      : () async {
                          await _createCategory();
                        },
                  child: _isSaving
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoriesRef
            .where('businessId', isEqualTo: widget.businessId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar las categorías.\n\n'
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

          final categories = snapshot.data?.docs.toList() ?? [];

          categories.sort((a, b) {
            final nameA = (a.data()['name'] ?? '').toString().toLowerCase();
            final nameB = (b.data()['name'] ?? '').toString().toLowerCase();

            return nameA.compareTo(nameB);
          });

          if (categories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tenés categorías.\n'
                  'Creá la primera con el botón +.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = categories[index];
              final data = doc.data();

              final name = (data['name'] ?? 'Sin nombre').toString();
              final active = data['active'] != false;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.category_outlined),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    active ? 'Activa' : 'Inactiva',
                  ),
                  trailing: IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _deleteCategory(doc.id, name);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Categoría'),
      ),
    );
  }
}