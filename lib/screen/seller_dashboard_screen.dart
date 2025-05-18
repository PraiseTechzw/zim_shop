import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/product.dart';
  import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/screen/add_product_screen.dart';
import 'package:zim_shop/screen/seller_orders_screen.dart';
import 'package:zim_shop/screen/seller_products_screen.dart';
import 'package:zim_shop/screen/seller_onboarding_screen.dart';

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

  void _navigateToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    ).then((_) => _loadData());
  }
  
  void _navigateToOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
    );
  }
  
  void _navigateToProducts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SellerProductsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional profile completion banner
            if (!appState.isSellerProfileComplete)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                            'Complete your profile',
                            style: TextStyle(
              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
            ),
          ),
                          const SizedBox(height: 4),
          Text(
                            'Add your business details to enhance your seller profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SellerOnboardingScreen(
                              user: appState.currentUser!,
                              onCompleted: () {
                                appState.refreshUser().then((_) {
                                  setState(() {});
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text('COMPLETE'),
                    ),
                  ],
                ),
              ),
            
            // Header section with welcome and profile info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              appState.currentUser?.username ?? 'Seller',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadData,
                        tooltip: 'Refresh data',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick status info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(
                          'Products', 
                          _sellerProducts.length.toString(),
                          Icons.inventory_2_outlined
                        ),
                        _buildQuickStat(
                          'Orders', 
                          _sellerOrders.length.toString(),
                          Icons.receipt_long_outlined
                        ),
                        _buildQuickStat(
                          'Revenue', 
                          '\$${_totalRevenue.toStringAsFixed(0)}',
                          Icons.attach_money
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Main stats cards with animation
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
                _buildAnimatedCard(
                  'Products',
                  _sellerProducts.length.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                  () => _navigateToProducts(),
                ),
                _buildAnimatedCard(
                  'Orders',
                  _sellerOrders.length.toString(),
                  Icons.receipt_long,
                  Colors.orange,
                  () => _navigateToOrders(),
                ),
                _buildAnimatedCard(
                  'Revenue',
                  '\$${_totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                  null,
                ),
                _buildAnimatedCard(
                  'Customers',
                  _uniqueCustomers.toString(),
                  Icons.people,
                  Colors.purple,
                  null,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
            // Recent orders with modern card design
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
                TextButton.icon(
                  onPressed: _navigateToOrders,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            _sellerOrders.isEmpty
                ? Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your orders will appear here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                    ),
                  ),
                )
              : Card(
                  margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sellerOrders.length > 5 ? 5 : _sellerOrders.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                        final order = _sellerOrders[index];
                      return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Order #${order.id.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                          onTap: _navigateToOrders,
                      );
                    },
                  ),
                ),
          
          const SizedBox(height: 24),
          
            // Quick actions with larger, more visible buttons
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
            
            // Action cards grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            children: [
                _buildActionCard(
                  'Add New Product',
                  Icons.add_circle_outline,
                  Colors.green,
                  _navigateToAddProduct,
                ),
                _buildActionCard(
                  'Manage Products',
                  Icons.inventory_2_outlined,
                  Colors.blue,
                  _navigateToProducts,
                ),
                _buildActionCard(
                  'View Orders',
                  Icons.receipt_long_outlined,
                  Colors.orange,
                  _navigateToOrders,
                ),
                _buildActionCard(
                  'Send Promotions',
                  Icons.campaign_outlined,
                  Colors.purple,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Promotions feature coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnimatedCard(
    String title, 
    String value, 
    IconData icon, 
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              if (onTap != null) ...[
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionCard(
    String title, 
    IconData icon, 
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}