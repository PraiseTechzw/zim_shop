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
    
    // First ensure the user exists in the database
    await ensureUserExistsInDatabase();
    
    // Then fetch user data from 'users' table to get role and other details
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
      debugPrint('❌ Signup failed: SupabaseService not initialized');
      return AuthResult(error: 'SupabaseService not initialized');
    }
    
    try {
      debugPrint('🔄 Starting signup process for user: $email');
      
      // Create a service role client for admin operations
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );
      
      // 1. Create auth user with metadata
      debugPrint('📝 Creating auth user...');
      
      final response = await serviceClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {
            'username': username,
            'role': role.toString().split('.').last,
          },
        ),
      );
      
      if (response.user == null) {
        debugPrint('❌ Auth user creation failed: No user returned from signUp');
        return AuthResult(error: 'Failed to create user');
      }
      
      debugPrint('✅ Auth user created successfully with ID: ${response.user!.id}');
      
      // 2. Add user to database using service role client
      try {
        debugPrint('🔄 Adding user to database...');
            final insertResult = await serviceClient.from('users').insert({
              'id': response.user!.id,
              'email': email,
              'username': username,
              'role': role.toString().split('.').last,
              'is_approved': role != UserRole.seller,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }).select();
            
            debugPrint('📝 Insert result: $insertResult');
            debugPrint('✅ User added to database successfully');
          } catch (insertError) {
            debugPrint('❌ Error inserting user: $insertError');
            if (insertError is PostgrestException) {
              debugPrint('  - Code: ${insertError.code}');
              debugPrint('  - Message: ${insertError.message}');
              debugPrint('  - Details: ${insertError.details}');
            }
        // Continue anyway as we can try to add the user later
      }
      
      // 3. Get complete user data using service role client
      User? user;
      try {
        debugPrint('🔄 Fetching complete user details for ID: ${response.user!.id}');
        final userData = await serviceClient
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();
            
        if (userData != null) {
          user = User(
            id: userData['id'],
            username: userData['username'],
            email: userData['email'],
            password: '',
            role: UserRole.values.firstWhere(
              (r) => r.toString().split('.').last == userData['role'],
              orElse: () => UserRole.buyer,
            ),
            isApproved: userData['is_approved'] ?? false,
            phoneNumber: userData['phone_number'],
            whatsappNumber: userData['whatsapp_number'],
            sellerBio: userData['seller_bio'],
            sellerRating: userData['seller_rating'] != null 
                ? (userData['seller_rating'] as num).toDouble() 
                : null,
            businessName: userData['business_name'],
            businessAddress: userData['business_address'],
          );
        }
        debugPrint('✅ Successfully fetched user details');
        debugPrint('📝 User details: {id: ${user?.id}, username: ${user?.username}, email: ${user?.email}, role: ${user?.role}, isApproved: ${user?.isApproved}}');
      } catch (e) {
        debugPrint('❌ Error fetching user details: $e');
        // Create basic user object as fallback
        user = User(
          id: response.user!.id,
          username: username,
          email: email,
          password: '',
          role: role,
          isApproved: role != UserRole.seller,
        );
        debugPrint('📝 Created basic user object as fallback');
      }
      
      debugPrint('✅ Signup process completed successfully for user: $email');
      return AuthResult(user: user);
    } catch (e) {
      debugPrint('❌ Error during signup: $e');
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
      // Use service role client for fetching user details
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );

      // Get user details directly from the users table
      final response = await serviceClient
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
      debugPrint('Fetching products with seller information...');
      
      // Create a service role client for admin operations
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );
      
      // Use a join query to fetch products with seller information using service role
      final response = await serviceClient
          .from('products')
          .select('''
            *,
            seller:users!products_seller_id_fkey (
              id,
              username,
              email,
              is_approved,
              phone_number,
              whatsapp_number,
              business_name
            )
          ''')
          .order('created_at', ascending: false);
      
      debugPrint('Found ${response.length} products');
      debugPrint('Raw response: $response');
      
      // Map products with seller information
      return response.map<Product>((item) {
        final sellerData = item['seller'] as Map<String, dynamic>?;
        
        debugPrint('\nProcessing product ${item['id']}');
        debugPrint('Seller ID: ${item['seller_id']}');
        
        if (sellerData != null) {
          debugPrint('Found seller data:');
          debugPrint('  - Username: ${sellerData['username']}');
          debugPrint('  - Email: ${sellerData['email']}');
          debugPrint('  - Is Approved: ${sellerData['is_approved']}');
          debugPrint('  - Phone: ${sellerData['phone_number']}');
          debugPrint('  - WhatsApp: ${sellerData['whatsapp_number']}');
          debugPrint('  - Business Name: ${sellerData['business_name']}');
        } else {
          debugPrint('No seller data found for product');
        }
        
        // Get seller information with proper null handling
        final sellerUsername = sellerData?['username'] as String? ?? 'Unknown Seller';
        final sellerEmail = sellerData?['email'] as String?;
        final sellerIsVerified = sellerData?['is_approved'] as bool? ?? false;
        final whatsappNumber = sellerData?['whatsapp_number'] as String?;
        
        debugPrint('Creating Product object with seller info:');
        debugPrint('  - Seller Username: $sellerUsername');
        debugPrint('  - Seller Email: $sellerEmail');
        debugPrint('  - Seller Verified: $sellerIsVerified');
        debugPrint('  - Seller WhatsApp: $whatsappNumber');
        
        return Product(
          id: item['id'] as String? ?? '',
          name: item['name'] as String? ?? 'Unnamed Product',
          description: item['description'] as String? ?? '',
          price: item['price'] != null ? (item['price'] as num).toDouble() : 0.0,
          imageUrl: item['image_url'] as String? ?? 'assets/images/placeholder.jpg',
          category: item['category'] as String? ?? 'Uncategorized',
          location: item['location'] as String? ?? 'Unknown Location',
          sellerId: item['seller_id'] as String? ?? '',
          sellerName: sellerUsername,
          sellerUsername: sellerUsername,
          sellerEmail: sellerEmail,
          sellerIsVerified: sellerIsVerified,
          sellerWhatsapp: whatsappNumber,
          isActive: item['is_active'] as bool? ?? true,
          createdAt: item['created_at'] as String?,
          updatedAt: item['updated_at'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (e is PostgrestException) {
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Details: ${e.details}');
      }
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
      final response = await _client
          .from('products')
          .update({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'category': product.category,
            'location': product.location,
            'is_active': product.isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', product.id);
      
      return response != null;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }
  
  Future<bool> deleteProduct(String productId) async {
    try {
      // First delete any associated order items
      await _client
          .from('order_items')
          .delete()
          .eq('product_id', productId);
      
      // Then delete the product
      final response = await _client
          .from('products')
          .delete()
          .eq('id', productId);
      
      return response != null;
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
      debugPrint('Creating order with data: ${order.toJson()}');
      
      // Create a service role client for admin operations
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );
      
      // Create order using service role client to bypass RLS
      final orderResponse = await serviceClient.from('orders').insert({
        'user_id': order.userId,
        'total_amount': order.totalAmount,
        'status': order.status,
        'shipping_name': order.shippingName,
        'shipping_email': order.shippingEmail,
        'shipping_phone': order.shippingPhone,
        'shipping_address': order.shippingAddress,
        'shipping_city': order.shippingCity,
        'shipping_postal_code': order.shippingPostalCode,
      }).select().single();
      
      debugPrint('Order created successfully: $orderResponse');
      
      // Add order items using service role client
      final orderId = orderResponse['id'];
      for (var item in order.items) {
        await serviceClient.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        });
      }
      
      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      if (e is PostgrestException) {
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Details: ${e.details}');
      }
      return false;
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select()
          .single();
          
      return response != null;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }
  
  // ADMIN METHODS
  Future<bool> approveUser(String userId, bool isApproved) async {
    try {
      debugPrint('🔄 Updating seller approval status for user: $userId');
      
      // Create a service role client for admin operations
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );
      
      // 1. Update the user's approval status in the database
      final updateResult = await serviceClient
          .from('users')
          .update({
            'is_approved': isApproved,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select();
          
      if (updateResult.isEmpty) {
        debugPrint('❌ Failed to update user approval status: No rows affected');
        return false;
      }
      
      debugPrint('✅ Successfully updated user approval status in database');
      
      // 2. If the user is currently logged in, update their session
      final currentUser = _client.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        try {
          // Update the user's metadata to reflect the new approval status
          await serviceClient.auth.admin.updateUserById(
            userId,
            attributes: AdminUserAttributes(
              userMetadata: {
                ...currentUser.userMetadata ?? {},
                'is_approved': isApproved,
              },
            ),
          );
          debugPrint('✅ Successfully updated user metadata');
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to update user metadata: $e');
          // Continue anyway as the database update was successful
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error updating seller approval status: $e');
      if (e is PostgrestException) {
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Details: ${e.details}');
      }
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

  // Add this new method
  Future<bool> ensureUserExistsInDatabase() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user is currently logged in');
        return false;
      }

      debugPrint('🔄 Checking if user ${currentUser.id} exists in database...');
      
      // Create a service role client for admin operations
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );

      // Check if user exists in database
      final existingUser = await serviceClient
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
          
      debugPrint('📝 Database check result: ${existingUser != null ? 'User found' : 'User not found'}');
      
      if (existingUser == null) {
        debugPrint('⚠️ User not found in database, adding now...');
        try {
          // Get role from metadata or default to buyer
          final role = currentUser.userMetadata?['role'] ?? 'buyer';
          final username = currentUser.userMetadata?['username'] ?? 
                          currentUser.email?.split('@').first ?? 
                          'user_${currentUser.id.substring(0, 8)}';
          
          final insertResult = await serviceClient.from('users').insert({
            'id': currentUser.id,
            'email': currentUser.email,
            'username': username,
            'role': role,
            'is_approved': role != 'seller',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).select();
          
          debugPrint('📝 Insert result: $insertResult');
          debugPrint('✅ User added to database successfully');
          return true;
        } catch (insertError) {
          debugPrint('❌ Error inserting user: $insertError');
          if (insertError is PostgrestException) {
            debugPrint('  - Code: ${insertError.code}');
            debugPrint('  - Message: ${insertError.message}');
            debugPrint('  - Details: ${insertError.details}');
          }
          return false;
        }
      }
      
      debugPrint('✅ User already exists in database');
      return true;
    } catch (e) {
      debugPrint('❌ Error ensuring user exists in database: $e');
      if (e is PostgrestException) {
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Details: ${e.details}');
      }
      return false;
    }
  }

  // Add this new method to create an admin account
  Future<AuthResult> createAdminAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ Admin creation failed: SupabaseService not initialized');
      return AuthResult(error: 'SupabaseService not initialized');
    }
    
    try {
      debugPrint('🔄 Starting admin account creation for: $email');
      
      // Create a service role client for admin operations
      final serviceClient = SupabaseClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );
      
      // 1. Create auth user with admin metadata
      debugPrint('📝 Creating auth user...');
      
      final response = await serviceClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {
            'username': username,
            'role': 'admin',
          },
        ),
      );
      
      if (response.user == null) {
        debugPrint('❌ Admin user creation failed: No user returned');
        return AuthResult(error: 'Failed to create admin user');
      }
      
      debugPrint('✅ Admin auth user created successfully with ID: ${response.user!.id}');
      
      // 2. Add admin user to database
      try {
        debugPrint('🔄 Adding admin to database...');
        final insertResult = await serviceClient.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'role': 'admin',
          'is_approved': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select();
        
        debugPrint('📝 Insert result: $insertResult');
        debugPrint('✅ Admin added to database successfully');
      } catch (insertError) {
        debugPrint('❌ Error inserting admin to database: $insertError');
        if (insertError is PostgrestException) {
          debugPrint('  - Code: ${insertError.code}');
          debugPrint('  - Message: ${insertError.message}');
          debugPrint('  - Details: ${insertError.details}');
        }
        // Continue anyway as we can try to add the user later
      }
      
      // 3. Get complete user data
      User? user;
      try {
        debugPrint('🔄 Fetching admin details...');
        user = await _getUserDetails(response.user!.id);
        debugPrint('✅ Successfully fetched admin details');
      } catch (e) {
        debugPrint('❌ Error fetching admin details: $e');
        // Create basic admin user object
        user = User(
          id: response.user!.id,
          username: username,
          email: email,
          password: '',
          role: UserRole.admin,
          isApproved: true,
        );
        debugPrint('📝 Created basic admin user object as fallback');
      }
      
      debugPrint('✅ Admin account creation completed successfully');
      return AuthResult(user: user);
    } catch (e) {
      debugPrint('❌ Error creating admin account: $e');
      if (e is PostgrestException) {
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
        debugPrint('  - Details: ${e.details}');
      }
      return AuthResult(error: e.toString());
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              product_id,
              quantity,
              price,
              products (
                id,
                name,
                description,
                price,
                image_url,
                location,
                category,
                seller_id,
                is_active,
                created_at,
                updated_at
              )
            )
          ''')
          .order('created_at', ascending: false);
      
      return response.map<Order>((item) {
        final items = (item['order_items'] as List).map((i) {
          final productData = i['products'];
          final product = Product(
            id: productData['id'],
            name: productData['name'],
            description: productData['description'],
            price: (productData['price'] as num).toDouble(),
            imageUrl: productData['image_url'],
            location: productData['location'],
            category: productData['category'],
            sellerId: productData['seller_id'],
            isActive: productData['is_active'],
            createdAt: productData['created_at'],
            updatedAt: productData['updated_at'],
          );
          
          return CartItem(
            product: product,
            quantity: i['quantity'],
          );
        }).toList();
        
        return Order(
          id: item['id'],
          userId: item['user_id'],
          items: items,
          totalAmount: (item['total_amount'] as num).toDouble(),
          date: DateTime.parse(item['created_at']),
          status: item['status'],
          shippingName: item['shipping_name'],
          shippingAddress: item['shipping_address'],
          shippingPhone: item['shipping_phone'],
          shippingEmail: item['shipping_email'],
          shippingCity: item['shipping_city'],
          shippingPostalCode: item['shipping_postal_code'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAdminSettings() async {
    try {
      final response = await _client
          .from('admin_settings')
          .select()
          .single();
      
      return response ?? {};
    } catch (e) {
      debugPrint('Error fetching admin settings: $e');
      return {};
    }
  }
  
  Future<bool> updateAdminSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _client
          .from('admin_settings')
          .upsert(settings)
          .select()
          .single();
      
      return response != null;
    } catch (e) {
      debugPrint('Error updating admin settings: $e');
      return false;
    }
  }
  
  Future<bool> updateAdminPassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      
      return response.user != null;
    } catch (e) {
      debugPrint('Error updating admin password: $e');
      return false;
    }
  }

  Future<bool> updateBuyerProfile({
    required String buyerId,
    String? phoneNumber,
    String? whatsappNumber,
    String? deliveryAddress,
  }) async {
    try {
      // Call the SQL function that bypasses RLS
      final result = await _client.rpc(
        'update_buyer_profile',
        params: {
          'p_buyer_id': buyerId,
          'p_phone_number': phoneNumber,
          'p_whatsapp_number': whatsappNumber,
          'p_delivery_address': deliveryAddress,
        },
      );
      
      if (result == true) {
        debugPrint('Successfully updated buyer profile for buyer ID: $buyerId');
        return true;
      } else {
        debugPrint('No changes were made to buyer profile for buyer ID: $buyerId');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating buyer profile: $e');
      return false;
    }
  }
} 