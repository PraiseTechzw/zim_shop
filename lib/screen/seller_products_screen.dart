  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
import 'package:zim_shop/models/product.dart';
  import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/supabase_service.dart';
  import 'package:zim_shop/widgets/product_list_item.dart';
  import 'package:zim_shop/screen/add_product_screen.dart'; 

class SellerProductsScreen extends StatefulWidget {
    const SellerProductsScreen({Key? key}) : super(key: key);

    @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _sellerProducts = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    final appState = Provider.of<AppState>(context, listen: false);
      final sellerId = appState.currentUser?.id;
      
    if (sellerId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final allProducts = await _supabaseService.getProducts();
      final sellerProducts = allProducts.where((p) => p.sellerId == sellerId).toList();
      
      if (mounted) {
        setState(() {
          _sellerProducts = sellerProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading seller products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _deleteProduct(String productId) async {
    try {
      setState(() => _isLoading = true);
      
      final success = await _supabaseService.deleteProduct(productId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        _loadProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
      
      return Scaffold(
      body: _sellerProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Products Yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first product to start selling',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddProductScreen(),
                          ),
                      ).then((_) => _loadProducts());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
              onRefresh: _loadProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                itemCount: _sellerProducts.length + 1, // +1 for the header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Products',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddProductScreen(),
                                    ),
                                ).then((_) => _loadProducts());
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    
                  final product = _sellerProducts[index - 1];
                    return ProductListItem(
                      product: product,
                      onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(product: product),
                        ),
                      ).then((_) => _loadProducts());
                      },
                      onDelete: () {
                        // Show delete confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: Text(
                              'Are you sure you want to delete "${product.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                _deleteProduct(product.id);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      );
    }
  }