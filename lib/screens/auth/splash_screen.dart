import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:laser_magique_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Give the splash screen some time to display
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isAuthenticated) {
      // User is already authenticated, navigate to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User is not authenticated, navigate to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or name
            Text(
              'Laser Magique',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const CupertinoActivityIndicator(radius: 16),
          ],
        ),
      ),
    );
  }
}
