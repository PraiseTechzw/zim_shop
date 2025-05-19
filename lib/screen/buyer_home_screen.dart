import 'package:flutter/material.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/screen/product_details_screen.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/widgets/category_card.dart';
import 'package:zim_shop/widgets/product_card.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _products = [];
  List<String> _categories = [];
  List<String> _locations = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load products
      final products = await _supabaseService.getProducts();
      
      // Extract unique categories and locations
      final categories = <String>{};
      final locations = <String>{};
      
      for (final product in products) {
        if (product.category?.isNotEmpty ?? false) {
          categories.add(product.category!);
        }
        if (product.location?.isNotEmpty ?? false) {
          locations.add(product.location!);
        }
      }
      
      if (mounted) {
        setState(() {
          _products = products;
          _categories = categories.toList()..sort();
          _locations = locations.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Locations
            Text(
              'Markets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: _locations.isEmpty
                ? Center(child: Text('No locations available'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        title: _locations[index],
                        onTap: () {
                          // Filter products by location
                        },
                      );
                    },
                  ),
            ),
            
            const SizedBox(height: 24),
            
            // Featured products
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all products
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _products.isEmpty
              ? Center(child: Text('No products available'))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                ),
            
            const SizedBox(height: 24),
            
            // Categories
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: _categories.isEmpty
                ? Center(child: Text('No categories available'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        title: _categories[index],
                        onTap: () {
                          // Filter products by category
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}