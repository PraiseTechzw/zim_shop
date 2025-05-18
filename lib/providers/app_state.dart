import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  String? _lastError;
  bool _isInitialized = false;
  
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
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  
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

  // Initialize the AppState
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      await _supabaseService.initialize();
      await checkAuthState();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error initializing AppState: $_lastError');
      notifyListeners();
    }
  }

  // Method to check if the current user is authenticated on app start
  Future<void> checkAuthState() async {
    try {
      debugPrint('Checking auth state...');
      
      // Initialize service if needed
      if (!_isInitialized) {
        await _supabaseService.initialize();
      }
      
      // Get current user from Supabase
      final user = await _supabaseService.getCurrentUser();
      
      if (user != null) {
        debugPrint('User is logged in: ${user.email}');
        _currentUser = user;
        _isLoggedIn = true;
        _currentRole = user.role;
        
        // If user is admin, fetch users
        if (_currentRole == UserRole.admin) {
          await getUsers();
        }
      } else {
        debugPrint('No user is logged in');
        _isLoggedIn = false;
        _currentUser = null;
        _currentRole = UserRole.buyer;
      }
      
      _isAuthenticated = _currentUser != null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error checking auth state: $_lastError');
      _isLoggedIn = false;
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    }
  }

  // Login method with improved error handling
  Future<bool> login(String email, String password) async {
    try {
      debugPrint('Attempting login for: $email');
      
      final result = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isLoggedIn = true;
        _currentRole = result.user!.role;
        _lastError = null;
        
        debugPrint('Login successful for: $email with role: ${result.user!.role}');
        notifyListeners();
        return true;
      } else {
        _lastError = result.error ?? 'Login failed';
        debugPrint('Login failed: $_lastError');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Exception during login: $_lastError');
      notifyListeners();
      return false;
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

  // Logout with improved error handling
  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
      _isLoggedIn = false;
      _currentUser = null;
      _currentRole = UserRole.buyer;
      _lastError = null;
      
      debugPrint('User logged out successfully');
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error during logout: $_lastError');
      notifyListeners();
    }
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
    debugPrint('Password recovery state set to: $value');
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      final result = await _supabaseService.resetPassword(email);
      return result;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error resetting password: $_lastError');
      return false;
    }
  }
}