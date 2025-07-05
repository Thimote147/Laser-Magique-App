import 'package:flutter/material.dart';
import './login_view.dart';
import './register_view.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginView(onRegisterTap: _toggleView);
    } else {
      return RegisterView(onLoginTap: _toggleView);
    }
  }
}
