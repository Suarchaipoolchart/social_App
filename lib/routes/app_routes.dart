import 'package:flutter/material.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/profile/presentation/profile_page.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const profile = '/profile';

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    profile: (_) => const ProfilePage(),
  };
}
