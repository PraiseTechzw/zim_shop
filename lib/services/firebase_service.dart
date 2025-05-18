import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/cart_item.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all products
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: int.parse(doc.id),
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
          location: data['location'] ?? '',
          sellerId: int.parse(data['sellerId'] ?? '0'),
          sellerName: data['sellerName'] ?? '',
        );
      }).toList();
    });
  }

  // Get products by seller
  Stream<List<Product>> getSellerProducts(int sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId.toString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: int.parse(doc.id),
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
          location: data['location'] ?? '',
          sellerId: int.parse(data['sellerId'] ?? '0'),
          sellerName: data['sellerName'] ?? '',
        );
      }).toList();
    });
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: int.parse(doc.id),
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
          location: data['location'] ?? '',
          sellerId: int.parse(data['sellerId'] ?? '0'),
          sellerName: data['sellerName'] ?? '',
        );
      }).toList();
    });
  }

  // Add new product
  Future<Product> addProduct(Product product, File imageFile) async {
    try {
      // Upload image to Firebase Storage
      final storageRef = _storage.ref().child('products/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await storageRef.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Create product document in Firestore
      final productData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'imageUrl': imageUrl,
        'category': product.category,
        'location': product.location,
        'sellerId': product.sellerId.toString(),
        'sellerName': product.sellerName,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('products').add(productData);
      
      // Return the created product with the new ID and image URL
      return Product(
        id: int.parse(docRef.id),
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: imageUrl,
        category: product.category,
        location: product.location,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
      );
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product
  Future<void> updateProduct(Product product, {File? imageFile}) async {
    try {
      final productData = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'category': product.category,
        'location': product.location,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If a new image is provided, upload it and update the URL
      if (imageFile != null) {
        final storageRef = _storage.ref().child('products/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = await storageRef.putFile(imageFile);
        final imageUrl = await uploadTask.ref.getDownloadURL();
        productData['imageUrl'] = imageUrl;
      }

      // Update the product in Firestore
      await _firestore.collection('products').doc(product.id.toString()).update(productData);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(int productId) async {
    try {
      await _firestore.collection('products').doc(productId.toString()).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Create order
  Future<String> createOrder(List<CartItem> items, double totalAmount, int userId) async {
    try {
      final orderData = {
        'userId': userId.toString(),
        'items': items.map((item) => {
          'productId': item.product.id.toString(),
          'productName': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'sellerId': item.product.sellerId.toString(),
        }).toList(),
        'totalAmount': totalAmount,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user orders
  Stream<List<Order>> getUserOrders(int userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final itemsList = (data['items'] as List<dynamic>).map((item) {
          return CartItem(
            product: Product(
              id: int.parse(item['productId']),
              name: item['productName'],
              description: '',
              price: (item['price'] ?? 0).toDouble(),
              imageUrl: '',
              category: '',
              location: '',
              sellerId: int.parse(item['sellerId']),
              sellerName: '',
            ),
            quantity: item['quantity'],
          );
        }).toList();

        return Order(
          id: int.parse(doc.id),
          userId: int.parse(data['userId']),
          items: itemsList,
          totalAmount: itemsList.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity)),
          date: (data['createdAt'] as Timestamp).toDate(),
          status: data['status'] ?? 'Processing',
        );
      }).toList();
    });
  }

  // Get seller orders
  Stream<List<Order>> getSellerOrders(int sellerId) {
    return _firestore
        .collection('orders')
        .where('items', arrayContains: {'sellerId': sellerId.toString()})
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final itemsList = (data['items'] as List<dynamic>)
            .where((item) => item['sellerId'] == sellerId.toString())
            .map((item) {
          return CartItem(
            product: Product(
              id: int.parse(item['productId']),
              name: item['productName'],
              description: '',
              price: (item['price'] ?? 0).toDouble(),
              imageUrl: '',
              category: '',
              location: '',
              sellerId: sellerId,
              sellerName: '',
            ),
            quantity: item['quantity'],
          );
        }).toList();

        return Order(
          id: int.parse(doc.id),
          userId: int.parse(data['userId']),
          items: itemsList,
          totalAmount: itemsList.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity)),
          date: (data['createdAt'] as Timestamp).toDate(),
          status: data['status'] ?? 'Processing',
        );
      }).toList();
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get all categories from Firestore
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // Get all locations from Firestore
  Future<List<String>> getLocations() async {
    try {
      final snapshot = await _firestore.collection('locations').get();
      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }
} 