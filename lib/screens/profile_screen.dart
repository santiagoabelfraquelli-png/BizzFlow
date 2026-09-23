import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ordivo/services/app_preferences.dart';
import 'package:ordivo/services/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  final String businessId;

  const ProfileScreen({super.key, required this.businessId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();

  bool _isSaving = false;
  bool _isSendingVerification = false;
  bool _isSendingPasswordReset = false;
  bool _isResettingData = false;
  late bool _rememberLogin;

  AppPreferences get _appPreferences => ThemeController.instance.preferences;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController.text = user?.displayName ?? '';
    _rememberLogin = _appPreferences.rememberLogin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Ingresá tu nombre.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set(
        {
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        _showMessage('Datos actualizados correctamente.');
        setState(() {});
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          'No se pudieron guardar los datos: ${e.message ?? 'intentá nuevamente.'}',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudieron guardar los datos. Intentá nuevamente.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;

    setState(() => _isSendingVerification = true);

    try {
      await user.sendEmailVerification();
      if (mounted) {
        _showMessage('Te enviamos un nuevo correo de verificación.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(_authErrorMessage(e.code), isError: true);
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _refreshVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.reload();
    if (mounted) setState(() {});
  }

  Future<void> _sendPasswordReset() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) return;

    setState(() => _isSendingPasswordReset = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showMessage('Te enviamos un correo para cambiar tu contraseña.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(_authErrorMessage(e.code), isError: true);
    } finally {
      if (mounted) setState(() => _isSendingPasswordReset = false);
    }
  }

  Future<void> _resetBusinessData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();

        return AlertDialog(
          title: const Text('Reiniciar datos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción eliminará los datos operativos de este negocio: ventas, gastos, caja, productos, stock, clientes, categorías y movimientos de stock.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu cuenta, correo, contraseña y negocio no serán eliminados.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Escribí REINICIAR para confirmar',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                final value = controller.text.trim().toUpperCase();
                Navigator.of(context).pop(value == 'REINICIAR');
              },
              child: const Text('Reiniciar datos'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      _showMessage('La confirmación no fue válida.', isError: true);
      return;
    }

    setState(() => _isResettingData = true);

    try {
      const collections = [
        'sales',
        'expenses',
        'cash_movements',
        'products',
        'customers',
        'categories',
        'stock_movements',
      ];

      var deleted = 0;

      for (final collectionName in collections) {
        while (true) {
          final snapshot = await _firestore
              .collection(collectionName)
              .where('businessId', isEqualTo: widget.businessId)
              .limit(450)
              .get();

          if (snapshot.docs.isEmpty) break;

          final batch = _firestore.batch();
          for (final document in snapshot.docs) {
            batch.delete(document.reference);
          }

          await batch.commit();
          deleted += snapshot.docs.length;

          if (snapshot.docs.length < 450) break;
        }
      }

      if (mounted) {
        _showMessage('Datos reiniciados correctamente. Se eliminaron $deleted registros.');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          'No se pudieron reiniciar todos los datos: ${e.message ?? 'intentá nuevamente.'}',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudieron reiniciar los datos. Intentá nuevamente.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResettingData = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Querés cerrar la sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _auth.signOut();
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá unos minutos y probá nuevamente.';
      case 'network-request-failed':
        return 'No hay conexión con Internet.';
      default:
        return 'No se pudo completar la operación. Intentá nuevamente.';
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay una sesión iniciada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('businesses').doc(widget.businessId).snapshots(),
        builder: (context, businessSnapshot) {
          final businessName = businessSnapshot.data?.data()?['name']?.toString() ?? 'Sin negocio';

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 900 ? 40.0 : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(
                          name: user.displayName,
                          email: user.email ?? 'Sin correo',
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: 'Datos personales',
                          subtitle: 'Actualizá la información que identifica tu cuenta.',
                          icon: Icons.person_outline_rounded,
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Nombre',
                                  hintText: 'Ej: Santiago Fraquelli',
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _InfoTile(
                                icon: Icons.email_outlined,
                                title: 'Correo electrónico',
                                value: user.email ?? 'Sin correo',
                                trailing: const Icon(Icons.lock_outline_rounded, size: 19),
                              ),
                              const SizedBox(height: 14),
                              _InfoTile(
                                icon: Icons.storefront_outlined,
                                title: 'Negocio asociado',
                                value: businessName,
                              ),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: _isSaving ? null : _saveName,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: const Text('Guardar cambios'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Verificación de correo',
                          subtitle: 'Mantené tu cuenta protegida y verificá tu dirección de correo.',
                          icon: Icons.verified_user_outlined,
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatusBadge(
                                  verified: user.emailVerified,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!user.emailVerified)
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _isSendingVerification ? null : _sendVerificationEmail,
                                      child: _isSendingVerification
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Enviar correo'),
                                    ),
                                    IconButton(
                                      tooltip: 'Actualizar estado',
                                      onPressed: _refreshVerificationStatus,
                                      icon: const Icon(Icons.refresh_rounded),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Apariencia',
                          subtitle: 'Personalizá cómo se ve ORDIVO en tu dispositivo.',
                          icon: Icons.palette_outlined,
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: ThemeController.instance.isDarkMode,
                            onChanged: (value) async {
                              await ThemeController.instance.setDarkMode(value);
                              if (mounted) setState(() {});
                            },
                            title: const Text(
                              'Modo nocturno',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              ThemeController.instance.isDarkMode
                                  ? 'ORDIVO está usando el tema oscuro.'
                                  : 'ORDIVO está usando el tema claro.',
                            ),
                            secondary: Icon(
                              ThemeController.instance.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Inicio de sesión',
                          subtitle: 'Elegí si ORDIVO debe recordar tu sesión al volver a abrir la aplicación.',
                          icon: Icons.login_rounded,
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _rememberLogin,
                            onChanged: (value) async {
                              await _appPreferences.setRememberLogin(value);
                              if (mounted) setState(() => _rememberLogin = value);
                            },
                            title: const Text(
                              'Recordar mi sesión',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text('Nunca se guarda tu contraseña.'),
                            secondary: Icon(
                              _rememberLogin ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Seguridad',
                          subtitle: 'Gestioná el acceso a tu cuenta.',
                          icon: Icons.security_outlined,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.lock_reset_rounded, color: colorScheme.primary),
                            ),
                            title: const Text(
                              'Cambiar contraseña',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text('Recibirás un correo para establecer una nueva contraseña.'),
                            trailing: _isSendingPasswordReset
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                            onTap: _isSendingPasswordReset ? null : _sendPasswordReset,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Datos del negocio',
                          subtitle: 'Reiniciá los datos operativos sin eliminar tu cuenta.',
                          icon: Icons.restart_alt_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Esta acción elimina ventas, gastos, caja, productos, stock, clientes, categorías y movimientos de stock. No elimina tu usuario ni el negocio.',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _isResettingData ? null : _resetBusinessData,
                                icon: _isResettingData
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.delete_sweep_outlined),
                                label: Text(_isResettingData ? 'Reiniciando datos...' : 'Reiniciar datos'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                  side: BorderSide(color: colorScheme.error.withValues(alpha: 0.35)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Cuenta',
                          subtitle: 'Acciones relacionadas con tu sesión.',
                          icon: Icons.manage_accounts_outlined,
                          child: OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.35)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ProfileHeader extends StatelessWidget {
  final String? name;
  final String email;
  final ColorScheme colorScheme;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name?.trim().isNotEmpty == true ? name!.trim() : 'Tu perfil';

    return Container(
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
        borderRadius: BorderRadius.circular(26),
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
          CircleAvatar(
            radius: 34,
            backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.15),
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.88),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool verified;

  const _StatusBadge({required this.verified});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = verified ? Colors.green : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              verified ? 'Correo verificado' : 'Correo pendiente de verificación',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
