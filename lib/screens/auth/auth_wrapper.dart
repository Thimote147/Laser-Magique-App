import 'package:flutter/cupertino.dart';
import 'package:laser_magique_app/main.dart';
import 'package:laser_magique_app/screens/auth/login_screen.dart';
import 'package:laser_magique_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the auth service to check authentication state
    final authService = Provider.of<AuthService>(context);

    // If auth status is still being determined, show loading screen
    if (authService.isLoading) {
      return const CupertinoActivityIndicator();
    }

    // Once auth state is determined, route appropriately
    if (authService.isAuthenticated) {
      // User is authenticated, show main app
      return const MainScreen();
    } else {
      // User is not authenticated, show login screen
      return const LoginScreen();
    }
  }
}
