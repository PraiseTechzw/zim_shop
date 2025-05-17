import 'package:flutter/material.dart';
  import 'package:zim_shop/mock_data.dart';
import 'package:zim_shop/screen/product_details_screen.dart';
  import 'package:zim_shop/widgets/category_card.dart';
  import 'package:zim_shop/widgets/product_card.dart';

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          
          // Categories
          Text(
            'Markets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.locations.length,
              itemBuilder: (context, index) {
                return CategoryCard(
                  title: MockData.locations[index],
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: MockData.products.length,
            itemBuilder: (context, index) {
              final product = MockData.products[index];
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
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.categories.length,
              itemBuilder: (context, index) {
                return CategoryCard(
                  title: MockData.categories[index],
                  onTap: () {
                    // Filter products by category
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}