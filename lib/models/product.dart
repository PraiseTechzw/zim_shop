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
  final String? sellerEmail;
  final String? sellerWhatsapp;
  final double? sellerRating;
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
    this.sellerEmail,
    this.sellerWhatsapp,
    this.sellerRating,
    this.sellerIsVerified,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Product data is null');
    }

    debugPrint('Product.fromJson input: $json');

    // Extract the actual product data if it's nested
    final productData = json['products'] ?? json;
    debugPrint('Extracted product data: $productData');

    // Ensure we have a valid map
    if (productData is! Map<String, dynamic>) {
      throw Exception('Invalid product data format');
    }

    try {
      // Required fields with safe defaults
      final id = productData['id']?.toString() ?? '';
      if (id.isEmpty) {
        throw Exception('Product ID is required');
      }

      final name = productData['name']?.toString() ?? '';
      if (name.isEmpty) {
        throw Exception('Product name is required');
      }

      // Handle price conversion safely
      double price = 0.0;
      if (productData['price'] != null) {
        if (productData['price'] is num) {
          price = (productData['price'] as num).toDouble();
        } else if (productData['price'] is String) {
          price = double.tryParse(productData['price'] as String) ?? 0.0;
        }
      }

      // Optional fields with null safety
      final description = productData['description']?.toString();
      final imageUrl = productData['image_url']?.toString();
      final location = productData['location']?.toString();
      final category = productData['category']?.toString();
      final sellerId = productData['seller_id']?.toString();
      final sellerName = productData['seller_name']?.toString();
      final sellerEmail = productData['seller_email']?.toString();
      final sellerWhatsapp = productData['seller_whatsapp']?.toString();
      final sellerRating = productData['seller_rating'] is num ? (productData['seller_rating'] as num).toDouble() : null;
      final sellerIsVerified = productData['seller_is_verified'] is bool ? productData['seller_is_verified'] as bool : null;
      final isActive = productData['is_active'] is bool ? productData['is_active'] as bool : null;
      final createdAt = productData['created_at']?.toString();
      final updatedAt = productData['updated_at']?.toString();

      return Product(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        location: location,
        category: category,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerEmail: sellerEmail,
        sellerWhatsapp: sellerWhatsapp,
        sellerRating: sellerRating,
        sellerIsVerified: sellerIsVerified,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e, stackTrace) {
      debugPrint('Error creating Product object: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Product data that caused error: $productData');
      rethrow;
    }
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
      'seller_email': sellerEmail,
      'seller_whatsapp': sellerWhatsapp,
      'seller_rating': sellerRating,
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
    String? sellerEmail,
    String? sellerWhatsapp,
    double? sellerRating,
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
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerWhatsapp: sellerWhatsapp ?? this.sellerWhatsapp,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}