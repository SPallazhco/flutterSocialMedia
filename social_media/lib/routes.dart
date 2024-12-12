import 'package:flutter/material.dart';
import 'package:social_media/screens/auth/login_screen.dart';
import 'package:social_media/screens/auth/register_screen.dart';
import 'package:social_media/screens/feed/feed_screen.dart';
import 'package:social_media/screens/home/home_screen.dart';
import 'package:social_media/screens/profile/profile_screen.dart';
import 'package:social_media/screens/search/search_screen.dart';
import 'package:social_media/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String feed = 'feed';
  static const String search = 'search';
  static const String profile = 'profile';
  static const String settings = 'settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (BuildContext context) => const LoginScreen(),
      register: (BuildContext context) => const RegisterScreen(),
      home: (BuildContext context) => const HomeScreen(),
      feed: (BuildContext context) => const FeedScreen(),
      search: (BuildContext context) => const SearchScreen(),
      profile: (BuildContext context) => const ProfileScreen(),
      settings: (BuildContext context) => const SettingsScreen(),
    };
  }
}
