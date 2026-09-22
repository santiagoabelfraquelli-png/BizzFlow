import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bizzflow/screens/categories_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();

  String _businessType = 'Restaurante';
  bool _isLoading = false;

  final List<String> _businessTypes = [
    'Restaurante',
    'Panadería',
    'Rotisería',
    'Cafetería',
    'Bar',
    'Otro',
  ];

  Future<void> _createBusiness() async {
    final businessName = _businessNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();

    if (businessName.isEmpty || ownerName.isEmpty) {
      _showMessage('Completá todos los campos.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('No hay un usuario autenticado.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final businessRef =
          FirebaseFirestore.instance.collection('businesses').doc();

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final now = FieldValue.serverTimestamp();

      await businessRef.set({
        'name': businessName,
        'type': _businessType,
        'ownerId': user.uid,
        'ownerName': ownerName,
        'createdAt': now,
      });

      await userRef.set({
        'email': user.email,
        'businessId': businessRef.id,
        'createdAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BusinessHomeScreen(
            businessId: businessRef.id,
            businessName: businessName,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      _showMessage(
        'No se pudo crear el negocio: ${e.message ?? e.code}',
      );
    } catch (e) {
      _showMessage('Ocurrió un error inesperado.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar negocio'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Configurá tu negocio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completá estos datos para comenzar a usar BizzFlow.',
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                    hintText: 'Ej. La Esquina',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _businessType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de negocio',
                    border: OutlineInputBorder(),
                  ),
                  items: _businessTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _businessType = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del propietario',
                    hintText: 'Ej. Santiago',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _createBusiness,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Crear negocio'),
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
  final String businessName;

  const BusinessHomeScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BizzFlow'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenido a BizzFlow',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                businessName,
                style: const TextStyle(
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 280,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoriesScreen(
                          businessId: businessId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.category),
                  label: const Text('Categorías'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


