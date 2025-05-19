import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/providers/app_state.dart' hide AuthException;
import 'dart:io';
import 'dart:typed_data';

// Supabase configuration constants
const String supabaseUrl = 'https://gkyeijnygndqqstxucpn.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdreWVpam55Z25kcXFzdHh1Y3BuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1Nzk5NzcsImV4cCI6MjA2MzE1NTk3N30.kgLfES9rO2VsIkCErg556pbXc3UZEaSjuoX7SHcRQFU';


const String supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdreWVpam55Z25kcXFzdHh1Y3BuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NzU3OTk3NywiZXhwIjoyMDYzMTU1OTc3fQ.RUfAHh8lkQB3AQoL4AsC8m_RR_L-GHBIbs6-yfucQOM';

class AuthResult {
  final User? user;
  final String? error;
  final bool requiresEmailConfirmation;
  
  AuthResult({this.user, this.error, this.requiresEmailConfirmation = false});
  
  bool get success => error == null && user != null;
}

class SupabaseService {
  late final SupabaseClient _client;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  // Initialize Supabase
  Future<void> initialize() async {
    try {
      // Prevent double initialization
      if (_isInitialized) {
        debugPrint('SupabaseService already initialized');
        return;
      }
      
      // Get the existing client - Supabase should already be initialized in main.dart
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('SupabaseService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SupabaseService: $e');
      rethrow; // Throw to allow the calling code to handle initialization errors
    }
  }
  
  SupabaseClient get client => _client;
  
  bool get isInitialized => _isInitialized;
  
  // Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;
  
