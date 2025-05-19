import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/screen/order_success_screen.dart';
import 'package:zim_shop/services/payment_service.dart' as payment;

class PayPalPaymentScreen extends StatefulWidget {
  final Order order;
  final String paymentUrl;
  final String returnUrl;
  final String cancelUrl;

  const PayPalPaymentScreen({
    Key? key,
    required this.order,
    required this.paymentUrl,
    required this.returnUrl,
    required this.cancelUrl,
  }) : super(key: key);

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  bool isCapturing = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
              errorMessage = null;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              isLoading = false;
            });
            
            // Handle return URL
            if (url.startsWith(widget.returnUrl)) {
              // Extract order ID from URL
              final uri = Uri.parse(url);
              final orderId = uri.queryParameters['token'];
              
              if (orderId != null) {
                setState(() {
                  isCapturing = true;
                });

                try {
                  // Capture the payment
                  final paymentService = Provider.of<payment.PaymentService>(context, listen: false);
                  final result = await paymentService.capturePayPalPayment(
                    orderId: orderId,
                  );

                  if (!mounted) return;

                  if (result.isSuccess) {
                    // Navigate to success screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => OrderSuccessScreen(order: widget.order),
                      ),
                    );
                  } else {
                    setState(() {
                      hasError = true;
                      errorMessage = result.error ?? 'Failed to capture payment';
                    });
                  }
                } catch (e) {
                  if (!mounted) return;
                  setState(() {
                    hasError = true;
                    errorMessage = e.toString();
                  });
                } finally {
                  if (mounted) {
                    setState(() {
                      isCapturing = false;
                    });
                  }
                }
              }
            }
            // Handle cancel URL
            else if (url.startsWith(widget.cancelUrl)) {
              Navigator.of(context).pop();
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              hasError = true;
              errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading || isCapturing)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      isCapturing ? 'Processing payment...' : 'Loading payment page...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          if (hasError)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error processing payment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage ?? 'Unknown error',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          hasError = false;
                          errorMessage = null;
                        });
                        controller.reload();
                      },
                      icon: const FaIcon(FontAwesomeIcons.rotate),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 