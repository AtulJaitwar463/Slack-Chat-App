import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:slack_chat_app/providers/auth_provider.dart';
import 'package:slack_chat_app/screens/home_screen.dart';
import 'package:slack_chat_app/screens/login_screen.dart';
import 'package:slack_chat_app/screens/splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _minimumSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _minimumSplashElapsed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider authProvider, _) {
        if (!_minimumSplashElapsed || authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