  // Ensure client is initialized before performing operations
  Future<bool> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await initialize();
        return true;
      } catch (e) {
        debugPrint('Failed to initialize SupabaseService: $e');
        return false;
      }
    }
    return true;
  }
  
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
    if (!_isInitialized) {
      return AuthResult(error: 'SupabaseService not initialized');
    }
    
    try {
      // 1. Create auth user with role in user metadata
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'role': role.toString().split('.').last,
        }
      );
      
      if (response.user == null) {
        return AuthResult(error: 'Failed to create user');
      }
      
      // 2. Add user details to 'users' table using a direct SQL insertion
      // This avoids the RLS policies by using a special pgFunction
      try {
        // Call a custom PostgreSQL function that bypasses RLS
        final result = await _client.rpc(
          'insert_new_user',
          params: {
            'user_id': response.user!.id,
            'user_email': email,
            'user_name': username,
            'user_role': role.toString().split('.').last,
            'is_user_approved': role != UserRole.seller, // Sellers need approval
          },
        );
        
        debugPrint('Successfully added user details to users table via RPC');
      } catch (e) {
        // Log the error for debugging
        debugPrint('Failed to insert user details via RPC: $e');
        
        // If RPC fails, create a basic user from auth user data
        if (response.session == null) {
          return AuthResult(
            user: User(
              id: response.user!.id,
              username: username,
              email: email,
              password: '',
              role: role,
              isApproved: role != UserRole.seller,
            ),
            requiresEmailConfirmation: true,
          );
        } else {
          return AuthResult(
            user: User(
              id: response.user!.id,
              username: username,
              email: email,
              password: '',
              role: role,
              isApproved: role != UserRole.seller,
            ),
          );
        }
      }
      
      // 3. Check if email confirmation is required
      if (response.session == null) {
        // Email confirmation is required
        return AuthResult(
          user: User(
            id: response.user!.id,
            username: username,
            email: email,
            password: '',
            role: role,
          ),
          error: 'Please check your email to confirm your account.',
          requiresEmailConfirmation: true,
        );
      }
      
      // 4. Get complete user data
      User? user;
      try {
        user = await _getUserDetails(response.user!.id);
      } catch (e) {
        // If we can't get user details, create a basic user object
        user = User(
          id: response.user!.id,
          username: username,
          email: email,
          password: '',
          role: role,
          isApproved: role != UserRole.seller,
        );
      }
      
      return AuthResult(user: user);
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException during signup: ${e.message}, code: ${e.code}, details: ${e.details}');
      if (e.message.contains('recursion') || e.message.contains('violates row-level security policy')) {
        // This means the auth user was created but we couldn't update the profile
        // We'll return a success with a warning
        return AuthResult(
          error: 'Account created but profile setup incomplete. Please contact support.',
          requiresEmailConfirmation: true,
        );
      }
      return AuthResult(error: e.message);
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        return AuthResult(
          error: 'Please check your email to confirm your account.',
          requiresEmailConfirmation: true,
        );
      }
      debugPrint('AuthException during signup: ${e.message}');
      return AuthResult(error: e.message);
    } catch (e) {
      debugPrint('Unknown error during signup: $e');
      return AuthResult(error: e.toString());
    }
  }
  
  Future<AuthResult> signIn({required String email, required String password}) async {
    if (!_isInitialized) {
      return AuthResult(error: 'SupabaseService not initialized');
    }
    
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
      // Get user details directly from the users table
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
      if (response == null) {
        // Fallback to auth user data if possible
        final authUser = _client.auth.currentUser;
        if (authUser != null && authUser.id == userId) {
          return User(
            id: userId,
            username: authUser.userMetadata?['username'] ?? 'User',
            email: authUser.email ?? '',
            password: '',
            role: UserRole.buyer, // Default role
            isApproved: false,
          );
        }
        return null;
      }
      
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
        phoneNumber: response['phone_number'],
        whatsappNumber: response['whatsapp_number'],
        sellerBio: response['seller_bio'],
        sellerRating: response['seller_rating'] != null 
            ? (response['seller_rating'] as num).toDouble() 
            : null,
        businessName: response['business_name'],
        businessAddress: response['business_address'],
      );
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      
      // Fallback to auth user data if possible
      final authUser = _client.auth.currentUser;
      if (authUser != null && authUser.id == userId) {
        return User(
          id: userId,
          username: authUser.userMetadata?['username'] ?? 'User',
          email: authUser.email ?? '',
          password: '',
          role: UserRole.buyer, // Default role
          isApproved: false,
        );
      }
      
      return null;
    }
  }
  
  // Update seller profile
  Future<bool> updateSellerProfile({
    required String sellerId,
    String? phoneNumber,
    String? whatsappNumber,
    String? sellerBio,
    String? businessName,
    String? businessAddress,
  }) async {
    try {
      // Call the SQL function that bypasses RLS
      final result = await _client.rpc(
        'update_seller_profile',
        params: {
          'p_seller_id': sellerId,
          'p_phone_number': phoneNumber,
          'p_whatsapp_number': whatsappNumber,
          'p_seller_bio': sellerBio,
          'p_business_name': businessName,
          'p_business_address': businessAddress,
        },
      );
      
      if (result == true) {
        debugPrint('Successfully updated seller profile for seller ID: $sellerId');
        return true;
      } else {
        debugPrint('No changes were made to seller profile for seller ID: $sellerId');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating seller profile: $e');
      return false;
    }
  }
  
  // Check if seller profile is complete
  Future<bool> isSellerProfileComplete(String sellerId) async {
    try {
      final user = await _getUserDetails(sellerId);
      return user?.hasCompleteSellerProfile ?? false;
    } catch (e) {
      debugPrint('Error checking seller profile: $e');
      return false;
    }
  }
  
  // PRODUCTS METHODS
  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('*, seller:seller_id(id, username, email, is_approved, phone_number, whatsapp_number, seller_bio, seller_rating, business_name, business_address)')
          .order('created_at', ascending: false);
      
      return response.map<Product>((item) {
        // Use null-safe access and provide default values
        final sellerId = item['seller_id'] as String? ?? '';
        final sellerData = item['seller'] as Map<String, dynamic>?;
        final sellerName = sellerData != null ? (sellerData['username'] as String? ?? 'Unknown Seller') : 'Unknown Seller';
        final sellerEmail = sellerData != null ? sellerData['email'] as String? : null;
        final sellerIsVerified = sellerData != null ? sellerData['is_approved'] as bool? ?? false : false;
        
        // Get seller rating from the database or use default
        final sellerRating = sellerData != null && sellerData['seller_rating'] != null
            ? (sellerData['seller_rating'] as num).toDouble()
            : 4.5; // Default rating if not available
        
        // Get WhatsApp number for contact integration
        final whatsappNumber = sellerData != null ? sellerData['whatsapp_number'] as String? : null;
        final businessName = sellerData != null ? sellerData['business_name'] as String? : null;
        
        return Product(
          id: item['id'] as String? ?? '',
          name: item['name'] as String? ?? 'Unnamed Product',
          description: item['description'] as String? ?? '',
          price: item['price'] != null ? (item['price'] as num).toDouble() : 0.0,
          imageUrl: item['image_url'] as String? ?? 'assets/images/placeholder.jpg',
          category: item['category'] as String? ?? 'Uncategorized',
          location: item['location'] as String? ?? 'Unknown Location',
          sellerId: sellerId,
          sellerName: businessName ?? sellerName, // Use business name if available
          sellerEmail: sellerEmail,
          sellerRating: sellerRating,
          sellerIsVerified: sellerIsVerified,
          sellerWhatsapp: whatsappNumber,
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
          .select('*, order_items(*, products(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      List<Order> orders = [];
      for (final orderData in response) {
        final order = Order.fromJson(orderData);
        
        // Parse order items
        final items = <CartItem>[];
        for (final itemData in orderData['order_items']) {
          final productData = itemData['products'];
          if (productData != null) {
            final product = Product.fromJson({'products': productData});
            items.add(CartItem(
              product: product,
              quantity: itemData['quantity'] as int,
            ));
          }
        }
        order.items = items;
        orders.add(order);
      }
      
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
      
      // Get orders that contain seller's products
      final response = await _client
          .from('orders')
          .select('*, order_items(*, products(*))')
          .order('created_at', ascending: false);
      
      List<Order> orders = [];
      for (final orderData in response) {
        final order = Order.fromJson(orderData);
        
        // Parse order items and filter for seller's products
        final items = <CartItem>[];
        for (final itemData in orderData['order_items']) {
          final productData = itemData['products'];
          if (productData != null) {
            final product = Product.fromJson({'products': productData});
            if (productIds.contains(product.id)) {
              items.add(CartItem(
                product: product,
                quantity: itemData['quantity'] as int,
              ));
            }
          }
        }
        
        // Only add orders that have items from this seller
        if (items.isNotEmpty) {
          order.items = items;
          orders.add(order);
        }
      }
      
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