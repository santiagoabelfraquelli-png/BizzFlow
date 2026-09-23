import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bizzflow/services/app_preferences.dart';

class AuthScreen extends StatefulWidget {
  final AppPreferences appPreferences;

  const AuthScreen({super.key, required this.appPreferences});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late bool _rememberLogin;

  @override
  void initState() {
    super.initState();
    _rememberLogin = widget.appPreferences.rememberLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _setRememberLogin(bool value) async {
    setState(() => _rememberLogin = value);
    await widget.appPreferences.setRememberLogin(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await widget.appPreferences.setRememberLogin(_rememberLogin);
      } else {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await widget.appPreferences.setRememberLogin(_rememberLogin);
        await credential.user?.sendEmailVerification();
        if (mounted) {
          _showMessage('Cuenta creada. Te enviamos un correo para verificar tu dirección.');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(_authErrorMessage(e.code), isError: true);
    } catch (_) {
      if (mounted) _showMessage('Ocurrió un error. Intentá nuevamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Escribí tu correo electrónico para recuperar la contraseña.', isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showMessage('Te enviamos un correo para restablecer la contraseña.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showMessage(_authErrorMessage(e.code), isError: true);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'El correo o la contraseña son incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá unos minutos y probá nuevamente.';
      case 'network-request-failed':
        return 'No hay conexión con Internet.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada.';
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
          margin: const EdgeInsets.all(16),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  void _toggleMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.20),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(Icons.auto_awesome_rounded, color: colorScheme.onPrimary, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'BizzFlow',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Gestioná tu negocio de forma simple'
                              : 'Creá tu cuenta y empezá a organizar tu negocio',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: _inputDecoration(
                                      label: 'Correo electrónico',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) return 'Ingresá tu correo electrónico.';
                                      if (!email.contains('@')) return 'Ingresá un correo válido.';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.password],
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading) _submit();
                                    },
                                    decoration: _inputDecoration(
                                      label: 'Contraseña',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').isEmpty) return 'Ingresá tu contraseña.';
                                      if (!_isLogin && value!.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_isLogin) ...[
                                    const SizedBox(height: 4),
                                    CheckboxListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      value: _rememberLogin,
                                      onChanged: _isLoading
                                          ? null
                                          : (value) => _setRememberLogin(value ?? true),
                                      title: const Text(
                                        'Recordar mi sesión',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: const Text('No guarda tu contraseña.'),
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _resetPassword,
                                        child: const Text('¿Olvidaste tu contraseña?'),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : Text(
                                              _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: colorScheme.outlineVariant)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'o',
                                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: colorScheme.outlineVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _isLoading ? null : _toggleMode,
                                    child: Text(
                                      _isLogin ? 'Crear una cuenta nueva' : 'Ya tengo una cuenta',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 17, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Tus datos están protegidos con Firebase Authentication',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
