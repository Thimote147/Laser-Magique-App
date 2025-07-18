import 'package:flutter/material.dart';
import '../features/profile/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;
  
  bool get isAdmin => _user?.settings?.role == 'admin';

  set user(UserModel? value) {
    _user = value;
    notifyListeners();
  }
}
