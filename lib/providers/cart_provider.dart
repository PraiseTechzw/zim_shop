import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/supabase_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final SupabaseService _supabaseService = SupabaseService();
  
  List<CartItem> get items => _items;
  
  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  }
  
  int get itemCount => _items.length;
  
  void addItem(Product product, int quantity) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex] = CartItem(
        product: _items[existingIndex].product,
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }
  
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }
  
  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = CartItem(
          product: _items[index].product,
          quantity: quantity,
        );
      }
      notifyListeners();
    }
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  Future<Order> checkout({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String postalCode,
  }) async {
    try {
      debugPrint('Starting checkout process...');
      
      if (_items.isEmpty) {
        throw Exception('Cart is empty');
      }

      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.currentUser == null) {
        throw Exception('User not logged in');
      }
      debugPrint('User ID: ${appState.currentUser!.id}');

      // Create order with shipping information
      final orderData = {
        'user_id': appState.currentUser!.id,
        'total_amount': totalAmount,
        'status': 'pending',
        'shipping_name': name,
        'shipping_email': email,
        'shipping_phone': phone,
        'shipping_address': address,
        'shipping_city': city,
        'shipping_postal_code': postalCode,
        'created_at': DateTime.now().toIso8601String(),
      };
      debugPrint('Order data: $orderData');

      final response = await _supabaseService.client
          .from('orders')
          .insert(orderData)
          .select()
          .single();
      debugPrint('Order response: $response');

      if (response == null) {
        throw Exception('Failed to create order: No response from server');
      }

      final order = Order.fromJson(response);
      debugPrint('Created order: ${order.toJson()}');

      // Create order items
      for (final item in _items) {
        if (item.product == null) {
          throw Exception('Product data is missing for cart item');
        }
        
        final itemData = {
          'order_id': order.id,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        };
        debugPrint('Creating order item: $itemData');
        
        final itemResponse = await _supabaseService.client
            .from('order_items')
            .insert(itemData)
            .select()
            .single();
            
        if (itemResponse == null) {
          throw Exception('Failed to create order item: No response from server');
        }
      }

      // Load order items with product details
      final itemsResponse = await _supabaseService.client
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', order.id);
      debugPrint('Order items response: $itemsResponse');

      if (itemsResponse == null) {
        throw Exception('Failed to load order items: No response from server');
      }

      final orderItems = <CartItem>[];
      for (final item in itemsResponse) {
        debugPrint('Processing order item: $item');
        
        final productData = item['products'];
        if (productData == null) {
          throw Exception('Product data is missing for order item: $item');
        }
        
        debugPrint('Raw product data: $productData');
        
        try {
          // Create a new map with the product data, ensuring all fields are properly typed
          final Map<String, dynamic> productMap = {
            'products': {
              'id': productData['id']?.toString() ?? '',
              'name': productData['name']?.toString() ?? '',
              'description': productData['description']?.toString(),
              'price': productData['price'] is num ? (productData['price'] as num).toDouble() : 0.0,
              'image_url': productData['image_url']?.toString(),
              'location': productData['location']?.toString(),
              'category': productData['category']?.toString(),
              'seller_id': productData['seller_id']?.toString(),
              'is_active': productData['is_active'] is bool ? productData['is_active'] as bool : null,
              'created_at': productData['created_at']?.toString(),
              'updated_at': productData['updated_at']?.toString(),
            }
          };
          
          debugPrint('Processed product map: $productMap');
          
          final product = Product.fromJson(productMap);
          final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
          orderItems.add(CartItem(product: product, quantity: quantity));
        } catch (e, stackTrace) {
          debugPrint('Error creating product: $e');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('Product data that caused error: $productData');
          rethrow;
        }
      }
      
      order.items = orderItems;
      debugPrint('Added ${orderItems.length} items to order');

      return order;
    } catch (e, stackTrace) {
      debugPrint('Error in checkout: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}