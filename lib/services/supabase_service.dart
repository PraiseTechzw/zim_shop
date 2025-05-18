import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/providers/app_state.dart' hide AuthException;
import 'dart:io';
import 'dart:typed_data';

// Supabase configuration constants
const String supabaseUrl = 'https://gkyeijnygndqqstxucpn.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdreWVpam55Z25kcXFzdHh1Y3BuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1Nzk5NzcsImV4cCI6MjA2MzE1NTk3N30.kgLfES9rO2VsIkCErg556pbXc3UZEaSjuoX7SHcRQFU';

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
      debugPrint('PostgrestException during signup: ${e.message}, code: ${e.code}, details: ${e.details}');
      return AuthResult(error: e.message);
    } on AuthException catch (e) {
      debugPrint('AuthException during signup: ${e.message}');
      return AuthResult(error: e.message);
    } catch (e) {
      debugPrint('Unknown error during signup: $e');
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
        id: userId,
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
  
  Future<bool> updateProduct(Product product) async {
    try {
      await _client
          .from('products')
          .update({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'image_url': product.imageUrl,
            'category': product.category,
            'location': product.location,
          })
          .eq('id', product.id);
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    try {
      // Delete product
      await _client
          .from('products')
          .delete()
          .eq('id', productId);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }
  
  // ORDERS METHODS
  Future<List<Order>> getUserOrders(String userId) async {
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
  
  Future<List<Order>> getSellerOrders(String sellerId) async {
    try {
      // First get seller's products
      final productsResponse = await _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId);
      
      if (productsResponse.isEmpty) {
        return [];
      }
      
      // Extract product IDs
      final productIds = productsResponse.map((p) => p['id'] as String).toList();
      
      // For now, we'll simplify and just return all orders
      // In a real implementation, you would filter by seller's products
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);
      
      // Parse orders from response
      List<Order> orders = [];
      // Implementation will depend on your data structure
      
      return orders;
    } catch (e) {
      debugPrint('Error fetching seller orders: $e');
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
  
  // STORAGE METHODS
  Future<String?> uploadProductImage(dynamic file, String sellerId) async {
    try {
      String fileName;
      List<int> fileBytes;
      
      if (file is String) {
        // It's a file path
        final f = File(file);
        fileName = f.path.split('/').last;
        fileBytes = await f.readAsBytes();
      } else if (file is File) {
        // It's already a File object
        fileName = file.path.split('/').last;
        fileBytes = await file.readAsBytes();
      } else if (file is Uint8List) {
        // It's raw bytes
        fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        fileBytes = file;
      } else {
        throw ArgumentError('Unsupported file type. Please provide a File, file path, or bytes.');
      }
      
      final fileExt = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'public/$sellerId/$timestamp.$fileExt';
      
      await _client
          .storage
          .from('products')
          .uploadBinary(storagePath, Uint8List.fromList(fileBytes));
      
      // Get public URL for the uploaded image
      final imageUrl = _client
          .storage
          .from('products')
          .getPublicUrl(storagePath);
      
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      return null;
    }
  }
  
  Future<bool> deleteProductImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // The path should be something like: /storage/v1/object/public/products/public/seller-id/filename.ext
      // We need to get everything after the bucket name ('products')
      final startIndex = pathSegments.indexOf('products') + 1;
      if (startIndex >= pathSegments.length) return false;
      
      final storagePath = pathSegments.sublist(startIndex).join('/');
      
      await _client
          .storage
          .from('products')
          .remove([storagePath]);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting product image: $e');
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
          id: item['id'],
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