import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/screen/order_success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _paymentMethod = 'PayNow';
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      
      if (appState.currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Create order
      final order = await cartProvider.checkout(
        appState.currentUser!.id,
        shippingInfo: {
          'name': _nameController.text,
          'address': _addressController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
        },
      );
      
      if (order == null) {
        throw Exception('Failed to create order');
      }
      
      // Format PayNow URL with order details
      final paynowUrl = Uri(
        scheme: 'https',
        host: 'paynow.co.zw',
        path: '/payment/process',
        queryParameters: {
          'amount': order.totalAmount.toString(),
          'reference': order.id,
          'email': _emailController.text,
          'name': _nameController.text,
          'phone': _phoneController.text,
        },
      );

      if (await canLaunchUrl(paynowUrl)) {
        await launchUrl(
          paynowUrl,
          mode: LaunchMode.externalApplication,
        );
        
        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(order: order),
            ),
          );
        }
      } else {
        throw Exception('Could not launch PayNow');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: cartProvider.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.cartShopping,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                    label: const Text('Continue Shopping'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order summary
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.receipt,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Order Summary',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...cartProvider.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.product.name}',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ),
                                      Text(
                                        '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                )),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Shipping information
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.truck,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Shipping Information',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Payment method
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.creditCard,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Method',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: [
                              RadioListTile(
                                title: Row(
                                  children: [
                                    const FaIcon(FontAwesomeIcons.moneyBill),
                                    const SizedBox(width: 8),
                                    const Text('PayNow'),
                                    const Spacer(),
                                    SvgPicture.asset(
                                      'assets/images/button_pay-now_large.svg',
                                      width: 80,
                                      height: 30,
                                      placeholderBuilder: (context) => const FaIcon(
                                        FontAwesomeIcons.moneyBill,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                                value: 'PayNow',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _paymentMethod = value.toString();
                                  });
                                },
                              ),
                              if (_paymentMethod == 'PayNow')
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const FaIcon(
                                            FontAwesomeIcons.shieldHalved,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Secure Payment',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PayNow is Zimbabwe\'s leading payment gateway',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Place order button
                        FilledButton.icon(
                          onPressed: _isProcessing ? null : _processPayment,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : SvgPicture.asset(
                                  'assets/images/button_pay-now_large.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                          label: Text(_isProcessing ? 'Processing...' : 'Pay with PayNow'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: const Color(0xFF00A0DC), // PayNow blue
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'You will be redirected to PayNow to complete your payment.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}