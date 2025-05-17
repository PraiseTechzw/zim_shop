import 'package:zim_shop/providers/app_state.dart' show UserRole;

class User {
  final int id;
  final String username;
  final UserRole role;
  final bool isApproved;
  
  User({
    required this.id,
    required this.username,
    required this.role,
    this.isApproved = true,
  });
  
  User copyWith({
    int? id,
    String? username,
    UserRole? role,
    bool? isApproved,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}