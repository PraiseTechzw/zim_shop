import 'package:flutter/material.dart';
import 'package:zim_shop/mock_data.dart';
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/services/supabase_service.dart';


enum UserRole { buyer, seller, admin }

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AppState extends ChangeNotifier {
  UserRole _currentRole = UserRole.buyer;
  User? _currentUser;
  bool _isLoggedIn = false;
  
  final SupabaseService _supabaseService = SupabaseService();

  UserRole get currentRole => _currentRole;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  
  // Get users (this should only be used by admins)
  Future<List<User>> getUsers() async {
    // In production, we would check if the current user is an admin
    return await _supabaseService.getAllUsers();
  }

  // Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final result = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (result.error != null) {
        throw AuthException(result.error!);
      }
      
      if (result.user == null) {
        throw AuthException('Invalid email or password. Please try again.');
      }
      
      _currentUser = result.user;
      _currentRole = result.user!.role;
      _isLoggedIn = true;
      notifyListeners();
      return result.user!;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Invalid email or password. Please try again.');
    }
  }

  // Register a new user
  Future<User> register(String username, String email, String password, UserRole role) async {
    try {
      final result = await _supabaseService.signUp(
        email: email,
        password: password,
        username: username,
        role: role,
      );
      
      if (result.error != null) {
        throw AuthException(result.error!);
      }
      
      if (result.user == null) {
        throw AuthException('Failed to register user.');
      }
      
      // In a real app, we would not auto-login after registration
      // especially if email verification is required
      return result.user!;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Registration failed. Please try again.');
    }
  }

  // Forgot password - in a real app this would send an email
  Future<void> forgotPassword(String email) async {
    try {
      final success = await _supabaseService.resetPassword(email);
      
      if (!success) {
        throw AuthException('Failed to send password reset email. Please try again.');
      }
      
      // Success - email has been sent
    } catch (e) {
      throw AuthException('Failed to send password reset email. Please try again.');
    }
  }

  Future<void> logout() async {
    await _supabaseService.signOut();
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> approveUser(String userId, bool isApproved) async {
    try {
      final success = await _supabaseService.approveUser(userId, isApproved);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
  
  // Method to check if the current user is authenticated on app start
  Future<void> checkAuthState() async {
    if (_supabaseService.isAuthenticated) {
      final user = await _supabaseService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _currentRole = user.role;
        _isLoggedIn = true;
        notifyListeners();
      }
    }
  }
}