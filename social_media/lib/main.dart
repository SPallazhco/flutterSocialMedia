import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/routes.dart';
import 'package:social_media/screens/auth/login_screen.dart';
import 'package:social_media/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YourSelf',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const AuthChecker(),
      routes: AppRoutes.getRoutes(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<bool> _isUserLoggedIn() async {
    // Consultamos al FirebaseAuth para ver si hay un usuario autenticado
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Ocurrió un error al verificar la autenticación'),
            ),
          );
        }

        if (snapshot.data == true) {
          // Usuario autenticado
          return const HomeScreen();
        } else {
          // Usuario no autenticado
          return const LoginScreen();
        }
      },
    );
  }
}
