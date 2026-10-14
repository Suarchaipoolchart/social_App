import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/feed/presentation/feed_page.dart';
import 'routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routes: AppRoutes.routes,
      home: const AuthGate(),
    );
  }
}

/// ล็อกอินแล้วไปหน้าหลัก ยังไม่ล็อกอินไปหน้า Login อัตโนมัติ
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AuthRepository>().authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ใช้ FeedPage เป็นหน้าหลักชั่วคราว
        return snap.hasData ? const FeedPage() : const LoginPage();
      },
    );
  }
}
