
import 'package:zim_shop/models/cart_item.dart';

class Order {
  final int id;
  final int userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final String status;
  
  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.status,
  });
}