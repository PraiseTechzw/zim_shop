import 'package:flutter/material.dart';
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
  List<User> _users = [];
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isPasswordRecovery = false;
  
  final SupabaseService _supabaseService = SupabaseService();

  AppState() {
    _checkCurrentUser();
  }

  UserRole get currentRole => _currentRole;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isSeller => _currentUser?.role == UserRole.seller;
  bool get isSellerApproved => 
    _currentUser?.role == UserRole.seller && _currentUser?.isApproved == true;
  bool get isPasswordRecovery => _isPasswordRecovery;
  
  // Check if seller profile is complete
  bool get isSellerProfileComplete => 
    _currentUser?.hasCompleteSellerProfile ?? false;

  // Get users (this should only be used by admins)
  Future<List<User>> getUsers() async {
    // In production, we would check if the current user is an admin
    _users = await _supabaseService.getAllUsers();
    notifyListeners();
    return _users;
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (result.error != null) {
        return {
          'success': false,
          'message': result.error!,
          'user': null,
        };
      }
      
      if (result.user == null) {
        return {
          'success': false,
          'message': 'Invalid email or password. Please try again.',
          'user': null,
        };
      }
      
      _currentUser = result.user;
      _currentRole = result.user!.role;
      _isLoggedIn = true;
      
      // Determine route based on user role
      String route;
      switch (_currentRole) {
        case UserRole.admin:
          route = '/admin';
          break;
        case UserRole.seller:
          route = '/seller';
          break;
        case UserRole.buyer:
        default:
          route = '/home';
          break;
      }
      
      notifyListeners();
      
      return {
        'success': true,
        'message': 'Login successful!',
        'user': result.user,
        'route': route,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e is AuthException ? e.message : 'Login failed. Please try again.',
        'user': null,
      };
    }
  }

  // Register a new user
  Future<AuthResult> register(String username, String email, String password, UserRole role) async {
    try {
      final result = await _supabaseService.signUp(
        email: email,
        password: password,
        username: username,
        role: role,
      );
      
      if (result.error != null) {
        // Check if this is an RLS error but registration succeeded
        if (result.error!.contains("recursion") && result.user != null) {
          // Registration was successful but we got RLS error
          return AuthResult(
            user: result.user,
            requiresEmailConfirmation: result.requiresEmailConfirmation
          );
        }
        throw AuthException(result.error!);
      }
      
      if (result.requiresEmailConfirmation) {
        return result; // Return the result with confirmationRequired flag
      }
      
      if (result.user == null) {
        throw AuthException('Failed to register user.');
      }
      
      // In a real app, we would not auto-login after registration
      // especially if email verification is required
      return result;
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
        
        // If user is admin, fetch users
        if (_currentRole == UserRole.admin) {
          await getUsers();
        }
        
        notifyListeners();
      }
    }
  }

  // Update current user
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.initialize();
      _currentUser = await _supabaseService.getCurrentUser();
      _isAuthenticated = _currentUser != null;
    } catch (e) {
      debugPrint('Error checking current user: $e');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _supabaseService.getCurrentUser();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set password recovery state
  void setPasswordRecovery(bool value) {
    _isPasswordRecovery = value;
    notifyListeners();
  }
}