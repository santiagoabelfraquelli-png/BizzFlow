import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import './categories_screen.dart';
import './cash_screen.dart';
import './customers_screen.dart';
import './dashboard_screen.dart';
import './expenses_screen.dart';
import './products_screen.dart';
import './profile_screen.dart';
import './sales_history_screen.dart';
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
  final TextEditingController _businessNameController = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _createBusiness() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final businessName = _businessNameController.text.trim();

    if (businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá el nombre de tu negocio.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final businessRef = _firestore.collection('businesses').doc();

      await businessRef.set({
        'name': businessName,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(user.uid).set(
        {'businessId': businessRef.id},
        SetOptions(merge: true),
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el negocio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay una sesión iniciada.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final businessId = snapshot.data?.data()?['businessId']?.toString();

        if (businessId == null || businessId.isEmpty) {
          return _buildSetup(context);
        }

        return BusinessHomeScreen(businessId: businessId);
      },
    );
  }

  Widget _buildSetup(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar negocio')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configurá tu negocio',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Primero necesitamos algunos datos para comenzar a usar BizzFlow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _businessNameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nombre del negocio',
                    hintText: 'Ej: Mi almacén',
                    prefixIcon: const Icon(Icons.store_outlined),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isCreating ? null : _createBusiness,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Crear negocio',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
}

class BusinessHomeScreen extends StatelessWidget {
  final String businessId;

  const BusinessHomeScreen({super.key, required this.businessId});

  void _openModule(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final modules = <_ModuleItem>[
      _ModuleItem(
        title: 'Dashboard',
        subtitle: 'Resumen de tu negocio',
        icon: Icons.dashboard_rounded,
        color: colorScheme.primary,
        onTap: () => _openModule(
          context,
          DashboardScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Ventas',
        subtitle: 'Registrar nuevas ventas',
        icon: Icons.point_of_sale_rounded,
        color: Colors.blue,
        onTap: () => _openModule(
          context,
          SalesScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Historial de ventas',
        subtitle: 'Consultar ventas realizadas',
        icon: Icons.history_rounded,
        color: Colors.deepPurple,
        onTap: () => _openModule(
          context,
          SalesHistoryScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Caja',
        subtitle: 'Controlar ingresos y egresos',
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.green,
        onTap: () => _openModule(
          context,
          CashScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Stock',
        subtitle: 'Controlar existencias',
        icon: Icons.inventory_2_rounded,
        color: Colors.orange,
        onTap: () => _openModule(
          context,
          StockScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Categorías',
        subtitle: 'Organizar productos',
        icon: Icons.category_rounded,
        color: Colors.purple,
        onTap: () => _openModule(
          context,
          CategoriesScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Productos',
        subtitle: 'Administrar productos',
        icon: Icons.inventory_rounded,
        color: Colors.indigo,
        onTap: () => _openModule(
          context,
          ProductsScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Clientes',
        subtitle: 'Administrar clientes',
        icon: Icons.people_alt_rounded,
        color: Colors.teal,
        onTap: () => _openModule(
          context,
          CustomersScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Gastos',
        subtitle: 'Registrar y controlar gastos',
        icon: Icons.receipt_long_rounded,
        color: Colors.red,
        onTap: () => _openModule(
          context,
          ExpensesScreen(businessId: businessId),
        ),
      ),
      _ModuleItem(
        title: 'Mi perfil',
        subtitle: 'Datos y seguridad de tu cuenta',
        icon: Icons.person_rounded,
        color: Colors.cyan,
        onTap: () => _openModule(
          context,
          ProfileScreen(businessId: businessId),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'BizzFlow',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 900 ? 40.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeHeader(colorScheme: colorScheme),
                const SizedBox(height: 28),
                const Text(
                  'Módulos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Todo lo que necesitás para administrar tu negocio.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: modules.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 178,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _ModuleCard(module: module),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final ColorScheme colorScheme;

  const _WelcomeHeader({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola! 👋',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administrá tu negocio de forma simple y ordenada.',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.88),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 34,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _ModuleItem module;

  const _ModuleCard({required this.module});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final module = widget.module;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: _isHovered ? 5 : 1,
          shadowColor: module.color.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: _isHovered
                  ? module.color.withValues(alpha: 0.28)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: module.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: module.color.withValues(
                            alpha: _isHovered ? 0.18 : 0.11,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          module.icon,
                          color: module.color,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 180),
                        offset: _isHovered ? const Offset(0.12, 0) : Offset.zero,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: _isHovered
                              ? module.color
                              : colorScheme.onSurfaceVariant,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    module.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
