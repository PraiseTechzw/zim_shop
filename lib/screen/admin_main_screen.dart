import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/widgets/theme_toggle_button.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/models/user.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalProducts = 0;
  int _pendingApprovals = 0;
  int _totalOrders = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _recentUsers = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _supabaseService.getAllUsers();
      final pendingSellers = users.where((u) => u.role == UserRole.seller && !u.isApproved).length;
      final products = await _supabaseService.getProducts();
      final orders = await _supabaseService.getOrders();
      
      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _totalProducts = products.length;
          _pendingApprovals = pendingSellers;
          _totalOrders = orders.length;
          _recentOrders = orders.take(5).map((o) => {
            'id': o.id,
            'amount': o.totalAmount,
            'status': o.status,
            'date': o.date,
          }).toList();
          _recentUsers = users.take(5).map((u) => {
            'id': u.id,
            'username': u.username,
            'role': u.role,
            'isApproved': u.isApproved,
          }).toList();
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
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    
    final List<Widget> adminTabs = [
      _buildDashboardTab(),
      _buildUsersTab(appState),
      _buildProductsTab(),
      _buildSettingsTab(context, appState),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.store, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'ZimMarket Admin',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              appState.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: adminTabs[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.people_outline, Icons.people, 'Users'),
                _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final color = isSelected 
        ? theme.colorScheme.primary 
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDashboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
            _buildUserDistributionChart(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                      'Welcome back,',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      appState.currentUser?.username ?? 'Admin',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Here\'s what\'s happening with your marketplace today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
        ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final childAspectRatio = constraints.maxWidth > 600 ? 1.8 : 1.5;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Total Users',
              _totalUsers.toString(),
              Icons.people,
              Colors.blue,
              'Active marketplace users',
            ),
            _buildStatCard(
              'Total Products',
              _totalProducts.toString(),
              Icons.inventory_2,
              Colors.green,
              'Listed products',
            ),
            _buildStatCard(
              'Pending Approvals',
              _pendingApprovals.toString(),
              Icons.pending_actions,
              Colors.orange,
              'Seller applications',
            ),
            _buildStatCard(
              'Total Orders',
              _totalOrders.toString(),
              Icons.shopping_cart,
              Colors.purple,
              'Completed transactions',
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    size: 20,
              ),
            ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                        style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentActivitySection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          'Recent Orders',
          Icons.shopping_cart,
          Colors.purple,
          _recentOrders.map((order) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.1),
              child: Icon(
                Icons.shopping_cart,
                color: Colors.purple,
                size: 20,
              ),
            ),
            title: Text(
              'Order #${order['id'].toString().substring(0, 8)}',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              '${order['status']} - \$${order['amount'].toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              _formatDate(order['date']),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          'Recent Users',
          Icons.people,
          Colors.blue,
          _recentUsers.map((user) => ListTile(
            leading: CircleAvatar(
              backgroundColor: _getUserRoleColor(user['role']).withOpacity(0.1),
              child: Icon(
                _getUserRoleIcon(user['role']),
                color: _getUserRoleColor(user['role']),
                size: 20,
              ),
            ),
            title: Text(
              user['username'],
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              _getUserRoleText(user['role']),
              style: theme.textTheme.bodySmall,
            ),
            trailing: user['role'] == UserRole.seller
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user['isApproved']
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user['isApproved'] ? 'Approved' : 'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: user['isApproved']
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          )).toList(),
        ),
      ],
    );
  }
  
  Widget _buildActivityCard(String title, IconData icon, Color color, List<Widget> items) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }
  
  Widget _buildUserDistributionChart() {
    final theme = Theme.of(context);
    final buyerCount = _recentUsers.where((u) => u['role'] == UserRole.buyer).length;
    final sellerCount = _recentUsers.where((u) => u['role'] == UserRole.seller).length;
    final adminCount = _recentUsers.where((u) => u['role'] == UserRole.admin).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Distribution',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Row(
                children: [
                  Expanded(
                    flex: isWide ? 2 : 1,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: buyerCount.toDouble(),
                              title: 'Buyers',
                              color: Colors.blue,
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            PieChartSectionData(
                              value: sellerCount.toDouble(),
                              title: 'Sellers',
                              color: Colors.green,
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            PieChartSectionData(
                              value: adminCount.toDouble(),
                              title: 'Admins',
                              color: Colors.purple,
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 16),
                  if (isWide)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Buyers', Colors.blue, buyerCount),
                          const SizedBox(height: 16),
                          _buildLegendItem('Sellers', Colors.green, sellerCount),
                          const SizedBox(height: 16),
                          _buildLegendItem('Admins', Colors.purple, adminCount),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, int count) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count users',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Widget _buildUsersTab(AppState appState) {
    if (!appState.isLoggedIn) {
      return const Center(child: Text('Please login to view users'));
    }
    
    if (appState.users.isEmpty) {
      Future.microtask(() => appState.getUsers());
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await appState.getUsers();
      },
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appState.users.length,
      itemBuilder: (context, index) {
        final user = appState.users[index];
          return _buildUserCard(user, appState);
        },
      ),
    );
  }
  
  Widget _buildUserCard(User user, AppState appState) {
    final theme = Theme.of(context);
    final isSeller = user.role == UserRole.seller;
    
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getUserRoleColor(user.role).withOpacity(0.1),
              child: Icon(
                _getUserRoleIcon(user.role),
                    color: _getUserRoleColor(user.role),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
              ),
            ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSeller)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.isApproved
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isApproved ? 'Approved' : 'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: user.isApproved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        _getUserRoleText(user.role),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.phoneNumber != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          user.phoneNumber!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (isSeller) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showSellerDetailsDialog(user);
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final success = await _handleSellerApproval(user, appState);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                user.isApproved
                                    ? 'Seller has been approved'
                                    : 'Seller approval has been revoked',
                              ),
                              backgroundColor: user.isApproved
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        user.isApproved
                            ? Icons.block
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        user.isApproved ? 'Revoke Approval' : 'Approve Seller',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: user.isApproved
                            ? Colors.red
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<bool> _handleSellerApproval(User user, AppState appState) async {
    try {
      final newApprovalStatus = !user.isApproved; // Store the new status
      final success = await appState.approveUser(user.id.toString(), newApprovalStatus);
      if (success) {
        await appState.getUsers(); // Refresh the users list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newApprovalStatus
                    ? 'Seller has been approved'
                    : 'Seller approval has been revoked',
              ),
              backgroundColor: newApprovalStatus ? Colors.green : Colors.orange,
            ),
          );
        }
      }
      return success;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating seller status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
  
  Future<void> _showSellerDetailsDialog(User user) {
    final theme = Theme.of(context);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getUserRoleColor(user.role).withOpacity(0.1),
              child: Icon(
                _getUserRoleIcon(user.role),
                color: _getUserRoleColor(user.role),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Seller Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Username', user.username),
              _buildDetailItem('Email', user.email),
              if (user.phoneNumber != null)
                _buildDetailItem('Phone', user.phoneNumber!),
              if (user.whatsappNumber != null)
                _buildDetailItem('WhatsApp', user.whatsappNumber!),
              if (user.businessName != null)
                _buildDetailItem('Business Name', user.businessName!),
              if (user.businessAddress != null)
                _buildDetailItem('Business Address', user.businessAddress!),
              if (user.sellerBio != null)
                _buildDetailItem('Bio', user.sellerBio!),
              if (user.sellerRating != null)
                _buildDetailItem(
                  'Rating',
                  '${user.sellerRating!.toStringAsFixed(1)}/5.0',
                ),
              _buildDetailItem(
                'Status',
                user.isApproved ? 'Approved' : 'Pending Approval',
                valueColor: user.isApproved ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getUserRoleColor(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return Colors.blue;
      case UserRole.seller:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
    }
  }
  
  IconData _getUserRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return Icons.person;
      case UserRole.seller:
        return Icons.store;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }
  
  String _getUserRoleText(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.admin:
        return 'Administrator';
    }
  }
  
  Widget _buildProductsTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!appState.isLoggedIn) {
          return const Center(child: Text('Please login to view products'));
        }
        
        return FutureBuilder<List<Product>>(
          future: _supabaseService.getProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading products: ${snapshot.error}'),
              );
            }
            
            final products = snapshot.data ?? [];
            
            if (products.isEmpty) {
    return const Center(
                child: Text('No products found'),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product.imageUrl?.startsWith('http') ?? false
                        ? Image.network(
                            product.imageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seller: ${product.sellerName ?? 'Unknown'}'),
                        Text('Category: ${product.category ?? 'Uncategorized'}'),
                        Text('Location: ${product.location ?? 'Not specified'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () {
                                // Show edit dialog
                                _showEditProductDialog(context, product);
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                // Show delete confirmation
                                _showDeleteProductConfirmation(context, product);
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Future<void> _showEditProductDialog(BuildContext context, Product product) async {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final categoryController = TextEditingController(text: product.category);
    final locationController = TextEditingController(text: product.location);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final updatedProduct = product.copyWith(
                  name: nameController.text,
                  description: descriptionController.text,
                  price: double.tryParse(priceController.text) ?? product.price,
                  category: categoryController.text,
                  location: locationController.text,
                );
                
                final success = await _supabaseService.updateProduct(updatedProduct);
                
                if (success && mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product updated successfully')),
                  );
                  setState(() {}); // Refresh the list
                } else {
                  throw Exception('Failed to update product');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating product: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showDeleteProductConfirmation(BuildContext context, Product product) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final success = await _supabaseService.deleteProduct(product.id);
                
                if (success && mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                  setState(() {}); // Refresh the list
                } else {
                  throw Exception('Failed to delete product');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTab(BuildContext context, AppState appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSecuritySettings(context);
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Text('English'),
            onTap: () {
              _showLanguageSettings(context);
            },
          ),
        ),
        Card(
          child: Consumer<AppState>(
            builder: (context, appState, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.verified_user),
                title: const Text('Auto-approve Sellers'),
                subtitle: const Text('Automatically approve new seller registrations'),
                value: appState.autoApproveSellers,
                onChanged: (value) async {
                  try {
                    await _supabaseService.updateAdminSettings({
                      'auto_approve_sellers': value,
                    });
                    if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating settings: $e')),
                  );
                    }
                  }
                },
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ZimMarket Admin',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.store, size: 48),
                applicationLegalese: '© 2023 ZimMarket Inc.',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'ZimMarket Admin is a powerful platform for managing your online marketplace. '
                    'With features like user management, product oversight, and order tracking, '
                    'you have complete control over your marketplace operations.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'For support or inquiries, please contact:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Email: support@zimmarket.com'),
                  const Text('Phone: +263 123 456 789'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  Future<void> _showSecuritySettings(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Admin Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              try {
                final success = await _supabaseService.updateAdminPassword(
                  passwordController.text,
                );
                
                if (success && mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully')),
                  );
                } else {
                  throw Exception('Failed to update password');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating password: $e')),
                  );
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showLanguageSettings(BuildContext context) async {
    final languages = ['English', 'Shona', 'Ndebele'];
    String selectedLanguage = 'English';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select your preferred language',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...languages.map((language) => RadioListTile(
              title: Text(language),
              value: language,
              groupValue: selectedLanguage,
              onChanged: (value) {
                selectedLanguage = value.toString();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $selectedLanguage')),
                );
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 