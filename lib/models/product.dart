class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String location;
  final String category;
  final String sellerId;
  final String sellerName;
  final String? sellerEmail;
  final String? sellerWhatsapp;
  final double? sellerRating;
  final bool? sellerIsVerified;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    this.sellerEmail,
    this.sellerWhatsapp,
    this.sellerRating,
    this.sellerIsVerified,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String,
      sellerEmail: json['seller_email'] as String?,
      sellerWhatsapp: json['seller_whatsapp'] as String?,
      sellerRating: json['seller_rating'] != null ? (json['seller_rating'] as num).toDouble() : null,
      sellerIsVerified: json['seller_is_verified'] as bool?,
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
      'seller_email': sellerEmail,
      'seller_whatsapp': sellerWhatsapp,
      'seller_rating': sellerRating,
      'seller_is_verified': sellerIsVerified,
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
    );
  }
}