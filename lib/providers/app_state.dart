import 'package:flutter/material.dart';
import 'package:zim_shop/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { buyer, seller, admin }

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AppState extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserRole _currentRole = UserRole.buyer;
  User? _currentUser;
  bool _isLoggedIn = false;

  UserRole get currentRole => _currentRole;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Get all users (for admin purposes)
  Future<List<User>> get users async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User(
        id: int.parse(doc.id),
        username: data['username'],
        email: data['email'],
        password: '', // We don't store or return passwords
        role: UserRole.values.firstWhere((e) => e.toString() == data['role']),
        isApproved: data['isApproved'] ?? true,
      );
    }).toList();
  }

  // Check if user is logged in when app starts
  Future<void> checkCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchUserData(firebaseUser.uid);
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = User(
          id: int.parse(uid),
          username: data['username'],
          email: data['email'],
          password: '', // We don't store passwords in the app
          role: UserRole.values.firstWhere(
            (role) => role.toString() == 'UserRole.${data['role']}',
          ),
          isApproved: data['isApproved'] ?? true,
        );
        _currentRole = _currentUser!.role;
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Login with email and password
  Future<User> login(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw AuthException('Login failed. Please try again.');
      }
      
      // Fetch user details from Firestore
      await _fetchUserData(userCredential.user!.uid);
      
      if (_currentUser == null) {
        throw AuthException('User data not found.');
      }
      
      // Check if seller is approved
      if (_currentUser!.role == UserRole.seller && !_currentUser!.isApproved) {
        await logout();
        throw AuthException('Your seller account is pending approval.');
      }
      
      return _currentUser!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password. Please try again.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = 'An error occurred. Please try again later.';
      }
      throw AuthException(message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // Register a new user
  Future<User> register(String username, String email, String password, UserRole role) async {
    try {
      // Check if username is already taken
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        throw AuthException('Username already taken. Please choose a different username.');
      }
      
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw AuthException('Registration failed. Please try again.');
      }
      
      // Generate a unique user ID
      final userId = userCredential.user!.uid;
      
      // Create user document in Firestore
      final newUser = User(
        id: int.parse(userId),
        username: username,
        email: email,
        password: '', // Don't store the password
        role: role,
        isApproved: role != UserRole.seller, // Sellers need approval
      );
      
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'role': role.toString().split('.').last,
        'isApproved': role != UserRole.seller,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Set current user
      _currentUser = newUser;
      _currentRole = role;
      _isLoggedIn = true;
      notifyListeners();
      
      return newUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already registered. Please use a different email or login.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use a stronger password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address. Please enter a valid email.';
          break;
        default:
          message = 'Registration failed. Please try again.';
      }
      throw AuthException(message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // Forgot password - send reset email
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email not found. Please check the email address or register.';
          break;
        case 'invalid-email':
          message = 'Invalid email address. Please enter a valid email.';
          break;
        default:
          message = 'Failed to send reset email. Please try again.';
      }
      throw AuthException(message);
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw AuthException('Failed to logout. Please try again.');
    }
  }

  // Approve/disapprove seller
  Future<void> approveUser(String userId, bool isApproved) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': isApproved,
      });
      
      // If the current user is being updated, update the local state
      if (_currentUser != null && _currentUser!.id.toString() == userId) {
        _currentUser = _currentUser!.copyWith(isApproved: isApproved);
        notifyListeners();
      }
    } catch (e) {
      throw AuthException('Failed to update user approval status.');
    }
  }
}