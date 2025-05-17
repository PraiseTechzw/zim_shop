import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zim_shop/mock_data.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userOrders = MockData.orders
        .where((order) => order.userId == appState.currentUser?.id)
        .toList();
    
    if (userOrders.isEmpty) {
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
              'Your order history will appear here',
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
      itemCount: userOrders.length,
      itemBuilder: (context, index) {
        final order = userOrders[index];
        return OrderCard(order: order);
      },
    );
  }
}