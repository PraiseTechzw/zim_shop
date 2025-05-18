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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}