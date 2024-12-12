import 'package:flutter/material.dart';
import 'package:social_media/screens/auth/login_screen.dart';
import 'package:social_media/screens/auth/register_screen.dart';
import 'package:social_media/screens/home/home_screen.dart';

class AppRoutes {
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (BuildContext context) => const LoginScreen(),
      register: (BuildContext context) => const RegisterScreen(),
      home: (BuildContext context) => const HomeScreen(),
    };
  }
}
