import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/theme_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                    Text('Profile information updated'),
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
                  child: Text('Error updating profile: ${e.toString()}'),
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

  Future<void> _showAccountInformation() async {
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Username', user.username),
              _buildInfoRow('Email', user.email),
              _buildInfoRow('Role', user.role.toString().split('.').last.toUpperCase()),
              if (user.role == UserRole.seller) ...[
                _buildInfoRow('Business Name', user.businessName ?? 'Not set'),
                _buildInfoRow('Business Address', user.businessAddress ?? 'Not set'),
                _buildInfoRow('Phone Number', user.phoneNumber ?? 'Not set'),
                _buildInfoRow('WhatsApp', user.whatsappNumber ?? 'Not set'),
                _buildInfoRow('Seller Bio', user.sellerBio ?? 'Not set'),
                _buildInfoRow('Approval Status', user.isApproved ? 'Approved' : 'Pending'),
              ],
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

  Future<void> _showDeliveryAddresses() async {
    // TODO: Implement delivery addresses screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery addresses feature coming soon'),
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

  Future<void> _showFAQs() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                'How do I place an order?',
                'Browse products, add them to your cart, and proceed to checkout. Follow the payment instructions to complete your order.',
              ),
              _buildFAQItem(
                'How do I become a seller?',
                'Register as a seller, complete your profile with business details, and wait for approval from our team.',
              ),
              _buildFAQItem(
                'What payment methods are accepted?',
                'We currently accept mobile money and bank transfers. More payment options coming soon.',
              ),
              _buildFAQItem(
                'How do I track my order?',
                'Go to the Orders section in your profile to view order status and tracking information.',
              ),
              _buildFAQItem(
                'What is the return policy?',
                'Items can be returned within 7 days of delivery if they are damaged or not as described.',
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

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(answer),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _showContactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@zimmarket.com',
      queryParameters: {
        'subject': 'Support Request',
        'body': 'Hello, I need help with...',
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
              const Text('Email: support@zimmarket.com'),
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
                        child: Icon(
                          user?.role == UserRole.seller ? Icons.store : Icons.person,
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
                    user?.username ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.role.toString().split('.').last.toUpperCase() ?? 'USER',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  if (user?.role == UserRole.seller && user?.isApproved == false)
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
                    leading: const Icon(Icons.person),
                    title: const Text('Account Information'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showAccountInformation,
                  ),
                  const Divider(height: 1),
                  if (user?.role == UserRole.buyer)
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Delivery Addresses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showDeliveryAddresses,
                    ),
                  if (user?.role == UserRole.buyer)
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
                    title: const Text('FAQs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showFAQs,
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