import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/providers/app_state.dart';

class MockData {
  static final List<User> users = [
    User(
      id: 1, 
      username: 'buyer1', 
      email: 'buyer1@example.com',
      password: 'password123',
      role: UserRole.buyer
    ),
    User(
      id: 2, 
      username: 'seller1', 
      email: 'seller1@example.com',
      password: 'password123',
      role: UserRole.seller, 
      isApproved: true
    ),
    User(
      id: 3, 
      username: 'admin', 
      email: 'admin@example.com',
      password: 'admin123',
      role: UserRole.admin
    ),
    User(
      id: 4, 
      username: 'seller2', 
      email: 'seller2@example.com',
      password: 'password123',
      role: UserRole.seller, 
      isApproved: false
    ),
  ];

  static final List<Product> products = [
    Product(
      id: 1,
      name: 'Fresh Tomatoes - Mbare',
      description: 'Locally grown tomatoes from Mbare Musika, Harare.',
      price: 2.50,
      imageUrl: 'assets/images/tomatoes.jpg',
      category: 'Vegetables',
      location: 'Mbare Musika',
      sellerId: 2,
      sellerName: 'seller1',
    ),
    Product(
      id: 2,
      name: 'Maize Cobs - Sakubva',
      description: 'Freshly harvested maize from Sakubva market in Mutare.',
      price: 1.20,
      imageUrl: 'assets/images/maize.jpg',
      category: 'Grains',
      location: 'Sakubva',
      sellerId: 2,
      sellerName: 'seller1',
    ),
    Product(
      id: 3,
      name: 'Potatoes - Kudzanai',
      description: 'Premium white potatoes from Kudzanai market, Gweru.',
      price: 3.00,
      imageUrl: 'assets/images/potatoes.jpg',
      category: 'Vegetables',
      location: 'Kudzanai',
      sellerId: 4,
      sellerName: 'seller2',
    ),
    Product(
      id: 4,
      name: 'Red Onions - Mbare',
      description: 'Locally sourced red onions from Mbare Musika.',
      price: 1.80,
      imageUrl: 'assets/images/onions.jpg',
      category: 'Vegetables',
      location: 'Mbare Musika',
      sellerId: 2,
      sellerName: 'seller1',
    ),
    Product(
      id: 5,
      name: 'Bananas - Sakubva',
      description: 'Sweet ripe bananas from Sakubva market.',
      price: 2.20,
      imageUrl: 'assets/images/bananas.jpg',
      category: 'Fruits',
      location: 'Sakubva',
      sellerId: 4,
      sellerName: 'seller2',
    ),
     Product(
      id: 5,
      name: 'Motor Spare Parts - Kaguvi',
      description: 'Motor spare parts from Kaguvi market.',
      price: 2.20,
      imageUrl: 'assets/images/motor.jpg',
      category: 'Spare Parts',
      location: 'Kaguvi',
      sellerId: 4,
      sellerName: 'seller5',
    ),
  ];

  static final List<Order> orders = [
    Order(
      id: 1,
      userId: 1,
      items: [
        CartItem(product: products[0], quantity: 2),
        CartItem(product: products[3], quantity: 1),
      ],
      totalAmount: 6.80,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Delivered',
    ),
    Order(
      id: 2,
      userId: 1,
      items: [
        CartItem(product: products[1], quantity: 3),
      ],
      totalAmount: 3.60,
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Delivered',
    ),
  ];

  static List<String> categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Meat',
    'Dairy',
    'Spices',
  ];

  static List<String> locations = [
    'Mbare Musika',
    'Sakubva',
    'Kudzanai',
    'Mucheke',
    'Gokwe',
    "Kaguvi"
  ];
}
