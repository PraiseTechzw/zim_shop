import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? location;
  final String? category;
  final String? sellerId;
  final String? sellerName;
  final String? sellerUsername;
  final String? sellerEmail;
  final String? sellerWhatsapp;
  final bool? sellerIsVerified;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.location,
    this.category,
    this.sellerId,
    this.sellerName,
    this.sellerUsername,
    this.sellerEmail,
    this.sellerWhatsapp,
    this.sellerIsVerified,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    debugPrint('Product.fromJson input: $json');
    
    // Handle nested products object
    final productData = json['products'] ?? json;
    debugPrint('Extracted product data: $productData');
    
    return Product(
      id: productData['id'] as String,
      name: productData['name'] as String,
      description: productData['description'] as String,
      price: (productData['price'] as num).toDouble(),
      imageUrl: productData['image_url'] as String?,
      location: productData['location'] as String?,
      category: productData['category'] as String?,
      sellerId: productData['seller_id'] as String?,
      isActive: productData['is_active'] as bool? ?? true,
      createdAt: productData['created_at'] as String,
      updatedAt: productData['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'location': location,
      'category': category,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_username': sellerUsername,
      'seller_email': sellerEmail,
      'seller_whatsapp': sellerWhatsapp,
      'seller_is_verified': sellerIsVerified,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? location,
    String? category,
    String? sellerId,
    String? sellerName,
    String? sellerUsername,
    String? sellerEmail,
    String? sellerWhatsapp,
    bool? sellerIsVerified,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerUsername: sellerUsername ?? this.sellerUsername,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerWhatsapp: sellerWhatsapp ?? this.sellerWhatsapp,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}