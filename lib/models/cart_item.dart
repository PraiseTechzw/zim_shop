
import 'package:zim_shop/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;
  
  CartItem({
    required this.product,
    required this.quantity,
  });
}