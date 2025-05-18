import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/widgets/dashboard_card.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _sellerProducts = [];
  List<Order> _sellerOrders = [];
  double _totalRevenue = 0;
  int _uniqueCustomers = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final sellerId = appState.currentUser?.id;
    
    if (sellerId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Load all products
      final allProducts = await _supabaseService.getProducts();
      
      // Filter seller's products
      final sellerProducts = allProducts.where((p) => p.sellerId == sellerId).toList();
      
      // Get seller's orders
      final allOrders = await _supabaseService.getSellerOrders(sellerId);
      
      // Calculate total revenue
      double totalRevenue = 0;
      final customerIds = <String>{};
      
      for (final order in allOrders) {
        for (final item in order.items) {
          if (sellerProducts.any((p) => p.id == item.product.id)) {
            totalRevenue += item.product.price * item.quantity;
          }
        }
        customerIds.add(order.userId);
      }
      
      if (mounted) {
        setState(() {
          _sellerProducts = sellerProducts;
          _sellerOrders = allOrders;
          _totalRevenue = totalRevenue;
          _uniqueCustomers = customerIds.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final appState = Provider.of<AppState>(context);
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
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
                  value: _sellerProducts.length.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
                DashboardCard(
                  title: 'Orders',
                  value: _sellerOrders.length.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
                DashboardCard(
                  title: 'Revenue',
                  value: '\$${_totalRevenue.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                DashboardCard(
                  title: 'Customers',
                  value: _uniqueCustomers.toString(),
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
            _sellerOrders.isEmpty
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
                      itemCount: _sellerOrders.length > 5 ? 5 : _sellerOrders.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final order = _sellerOrders[index];
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
      ),
    );
  }
}