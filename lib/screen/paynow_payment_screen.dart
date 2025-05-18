import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/screen/order_success_screen.dart';

class PayNowPaymentScreen extends StatefulWidget {
  final Order order;
  final String name;
  final String email;
  final String phone;

  const PayNowPaymentScreen({
    Key? key,
    required this.order,
    required this.name,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  State<PayNowPaymentScreen> createState() => _PayNowPaymentScreenState();
}

class _PayNowPaymentScreenState extends State<PayNowPaymentScreen> {
  late final WebViewController controller;
  bool isLoading = true;

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
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            // Check if payment is complete
            if (url.contains('payment/complete')) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderSuccessScreen(order: widget.order),
                ),
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri(
          scheme: 'https',
          host: 'paynow.co.zw',
          path: '/payment/process',
          queryParameters: {
            'amount': widget.order.totalAmount.toString(),
            'reference': widget.order.id,
            'email': widget.email,
            'name': widget.name,
            'phone': widget.phone,
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayNow Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading payment page...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 