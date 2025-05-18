class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String location;
  final String sellerId;
  final String sellerName;
  final String? sellerEmail;
  final double? sellerRating;
  final bool? sellerIsVerified;
  final String? sellerWhatsapp;
  
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.sellerId,
    required this.sellerName,
    this.sellerEmail,
    this.sellerRating,
    this.sellerIsVerified,
    this.sellerWhatsapp,
  });
  
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? location,
    String? sellerId,
    String? sellerName,
    String? sellerEmail,
    double? sellerRating,
    bool? sellerIsVerified,
    String? sellerWhatsapp,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      location: location ?? this.location,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      sellerWhatsapp: sellerWhatsapp ?? this.sellerWhatsapp,
    );
  }
}