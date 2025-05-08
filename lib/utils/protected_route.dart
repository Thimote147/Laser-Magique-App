import 'package:flutter/cupertino.dart';
import 'package:laser_magique_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // If still loading, show a loading indicator
    if (authService.isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // If not authenticated, redirect to login
    if (!authService.isAuthenticated) {
      final navigator = Navigator.of(context);
      // Use Future.microtask to avoid calling Navigator during build
      Future.microtask(() {
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      });

      // Return an empty container while redirecting
      return const SizedBox.shrink();
    }

    // If authenticated, show the requested route
    return child;
  }
}
