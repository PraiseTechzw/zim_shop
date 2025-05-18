import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/services/firebase_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseService _firebaseService = FirebaseService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  List<CartItem> get items => _items;
  
  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  }
  
  int get itemCount => _items.length;

  // Load cart from Firebase if available
  Future<void> loadCart() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final cartDoc = await FirebaseFirestore.instance
            .collection('carts')
            .doc(userId)
            .get();

        if (cartDoc.exists && cartDoc.data() != null) {
          final cartData = cartDoc.data()!;
          final cartItems = cartData['items'] as List<dynamic>;
          
          // Clear existing items
          _items.clear();
          
          // Fetch each product data and add to cart
          for (var item in cartItems) {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(item['productId'].toString())
                .get();
                
            if (productDoc.exists) {
              final productData = productDoc.data()!;
              final product = Product(
                id: int.parse(productDoc.id),
                name: productData['name'] ?? '',
                description: productData['description'] ?? '',
                price: (productData['price'] ?? 0).toDouble(),
                imageUrl: productData['imageUrl'] ?? '',
                category: productData['category'] ?? '',
                location: productData['location'] ?? '',
                sellerId: int.parse(productData['sellerId'] ?? '0'),
                sellerName: productData['sellerName'] ?? '',
              );
              
              _items.add(CartItem(
                product: product,
                quantity: item['quantity'] ?? 1,
              ));
            }
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }
  
  // Save cart to Firebase
  Future<void> _saveCart() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(userId)
            .set({
          'items': _items.map((item) => {
            'productId': item.product.id.toString(),
            'quantity': item.quantity,
          }).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
  
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
    _saveCart();
  }
  
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    _saveCart();
  }
  
  void updateQuantity(int productId, int quantity) {
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
      _saveCart();
    }
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }
  
  Future<Order> checkout(int userId) async {
    try {
      // Create order in Firebase
      final orderId = await _firebaseService.createOrder(_items, totalAmount, userId);
      
      // Create local Order object
      final order = Order(
        id: int.parse(orderId),
        userId: userId,
        items: List.from(_items),
        totalAmount: totalAmount,
        date: DateTime.now(),
        status: 'Processing',
      );
      
      // Clear cart after successful checkout
      clear();
      
      return order;
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }
}