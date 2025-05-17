import 'package:flutter/material.dart';
import 'package:zim_shop/mock_data.dart';
import 'package:zim_shop/models/user.dart';


enum UserRole { buyer, seller, admin }

class AppState extends ChangeNotifier {
  UserRole _currentRole = UserRole.buyer;
  User? _currentUser;
  bool _isLoggedIn = false;

  UserRole get currentRole => _currentRole;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<User> get users => MockData.users;

  void login(String username, UserRole role) {
    _currentRole = role;
    
    // Find user in mock data or create a new one
    _currentUser = MockData.users.firstWhere(
      (user) => user.username == username && user.role == role,
      orElse: () => User(
        id: MockData.users.length + 1,
        username: username,
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