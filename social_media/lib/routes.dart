import 'package:flutter/material.dart';
import 'package:social_media/screens/auth/login_screen.dart';
import 'package:social_media/screens/auth/register_screen.dart';
import 'package:social_media/screens/feed/comments_screen.dart';
import 'package:social_media/screens/feed/feed_screen.dart';
import 'package:social_media/screens/home/home_screen.dart';
import 'package:social_media/screens/posts/create_post_screen.dart';
import 'package:social_media/screens/profile/profile_screen.dart';
import 'package:social_media/screens/search/search_screen.dart';
import 'package:social_media/screens/profile/settings_screen.dart';

class AppRoutes {
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String feed = 'feed';
  static const String search = 'search';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String addPost = 'addPost';
  static const String comments = 'comments';

  static final Map<String, Widget Function(BuildContext, Object?)> _routes = {
    login: (_, __) => const LoginScreen(),
    register: (_, __) => const RegisterScreen(),
    home: (_, __) => const HomeScreen(),
    feed: (_, __) => const FeedScreen(),
    search: (_, __) => const SearchScreen(),
    profile: (_, __) => const ProfileScreen(),
    settings: (_, __) => const SettingsScreen(),
    addPost: (_, __) => const CreatePostScreen(),
    comments: (_, args) {
      if (args is String) {
        return CommentsScreen(postId: args);
      }
      return _errorScreen("Invalid or missing arguments for CommentsScreen");
    },
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: (context) => builder(context, settings.arguments),
      );
    }
    return MaterialPageRoute(
      builder: (_) => _errorScreen("No route defined for ${settings.name}"),
    );
  }

  static Widget _errorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Text(message, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
