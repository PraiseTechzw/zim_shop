import 'package:flutter/material.dart';
    import 'package:zim_shop/models/cart_item.dart';
    import 'package:zim_shop/models/order.dart';
    import 'package:zim_shop/models/product.dart';
    import 'package:zim_shop/mock_data.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  
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
  
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
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
    }
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  Order checkout(int userId) {
    final order = Order(
      id: MockData.orders.length + 1,
      userId: userId,
      items: List.from(_items),
      totalAmount: totalAmount,
      date: DateTime.now(),
      status: 'Processing',
    );
    
    MockData.orders.add(order);
    clear();
    return order;
  }
}