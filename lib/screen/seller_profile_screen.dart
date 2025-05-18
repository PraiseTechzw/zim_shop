import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/theme_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({Key? key}) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _updateUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = appState.currentUser;
      
      if (user != null) {
        final updatedUser = await _supabaseService.getCurrentUser();
        if (updatedUser != null) {
          appState.updateCurrentUser(updatedUser);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Store information updated'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error updating store: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _showStoreInformation() async {
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Store Name', user.businessName ?? 'Not set'),
              _buildInfoRow('Business Address', user.businessAddress ?? 'Not set'),
              _buildInfoRow('Phone Number', user.phoneNumber ?? 'Not set'),
              _buildInfoRow('WhatsApp', user.whatsappNumber ?? 'Not set'),
              _buildInfoRow('Seller Bio', user.sellerBio ?? 'Not set'),
              _buildInfoRow('Approval Status', user.isApproved ? 'Approved' : 'Pending'),
              _buildInfoRow('Seller Rating', user.sellerRating?.toString() ?? 'No ratings yet'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to edit store information screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit store information feature coming soon'),
                ),
              );
            },
            child: const Text('EDIT'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _showPaymentSettings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Settings'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodItem(
                'Mobile Money',
                'EcoCash, OneMoney, InnBucks',
                Icons.phone_android,
              ),
              _buildPaymentMethodItem(
                'Bank Transfer',
                'CBZ, Stanbic, FBC',
                Icons.account_balance,
              ),
              const SizedBox(height: 16),
              const Text(
                'Commission Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('5% per transaction'),
              const SizedBox(height: 16),
              const Text(
                'Payout Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Weekly payouts every Monday'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to edit payment settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit payment settings feature coming soon'),
                ),
              );
            },
            child: const Text('EDIT'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    // TODO: Implement notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon'),
      ),
    );
  }

  Future<void> _showSellerGuidelines() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seller Guidelines'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuidelineItem(
                'Product Listings',
                'Ensure all product descriptions are accurate and include clear images. Set competitive prices and maintain stock levels.',
              ),
              _buildGuidelineItem(
                'Order Processing',
                'Process and ship orders within 48 hours. Update order status promptly and communicate with buyers.',
              ),
              _buildGuidelineItem(
                'Customer Service',
                'Respond to customer inquiries within 24 hours. Handle returns and refunds professionally.',
              ),
              _buildGuidelineItem(
                'Payment & Commission',
                'We charge a 5% commission on all sales. Payouts are processed weekly.',
              ),
              _buildGuidelineItem(
                'Prohibited Items',
                'Do not list illegal, counterfeit, or restricted items. Violations may result in account suspension.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _showContactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'seller-support@zimmarket.com',
      queryParameters: {
        'subject': 'Seller Support Request',
        'body': 'Hello, I need help with my seller account...',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client'),
          ),
        );
      }
    }
  }

  Future<void> _showAbout() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ZimMarket'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ZimMarket is Zimbabwe\'s premier online marketplace, connecting buyers and sellers across the country.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To empower Zimbabwean businesses and consumers by providing a secure, efficient, and user-friendly platform for online commerce.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Version',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('1.0.0'),
              const SizedBox(height: 16),
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Email: seller-support@zimmarket.com'),
              const Text('Phone: +263 77 123 4567'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = appState.currentUser;
    
    return RefreshIndicator(
      onRefresh: _updateUserInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.store,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? 'Seller',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Seller',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  if (user?.isApproved == false)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Pending Approval',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Settings
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Store Information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showStoreInformation,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.payments),
                    title: const Text('Payment Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPaymentSettings,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showNotifications,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Help & Support
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Seller Guidelines'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showSellerGuidelines,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Contact Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showContactSupport,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About ZimMarket'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAbout,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Logout button
            FilledButton.icon(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App version
            Center(
              child: Text(
                'ZimMarket v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 