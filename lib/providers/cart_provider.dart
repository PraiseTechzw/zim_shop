import 'package:flutter/material.dart';
import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/services/supabase_service.dart';

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
  
  Future<Order?> checkout(String userId, {Map<String, String>? shippingInfo}) async {
    try {
      debugPrint('Starting checkout process...');
      debugPrint('User ID: $userId');
      debugPrint('Shipping Info: $shippingInfo');
      
      // Create order in Supabase
      final orderData = {
        'user_id': userId,
        'total_amount': totalAmount,
        'status': 'pending',
        'shipping_name': shippingInfo?['name'] ?? '',
        'shipping_address': shippingInfo?['address'] ?? '',
        'shipping_phone': shippingInfo?['phone'] ?? '',
        'shipping_email': shippingInfo?['email'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Order Data: $orderData');
      
      final response = await _supabaseService.client
          .from('orders')
          .insert(orderData)
          .select()
          .single();
      
      debugPrint('Order Response: $response');
      
      if (response == null) {
        throw Exception('Failed to create order: No response from server');
      }
      
      // Create order items
      for (final item in items) {
        final itemData = {
          'order_id': response['id'],
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        };
        debugPrint('Creating order item: $itemData');
        
        await _supabaseService.client.from('order_items').insert(itemData);
      }
      
      // Load order items
      final orderItemsResponse = await _supabaseService.client
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', response['id']);
      
      debugPrint('Order Items Response: $orderItemsResponse');
      
      if (orderItemsResponse == null) {
        throw Exception('Failed to load order items');
      }

      final List<CartItem> orderItems = [];
      for (final item in orderItemsResponse) {
        final productData = item['products'];
        if (productData == null) {
          debugPrint('Warning: Product data is null for order item: $item');
          continue;
        }
        
        try {
          final cartItem = CartItem(
            product: Product.fromJson(productData as Map<String, dynamic>),
            quantity: item['quantity'] as int,
          );
          orderItems.add(cartItem);
        } catch (e) {
          debugPrint('Error processing order item: $e');
          debugPrint('Item data: $item');
        }
      }
      
      // Create order with items
      final order = Order(
        id: response['id'] as String,
        userId: response['user_id'] as String,
        items: orderItems,
        totalAmount: (response['total_amount'] as num).toDouble(),
        date: DateTime.parse(response['created_at'] as String),
        status: response['status'] as String,
        shippingName: response['shipping_name'] as String? ?? '',
        shippingAddress: response['shipping_address'] as String? ?? '',
        shippingPhone: response['shipping_phone'] as String? ?? '',
        shippingEmail: response['shipping_email'] as String? ?? '',
      );
      
      debugPrint('Created Order: ${order.toJson()}');
      
      // Clear cart after successful order
      clear();
      
      return order;
    } catch (e, stackTrace) {
      debugPrint('Error creating order: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}