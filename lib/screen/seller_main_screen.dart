import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/screen/seller_profile_screen.dart';
import 'package:zim_shop/widgets/theme_toggle_button.dart';
import 'package:zim_shop/screen/seller_dashboard_screen.dart';
import 'package:zim_shop/screen/seller_products_screen.dart';
import 'package:zim_shop/screen/seller_orders_screen.dart';

class SellerMainScreen extends StatefulWidget {
  const SellerMainScreen({Key? key}) : super(key: key);

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
      const SellerDashboardScreen(),
    const SellerProductsScreen(),
    const SellerOrdersScreen(),
    const SellerProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    
    // Check if seller is approved
    if (appState.currentUser?.role == UserRole.seller && 
        !appState.currentUser!.isApproved) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ZimMarket Seller'),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pending_actions,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Account Pending Approval',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your seller account is currently under review. You will be notified once your account is approved.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    appState.logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZimMarket Seller'),
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
                _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
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
}