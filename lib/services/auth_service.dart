import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  // Instance of Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Current user
  User? _currentUser;

  // User's role
  String? _userRole;

  // Current session
  Session? _currentSession;

  // Loading state
  bool _isLoading = true;

  // Getters
  User? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  String? get userRole => _userRole;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // Init method to be called when app starts
  Future<void> initialize() async {
    try {
      // Get initial session
      _currentSession = _supabase.auth.currentSession;
      _currentUser = _supabase.auth.currentUser;

      // Fetch user role if user is authenticated
      if (_currentUser != null) {
        await _fetchUserRole(_currentUser!.id);
      }

      // Listen for auth state changes
      _supabase.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        switch (event) {
          case AuthChangeEvent.signedIn:
            _currentUser = session?.user;
            _currentSession = session;
            if (_currentUser != null) {
              await _fetchUserRole(_currentUser!.id);
            }
            notifyListeners();
            break;
          case AuthChangeEvent.signedOut:
            _currentUser = null;
            _currentSession = null;
            _userRole = null;

            notifyListeners();
            break;
          case AuthChangeEvent.userUpdated:
            _currentUser = session?.user;
            _currentSession = session;
            if (_currentUser != null) {
              await _fetchUserRole(_currentUser!.id);
            }
            notifyListeners();
            break;
          case AuthChangeEvent.passwordRecovery:
            break;
          default:
            break;
        }
      });
    } catch (e) {
      // Silently handle initialization errors
    } finally {
      // Set loading to false once initialization is complete
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user role from the database
  Future<void> _fetchUserRole(String userId) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('role')
              .eq('user_id', userId)
              .single();

      _userRole = response['role'];
    } catch (e) {
      _userRole = null;
      debugPrint('Error fetching user role: $e');
    }
  }

  // Check if user has required role (member or admin)
  bool hasRequiredRole() {
    return _userRole == 'member' || _userRole == 'admin';
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch the user's role
        await _fetchUserRole(response.user!.id);

        // Check if the user has the required role
        if (!hasRequiredRole()) {
          // If not, sign them out and throw an exception
          await _supabase.auth.signOut();
          throw Exception('Access denied: insufficient permissions');
        }
      }
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(data: data));
      // Update the current user with new data
      _currentUser = _supabase.auth.currentUser;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Verify current password
  Future<void> verifyPassword(String password) async {
    try {
      final user = _currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user found');
      }

      // Try to sign in with current email and provided password to verify
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );

      // If no error was thrown, the password is correct
    } catch (e) {
      throw Exception('Current password is incorrect');
    }
  }
}
