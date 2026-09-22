import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import './categories_screen.dart';
import './customers_screen.dart';
import './dashboard_screen.dart';
import './expenses_screen.dart';
import './products_screen.dart';
import './sales_screen.dart';
import './stock_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _businessNameController =
      TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _createBusiness() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final businessName = _businessNameController.text.trim();

    if (businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá el nombre de tu negocio.'),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final businessRef = _firestore.collection('businesses').doc();

      await businessRef.set({
        'name': businessName,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(user.uid).set(
        {
          'businessId': businessRef.id,
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al crear el negocio: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay una sesión iniciada.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userData = snapshot.data?.data();
        final businessId = userData?['businessId']?.toString();

        if (businessId == null || businessId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Configurar negocio'),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Configurá tu negocio',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Primero necesitamos algunos datos '
                        'para comenzar a usar BizzFlow.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _businessNameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del negocio',
                          hintText: 'Ej: Mi almacén',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.store_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _isCreating ? null : _createBusiness,
                          child: _isCreating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Crear negocio',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return BusinessHomeScreen(
          businessId: businessId,
        );
      },
    );
  }
}

class BusinessHomeScreen extends StatelessWidget {
  final String businessId;

  const BusinessHomeScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final modules = <_ModuleItem>[
      _ModuleItem(
        title: 'Dashboard',
        subtitle: 'Resumen de tu negocio',
        icon: Icons.dashboard_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: 'Ventas',
        subtitle: 'Registrar y consultar ventas',
        icon: Icons.point_of_sale_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SalesScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: 'Stock',
        subtitle: 'Controlar existencias',
        icon: Icons.inventory_2_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StockScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: 'Categorías',
        subtitle: 'Organizar productos',
        icon: Icons.category_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategoriesScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: 'Productos',
        subtitle: 'Administrar productos',
        icon: Icons.inventory_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductsScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: 'Clientes',
        subtitle: 'Administrar clientes',
        icon: Icons.people_outline,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomersScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
      _ModuleItem(
        title: 'Gastos',
        subtitle: 'Registrar y controlar gastos',
        icon: Icons.receipt_long_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpensesScreen(
                businessId: businessId,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BizzFlow'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel principal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Administrá tu negocio desde un solo lugar.',
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisExtent: 150,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final module = modules[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: module.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            module.icon,
                            size: 34,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          const Spacer(),
                          Text(
                            module.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            module.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
