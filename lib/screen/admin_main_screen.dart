import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/screen/login_screen.dart';
import 'package:zim_shop/widgets/theme_toggle_button.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    
    // Create tabs/sections for the admin interface
    final List<Widget> adminTabs = [
      _buildDashboardTab(),
      _buildUsersTab(appState),
      _buildProductsTab(),
      _buildSettingsTab(context, appState),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZimMarket Admin'),
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
      body: adminTabs[_selectedIndex],
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatCard('Total Users', '14', Icons.people, Colors.blue),
            const SizedBox(height: 16),
            _buildStatCard('Total Products', '45', Icons.inventory_2, Colors.green),
            const SizedBox(height: 16),
            _buildStatCard('Pending Approvals', '3', Icons.pending_actions, Colors.orange),
            const SizedBox(height: 16),
            _buildStatCard('Total Orders', '78', Icons.shopping_cart, Colors.purple),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUsersTab(AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appState.isLoggedIn ? appState.users.length : 0,
      itemBuilder: (context, index) {
        final user = appState.users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getUserRoleColor(user.role),
              child: Icon(
                _getUserRoleIcon(user.role),
                color: Colors.white,
              ),
            ),
            title: Text('${user.username}'),
            subtitle: Text(_getUserRoleText(user.role)),
            trailing: user.role == UserRole.seller
                ? Switch(
                    value: user.isApproved,
                    onChanged: (value) {
                      // Update seller approval status
                      appState.approveUser(user.id, value);
                    },
                  )
                : null,
          ),
        );
      },
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
    // Placeholder for products management
    return const Center(
      child: Text('Products Management (Coming Soon)'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon')),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Text('English'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon')),
              );
            },
          ),
        ),
        Card(
          child: Consumer<AppState>(
            builder: (context, appState, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.verified_user),
                title: const Text('Auto-approve Sellers'),
                value: false, // Connect to a real setting in AppState
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Setting will be saved in the future')),
                  );
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
              );
            },
          ),
        ),
      ],
    );
  }
} 