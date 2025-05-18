import 'package:zim_shop/providers/app_state.dart' show UserRole;

class User {
  final int id;
  final String username;
  final String email;
  final String password; // In a real app, this would be hashed
  final UserRole role;
  final bool isApproved;
  
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.isApproved = true,
  });
  
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    UserRole? role,
    bool? isApproved,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}