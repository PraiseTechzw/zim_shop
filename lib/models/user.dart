import 'package:zim_shop/providers/app_state.dart' show UserRole;

class User {
  final String id;
  final String username;
  final String email;
  final String password; // In a real app, this would be hashed
  final UserRole role;
  final bool isApproved;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? sellerBio;
  final double? sellerRating;
  final String? businessName;
  final String? businessAddress;
  
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.isApproved = true,
    this.phoneNumber,
    this.whatsappNumber,
    this.sellerBio,
    this.sellerRating,
    this.businessName,
    this.businessAddress,
  });
  
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    UserRole? role,
    bool? isApproved,
    String? phoneNumber,
    String? whatsappNumber,
    String? sellerBio,
    double? sellerRating,
    String? businessName,
    String? businessAddress,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      sellerBio: sellerBio ?? this.sellerBio,
      sellerRating: sellerRating ?? this.sellerRating,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
    );
  }
  
  // Check if user has completed seller profile
  bool get hasCompleteSellerProfile {
    if (role != UserRole.seller) return true;
    return businessName != null && 
           whatsappNumber != null && 
           sellerBio != null;
  }
}