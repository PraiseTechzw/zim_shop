import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/screen/buyer_main_screen.dart';
import 'package:zim_shop/services/payment_service.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Order order;
  final String paymentReference;
  final String instructions;
  final String pollUrl;

  const PaymentSuccessScreen({
    Key? key,
    required this.order,
    required this.paymentReference,
    required this.instructions,
    required this.pollUrl,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isPaid = false;
  bool _isChecking = false;
  String _status = 'Pending';
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    // Start checking payment status every 10 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkPaymentStatus();
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    if (_isPaid || !mounted) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final result = await _paymentService.checkPaymentStatus(widget.pollUrl);
      
      if (mounted) {
        setState(() {
          _isChecking = false;
          if (result['success']) {
            _status = result['status'] ?? 'Pending';
            _isPaid = result['paid'] ?? false;
            
            // If payment is confirmed, cancel the timer
            if (_isPaid) {
              _statusCheckTimer?.cancel();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment status icon
              Icon(
                _isPaid ? Icons.check_circle : Icons.access_time,
                size: 100,
                color: _isPaid 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              
              // Payment status
              Text(
                _isPaid ? 'Payment Confirmed!' : 'Payment Pending',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isPaid 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Payment reference
              Text(
                'Reference: ${widget.paymentReference}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              // Payment status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Status: $_status',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_isChecking)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Payment instructions card
              Card(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Instructions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      Text(
                        widget.instructions,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              if (_isPaid)
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const BuyerMainScreen()),
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Home'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    FilledButton.icon(
                      onPressed: _isChecking ? null : _checkPaymentStatus,
                      icon: _isChecking 
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ) 
                          : const Icon(Icons.refresh),
                      label: const Text('Check Payment Status'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const BuyerMainScreen()),
                      ),
                      child: const Text('Continue Shopping'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
} 