import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/business_setup_screen.dart';
import 'services/app_preferences.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final appPreferences = AppPreferences.instance;

    await ThemeController.instance.load();

    runApp(
      OrdivoApp(
        appPreferences: appPreferences,
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Error al iniciar ORDIVO:\n\n$e\n\n$stackTrace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrdivoApp extends StatelessWidget {
  final AppPreferences appPreferences;

  const OrdivoApp({
    super.key,
    required this.appPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'ORDIVO',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeController.instance.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: AppRouter(
            appPreferences: appPreferences,
          ),
        );
      },
    );
  }
}

class AppRouter extends StatelessWidget {
  final AppPreferences appPreferences;

  const AppRouter({
    super.key,
    required this.appPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return AuthScreen(
            appPreferences: appPreferences,
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final data = userSnapshot.data?.data();
            final businessId = data?['businessId'];

            if (businessId == null ||
                businessId.toString().trim().isEmpty) {
              return const BusinessSetupScreen();
            }

            return BusinessHomeScreen(
              businessId: businessId.toString(),
            );
          },
        );
      },
    );
  }
}
