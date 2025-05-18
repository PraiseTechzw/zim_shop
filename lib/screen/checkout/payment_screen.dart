import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/payment_service.dart';
import 'package:zim_shop/screen/buyer_main_screen.dart';
import 'package:zim_shop/screen/checkout/payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;

  const PaymentScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPaymentMethod = 'ecocash';

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      
      // Use the payment service to create a payment
      final result = await _paymentService.createPayment(widget.order, email);
      
      if (mounted) {
        if (result['success']) {
          // Payment initiated successfully
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                order: widget.order,
                paymentReference: result['reference'],
                instructions: result['instructions'],
                pollUrl: result['pollUrl'],
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['error'] ?? 'Payment processing failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Pre-fill email if user is logged in
    if (_emailController.text.isEmpty && appState.currentUser != null) {
      _emailController.text = appState.currentUser!.email;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary
              Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      ...widget.order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name} x ${item.quantity}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${widget.order.totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Error message if any
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Payment method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              // Radio group for payment methods
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset(
                            'assets/images/ecocash_logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet),
                          ),
                          const SizedBox(width: 8),
                          const Text('EcoCash'),
                        ],
                      ),
                      value: 'ecocash',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset(
                            'assets/images/onemoney_logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet),
                          ),
                          const SizedBox(width: 8),
                          const Text('OneMoney'),
                        ],
                      ),
                      value: 'onemoney',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset(
                            'assets/images/telecash_logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet),
                          ),
                          const SizedBox(width: 8),
                          const Text('Telecash'),
                        ],
                      ),
                      value: 'telecash',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // Payment information
              const SizedBox(height: 16),
              Text(
                'Payment Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              // Phone number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '07XXXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!value.startsWith('07') || value.length != 10) {
                    return 'Please enter a valid phone number (format: 07XXXXXXXX)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
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
              const SizedBox(height: 24),
              
              // Pay button
              FilledButton.icon(
                onPressed: _isLoading ? null : _processPayment,
                icon: _isLoading 
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ) 
                    : const Icon(Icons.payment),
                label: Text('Pay \$${widget.order.totalAmount.toStringAsFixed(2)}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const BuyerMainScreen()),
                ),
                child: const Text('Cancel Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 