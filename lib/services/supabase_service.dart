import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/providers/app_state.dart' hide AuthException;

// Supabase configuration constants
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

class AuthResult {
  final User? user;
  final String? error;
  
  AuthResult({this.user, this.error});
  
  bool get success => error == null && user != null;
}

class SupabaseService {
  late final SupabaseClient _client;
  
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  // Initialize Supabase
  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  SupabaseClient get client => _client;
  
  // Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;
  
  // Get current authenticated user
  Future<User?> getCurrentUser() async {
    final supabaseUser = _client.auth.currentUser;
    if (supabaseUser == null) return null;
    
    // Fetch user data from 'users' table to get role and other details
    return await _getUserDetails(supabaseUser.id);
  }
  
  // Auth Methods
  Future<AuthResult> signUp({
    required String email, 
    required String password, 
    required String username, 
    required UserRole role
  }) async {
    try {
      // 1. Create auth user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return AuthResult(error: 'Failed to create user');
      }
      
      // 2. Add user details to 'users' table
      await _client.from('users').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'role': role.toString().split('.').last,
        'is_approved': role != UserRole.seller, // Sellers need approval
      });
      
      // 3. Get complete user data
      final user = await _getUserDetails(response.user!.id);
      return AuthResult(user: user);
    } on PostgrestException catch (e) {
      return AuthResult(error: e.message);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }
  
  Future<AuthResult> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return AuthResult(error: 'Invalid email or password');
      }
      
      // Get user details from database
      final user = await _getUserDetails(response.user!.id);
      return AuthResult(user: user);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Helper method to fetch user details from 'users' table
  Future<User?> _getUserDetails(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      if (response == null) return null;
      
      UserRole role;
      switch (response['role']) {
        case 'buyer':
          role = UserRole.buyer;
          break;
        case 'seller':
          role = UserRole.seller;
          break;
        case 'admin':
          role = UserRole.admin;
          break;
        default:
          role = UserRole.buyer;
      }
      
      return User(
        id: int.parse(response['id']),
        username: response['username'],
        email: response['email'],
        password: '', // We don't store passwords in the app
        role: role,
        isApproved: response['is_approved'] ?? false,
      );
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }
  
  // PRODUCTS METHODS
  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('*, seller:seller_id(username)')
          .order('created_at', ascending: false);
      
      return response.map<Product>((item) {
        return Product(
          id: item['id'],
          name: item['name'],
          description: item['description'],
          price: item['price'].toDouble(),
          imageUrl: item['image_url'],
          category: item['category'],
          location: item['location'],
          sellerId: item['seller_id'],
          sellerName: item['seller']['username'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }
  
  Future<bool> addProduct(Product product) async {
    try {
      await _client.from('products').insert({
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'image_url': product.imageUrl,
        'category': product.category,
        'location': product.location,
        'seller_id': product.sellerId,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }
  
  // ORDERS METHODS
  Future<List<Order>> getUserOrders(int userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      // Parse orders from response
      List<Order> orders = [];
      // Implementation will depend on your data structure
      
      return orders;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }
  
  Future<bool> createOrder(Order order) async {
    try {
      // Create order
      final orderResponse = await _client.from('orders').insert({
        'user_id': order.userId,
        'total_amount': order.totalAmount,
        'status': order.status,
      }).select().single();
      
      // Add order items
      final orderId = orderResponse['id'];
      for (var item in order.items) {
        await _client.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        });
      }
      
      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return false;
    }
  }
  
  // ADMIN METHODS
  Future<bool> approveUser(String userId, bool isApproved) async {
    try {
      await _client
          .from('users')
          .update({'is_approved': isApproved})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error approving user: $e');
      return false;
    }
  }
  
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      
      return response.map<User>((item) {
        UserRole role;
        switch (item['role']) {
          case 'buyer':
            role = UserRole.buyer;
            break;
          case 'seller':
            role = UserRole.seller;
            break;
          case 'admin':
            role = UserRole.admin;
            break;
          default:
            role = UserRole.buyer;
        }
        
        return User(
          id: int.parse(item['id']),
          username: item['username'],
          email: item['email'],
          password: '', // We don't store passwords in the app
          role: role,
          isApproved: item['is_approved'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }
} 