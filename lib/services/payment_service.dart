import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum PaymentMethod {
  paypal,
  bank,
}

class PaymentTransaction {
  final bool isSuccess;
  final String? error;
  final String? reference;
  final String? redirectUrl;
  final String? returnUrl;
  final String? cancelUrl;

  PaymentTransaction({
    required this.isSuccess,
    this.error,
    this.reference,
    this.redirectUrl,
    this.returnUrl,
    this.cancelUrl,
  });
}

class PaymentService {
  final String clientId;
  final String secret;
  final bool isSandbox;
  final String baseUrl;
  String? _accessToken;
  Timer? _tokenRefreshTimer;

  PaymentService({
    required this.clientId,
    required this.secret,
    this.isSandbox = true,
  }) : baseUrl = isSandbox
          ? 'https://api-m.sandbox.paypal.com'
          : 'https://api-m.paypal.com' {
    _initializeToken();
  }

  void _initializeToken() {
    _getAccessToken();
    // Refresh token every 8 hours (PayPal tokens are valid for 9 hours)
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(hours: 8),
      (_) => _getAccessToken(),
    );
  }

  Future<void> _getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
        },
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
      } else {
        debugPrint('Error getting PayPal access token: ${response.body}');
        throw Exception('Failed to get PayPal access token');
      }
    } catch (e) {
      debugPrint('Error getting PayPal access token: $e');
      throw Exception('Failed to get PayPal access token');
    }
  }

  Future<PaymentTransaction> createPayPalPayment({
    required String email,
    required double amount,
    required String description,
  }) async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final returnUrl = isSandbox
          ? 'https://sandbox.zimmarket.com/payment/success'
          : 'https://zimmarket.com/payment/success';
      final cancelUrl = isSandbox
          ? 'https://sandbox.zimmarket.com/payment/cancel'
          : 'https://zimmarket.com/payment/cancel';

      final response = await http.post(
        Uri.parse('$baseUrl/v2/checkout/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {
                'currency_code': 'USD',
                'value': amount.toStringAsFixed(2),
              },
              'description': description,
            }
          ],
          'application_context': {
            'return_url': returnUrl,
            'cancel_url': cancelUrl,
            'brand_name': 'ZimMarket',
            'landing_page': 'LOGIN',
            'user_action': 'PAY_NOW',
            'shipping_preference': 'NO_SHIPPING',
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final links = data['links'] as List;
        final approveLink = links.firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => {'href': null},
        );
        
        return PaymentTransaction(
          isSuccess: true,
          reference: data['id'],
          redirectUrl: approveLink['href'],
          returnUrl: returnUrl,
          cancelUrl: cancelUrl,
        );
      } else {
        debugPrint('Error creating PayPal payment: ${response.body}');
        return PaymentTransaction(
          isSuccess: false,
          error: 'Failed to create PayPal payment',
        );
      }
    } catch (e) {
      debugPrint('Error creating PayPal payment: $e');
      return PaymentTransaction(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<PaymentTransaction> checkPaymentStatus({
    required String reference,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/v2/checkout/orders/$reference'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        
        return PaymentTransaction(
          isSuccess: status == 'COMPLETED',
          reference: reference,
          error: status == 'COMPLETED' ? null : 'Payment status: $status',
        );
      } else {
        debugPrint('Error checking PayPal payment status: ${response.body}');
        return PaymentTransaction(
          isSuccess: false,
          error: 'Failed to check payment status',
        );
      }
    } catch (e) {
      debugPrint('Error checking PayPal payment status: $e');
      return PaymentTransaction(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  Stream<PaymentTransaction> streamPaymentStatus({
    required String reference,
    required double amount,
    required PaymentMethod method,
  }) async* {
    while (true) {
      final result = await checkPaymentStatus(
        reference: reference,
        amount: amount,
        method: method,
      );
      
      yield result;
      
      if (result.isSuccess) {
        break;
      }
      
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<PaymentTransaction> capturePayPalPayment({
    required String orderId,
  }) async {
    try {
      if (_accessToken == null) {
        await _getAccessToken();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return PaymentTransaction(
          isSuccess: true,
          reference: data['id'],
        );
      } else {
        debugPrint('Error capturing PayPal payment: ${response.body}');
        return PaymentTransaction(
          isSuccess: false,
          error: 'Failed to capture payment',
        );
      }
    } catch (e) {
      debugPrint('Error capturing PayPal payment: $e');
      return PaymentTransaction(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<PaymentTransaction> createBankPayment({
    required double amount,
    required String description,
  }) async {
    try {
      // For now, return a placeholder transaction
      return PaymentTransaction(
        isSuccess: true,
        reference: DateTime.now().millisecondsSinceEpoch.toString(),
        redirectUrl: null,
      );
    } catch (e) {
      debugPrint('Error creating bank payment: $e');
      return PaymentTransaction(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  void dispose() {
    _tokenRefreshTimer?.cancel();
  }
} 