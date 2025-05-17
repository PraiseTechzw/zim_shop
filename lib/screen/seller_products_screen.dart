  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:zim_shop/providers/app_state.dart';
  import 'package:zim_shop/mock_data.dart';
  import 'package:zim_shop/widgets/product_list_item.dart';
  import 'package:zim_shop/screen/add_product_screen.dart'; 

  class SellerProductsScreen extends StatelessWidget {
    const SellerProductsScreen({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      final appState = Provider.of<AppState>(context);
      final sellerId = appState.currentUser?.id;
      
      // Get seller's products
      final sellerProducts = MockData.products
          .where((product) => product.sellerId == sellerId)
          .toList();
      
      return Scaffold(
        body: sellerProducts.isEmpty
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
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  // Simulate refresh
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sellerProducts.length + 1, // +1 for the header
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
                                  );
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
                    
                    final product = sellerProducts[index - 1];
                    return ProductListItem(
                      product: product,
                      onEdit: () {
                        // Navigate to edit product screen
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
                                  // Delete product
                                  MockData.products.removeWhere(
                                    (p) => p.id == product.id,
                                  );
                                  Navigator.of(context).pop();
                                  // Force rebuild
                                  (context as Element).markNeedsBuild();
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