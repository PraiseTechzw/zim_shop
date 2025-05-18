import 'package:flutter/material.dart';
import 'package:zim_shop/mock_data.dart';
import 'package:zim_shop/models/user.dart';


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

  UserRole get currentRole => _currentRole;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<User> get users => MockData.users;

  // Login with email and password
  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      final user = MockData.users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase() && user.password == password,
      );
      
      _currentUser = user;
      _currentRole = user.role;
      _isLoggedIn = true;
      notifyListeners();
      return user;
    } catch (e) {
      throw AuthException('Invalid email or password. Please try again.');
    }
  }

  // Legacy login method (keeping for backward compatibility)
  void legacyLogin(String username, UserRole role) {
    _currentRole = role;
    
    // Find user in mock data or create a new one
    _currentUser = MockData.users.firstWhere(
      (user) => user.username == username && user.role == role,
      orElse: () => User(
        id: MockData.users.length + 1,
        username: username,
        email: '$username@example.com',
        password: 'password123',
        role: role,
        isApproved: role != UserRole.seller || role == UserRole.admin,
      ),
    );
    
    if (_currentUser != null && !MockData.users.contains(_currentUser)) {
      MockData.users.add(_currentUser!);
    }
    
    _isLoggedIn = true;
    notifyListeners();
  }

  // Register a new user
  Future<User> register(String username, String email, String password, UserRole role) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Check if email already exists
    final emailExists = MockData.users.any(
      (user) => user.email.toLowerCase() == email.toLowerCase()
    );
    
    if (emailExists) {
      throw AuthException('Email already registered. Please use a different email or login.');
    }
    
    // Check if username already exists
    final usernameExists = MockData.users.any(
      (user) => user.username.toLowerCase() == username.toLowerCase()
    );
    
    if (usernameExists) {
      throw AuthException('Username already taken. Please choose a different username.');
    }
    
    // Create new user
    final newUser = User(
      id: MockData.users.length + 1,
      username: username,
      email: email,
      password: password,
      role: role,
      isApproved: role != UserRole.seller, // Sellers need approval
    );
    
    MockData.users.add(newUser);
    notifyListeners();
    
    return newUser;
  }

  // Forgot password - in a real app this would send an email
  Future<void> forgotPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Check if email exists
    final emailExists = MockData.users.any(
      (user) => user.email.toLowerCase() == email.toLowerCase()
    );
    
    if (!emailExists) {
      throw AuthException('Email not found. Please check the email address or register.');
    }
    
    // In a real app, this would send a password reset email
    // For the mock, we just return success
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  void approveUser(int userId, bool isApproved) {
    final userIndex = MockData.users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      MockData.users[userIndex] = MockData.users[userIndex].copyWith(isApproved: isApproved);
      notifyListeners();
    }
  }
}