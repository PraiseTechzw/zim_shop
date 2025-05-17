import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/mock_data.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/widgets/order_card.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final sellerId = appState.currentUser?.id;
    
    // Get seller's products
    final sellerProducts = MockData.products
        .where((product) => product.sellerId == sellerId)
        .toList();
    
    // Get orders containing seller's products
    final sellerOrders = MockData.orders
        .where((order) => order.items.any((item) => 
            sellerProducts.any((product) => product.id == item.product.id)))
        .toList();
    
    if (sellerOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your orders will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sellerOrders.length,
      itemBuilder: (context, index) {
        final order = sellerOrders[index];
        return OrderCard(
          order: order,
          isSellerView: true,
        );
      },
    );
  }
}