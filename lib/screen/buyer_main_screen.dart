import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/screen/buyer_home_screen.dart';
import 'package:zim_shop/screen/cart_screen.dart';
import 'package:zim_shop/screen/orders_screen.dart';
import 'package:zim_shop/screen/profile_screen.dart';

import 'package:zim_shop/widgets/theme_toggle_button.dart';

class BuyerMainScreen extends StatefulWidget {
  const BuyerMainScreen({Key? key}) : super(key: key);

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const BuyerHomeScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZimMarket'),
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
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart'),
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
            if (index == 1) // Cart item with badge
              Badge(
                label: Consumer<CartProvider>(
                  builder: (context, cart, _) => Text(
                    cart.itemCount?.toString() ?? '0',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                isLabelVisible: true,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: color,
                ),
              )
            else
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