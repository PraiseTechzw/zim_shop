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
      
      final response = await _supabaseService.client
          .from('orders')
          .insert(orderData)
          .select()
          .single();
      
      if (response == null) {
        return null;
      }
      
      // Create order items
      for (final item in items) {
        await _supabaseService.client.from('order_items').insert({
          'order_id': response['id'],
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        });
      }
      
      // Load order items
      final orderItemsResponse = await _supabaseService.client
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', response['id']);
      
      final orderItems = orderItemsResponse.map((item) {
        return CartItem(
          product: Product.fromJson(item['products']),
          quantity: item['quantity'] as int,
        );
      }).toList();
      
      // Create order with items
      final order = Order.fromJson(response);
      order.items.addAll(orderItems);
      
      // Clear cart after successful order
      clear();
      
      return order;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }
}