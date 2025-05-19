import 'package:zim_shop/models/cart_item.dart';

class Order {
  final String id;
  final String userId;
  List<CartItem> _items;
  final double totalAmount;
  final DateTime date;
  final String status;
  final String? shippingName;
  final String? shippingAddress;
  final String? shippingPhone;
  final String? shippingEmail;
  final String? shippingCity;
  final String? shippingPostalCode;
  
  Order({
    required this.id,
    required this.userId,
    List<CartItem>? items,
    required this.totalAmount,
    required this.date,
    required this.status,
    this.shippingName,
    this.shippingAddress,
    this.shippingPhone,
    this.shippingEmail,
    this.shippingCity,
    this.shippingPostalCode,
  }) : _items = items ?? [];

  List<CartItem> get items => _items;
  set items(List<CartItem> value) {
    _items = value;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      items: [], // Items will be loaded separately
      totalAmount: (json['total_amount'] as num).toDouble(),
      date: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
      shippingName: json['shipping_name'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      shippingEmail: json['shipping_email'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingPostalCode: json['shipping_postal_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'created_at': date.toIso8601String(),
      'status': status,
      'shipping_name': shippingName,
      'shipping_address': shippingAddress,
      'shipping_phone': shippingPhone,
      'shipping_email': shippingEmail,
      'shipping_city': shippingCity,
      'shipping_postal_code': shippingPostalCode,
    };
  }
}