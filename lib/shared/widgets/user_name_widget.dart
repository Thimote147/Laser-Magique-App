import 'package:flutter/material.dart';
import '../services/user_service.dart';

/// Widget pour afficher le nom d'un utilisateur de manière asynchrone
class UserNameWidget extends StatefulWidget {
  final String userId;
  final String fallbackName;
  final TextStyle? textStyle;
  final String prefix;

  const UserNameWidget({
    super.key,
    required this.userId,
    required this.fallbackName,
    this.textStyle,
    this.prefix = '',
  });

  @override
  State<UserNameWidget> createState() => _UserNameWidgetState();
}

class _UserNameWidgetState extends State<UserNameWidget> {
  final UserService _userService = UserService();
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userName = await _userService.getUserFullName(widget.userId);
      if (mounted) {
        setState(() {
          _userName = userName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = widget.fallbackName;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Text(
        '${widget.prefix}${widget.fallbackName}',
        style: widget.textStyle,
      );
    }

    return Text(
      '${widget.prefix}${_userName ?? widget.fallbackName}',
      style: widget.textStyle,
    );
  }
}