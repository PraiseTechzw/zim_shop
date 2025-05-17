import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
  import 'package:zim_shop/mock_data.dart';
  import 'package:zim_shop/providers/app_state.dart';
  import 'package:zim_shop/widgets/dashboard_card.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final sellerId = appState.currentUser?.id;
    
    // Get seller's products
    final sellerProducts = MockData.products
        .where((product) => product.sellerId == sellerId)
        .toList();
    
    // Get seller's orders
    final sellerOrders = MockData.orders
        .where((order) => order.items.any((item) => 
            sellerProducts.any((product) => product.id == item.product.id)))
        .toList();
    
    // Calculate total revenue
    double totalRevenue = 0;
    for (final order in sellerOrders) {
      for (final item in order.items) {
        if (sellerProducts.any((product) => product.id == item.product.id)) {
          totalRevenue += item.product.price * item.quantity;
        }
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back, ${appState.currentUser?.username ?? 'Seller'}!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              DashboardCard(
                title: 'Products',
                value: sellerProducts.length.toString(),
                icon: Icons.inventory_2,
                color: Colors.blue,
              ),
              DashboardCard(
                title: 'Orders',
                value: sellerOrders.length.toString(),
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
              DashboardCard(
                title: 'Revenue',
                value: '\$${totalRevenue.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              DashboardCard(
                title: 'Customers',
                value: sellerOrders
                    .map((order) => order.userId)
                    .toSet()
                    .length
                    .toString(),
                icon: Icons.people,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent orders
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          sellerOrders.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('No orders yet'),
                    ),
                  ),
                )
              : Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sellerOrders.length > 5 ? 5 : sellerOrders.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = sellerOrders[index];
                      return ListTile(
                        title: Text('Order #${order.id}'),
                        subtitle: Text(
                          '${order.date.day}/${order.date.month}/${order.date.year} - ${order.status}',
                        ),
                        trailing: Text(
                          '\$${order.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onTap: () {
                          // View order details
                        },
                      );
                    },
                  ),
                ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // Navigate to add product screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to orders screen
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Orders'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}