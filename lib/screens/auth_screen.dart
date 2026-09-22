import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

CollectionReference<Map<String, dynamic>> get _categories {
return FirebaseFirestore.instance.collection('categories');
}

Future<void> _createCategory() async {
final name = _nameController.text.trim();

if (name.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Ingresá un nombre para la categoría'),
    ),
  );
  return;
}

final user = FirebaseAuth.instance.currentUser;

if (user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No hay un usuario autenticado'),
    ),
  );
  return;
}

setState(() {
  _isSaving = true;
});

try {
  await _categories.add({
    'businessId': widget.businessId,
    'name': name,
    'createdAt': FieldValue.serverTimestamp(),
  });

  _nameController.clear();

  if (mounted) {
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Categoría creada correctamente'),
      ),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al crear categoría: $e'),
      ),
    );
  }
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
  await _categories.doc(categoryId).delete();

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Categoría eliminada'),
      ),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al eliminar categoría: $e'),
      ),
    );
  }
}

}

void _showCreateCategoryDialog() {
_nameController.clear();

showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          hintText: 'Ej: Bebidas',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _createCategory,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Crear'),
        ),
      ],
    );
  },
);

}

@override
void dispose() {
_nameController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Categorías'),
),
floatingActionButton: FloatingActionButton(
onPressed: _showCreateCategoryDialog,
child: const Icon(Icons.add),
),
body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
stream: _categories
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
'Error al cargar categorías:\n${snapshot.error}',
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

      final categories = snapshot.data?.docs ?? [];

      if (categories.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Todavía no hay categorías.\n\n'
              'Tocá el botón + para crear la primera.',
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
          final document = categories[index];
          final data = document.data();

          final name = data['name'] as String? ?? 'Sin nombre';

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.category),
              ),
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  _deleteCategory(
                    document.id,
                    name,
                  );
                },
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

