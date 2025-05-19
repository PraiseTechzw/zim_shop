import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

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
  final bool _isSandbox;
  final String baseUrl;
  String? _accessToken;
  Timer? _tokenRefreshTimer;
  late final http.Client _httpClient;

  bool get isSandbox => _isSandbox;

  PaymentService({
    required this.clientId,
    required this.secret,
    bool isSandbox = true,
  }) : _isSandbox = isSandbox,
       baseUrl = isSandbox 
          ? 'https://api-m.sandbox.paypal.com'
          : 'https://api-m.paypal.com' {
    debugPrint('Initializing PaymentService:');
    debugPrint('- Client ID: ${clientId.substring(0, 5)}...');
    debugPrint('- Is Sandbox: $_isSandbox');
    debugPrint('- Base URL: $baseUrl');
    
    // Initialize HTTP client with SSL certificate handling
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    _httpClient = IOClient(httpClient);
    
    _initializeToken();
  }

  void _initializeToken() {
    debugPrint('Initializing token...');
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
      debugPrint('Getting PayPal access token...');
      
      // Encode client credentials for Basic Auth
      final credentials = base64Encode(utf8.encode('$clientId:$secret'));
      debugPrint('Using credentials: ${credentials.substring(0, 10)}...');
      
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/v1/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $credentials',
        },
        body: {
          'grant_type': 'client_credentials',
        },
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 10));

      debugPrint('PayPal token response status: ${response.statusCode}');
      debugPrint('PayPal token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        debugPrint('Successfully got access token: ${_accessToken?.substring(0, 10)}...');
      } else {
        debugPrint('Error getting PayPal access token: ${response.body}');
        throw Exception('Failed to get PayPal access token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting PayPal access token: $e');
      throw Exception('Failed to get PayPal access token: $e');
    }
  }

  Future<PaymentTransaction> createPayPalPayment({
    required String email,
    required double amount,
    required String description,
  }) async {
    try {
      debugPrint('Creating PayPal payment:');
      debugPrint('- Email: $email');
      debugPrint('- Amount: $amount');
      debugPrint('- Description: $description');

      if (_accessToken == null) {
        debugPrint('Access token is null, getting new token...');
        await _getAccessToken();
      }
      debugPrint('Using access token: ${_accessToken?.substring(0, 10)}...');

      final returnUrl = isSandbox
          ? 'https://sandbox.zimmarket.com/payment/success'
          : 'https://zimmarket.com/payment/success';
      final cancelUrl = isSandbox
          ? 'https://sandbox.zimmarket.com/payment/cancel'
          : 'https://zimmarket.com/payment/cancel';

      debugPrint('Using URLs:');
      debugPrint('- Return URL: $returnUrl');
      debugPrint('- Cancel URL: $cancelUrl');

      final requestBody = {
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
      };

      debugPrint('Sending request to PayPal API:');
      debugPrint('URL: $baseUrl/v2/checkout/orders');
      debugPrint('Body: ${json.encode(requestBody)}');

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/v2/checkout/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      debugPrint('PayPal API Response:');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data == null) {
          throw Exception('Invalid response from PayPal API');
        }

        final links = data['links'] as List?;
        if (links == null) {
          throw Exception('No links found in PayPal response');
        }

        debugPrint('Found ${links.length} links in response');

        final approveLink = links.firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => {'href': null},
        );

        final redirectUrl = approveLink['href'] as String?;
        if (redirectUrl == null) {
          throw Exception('No approval URL found in PayPal response');
        }

        debugPrint('Successfully created PayPal payment:');
        debugPrint('- Order ID: ${data['id']}');
        debugPrint('- Redirect URL: $redirectUrl');

        return PaymentTransaction(
          isSuccess: true,
          reference: data['id'] as String? ?? '',
          redirectUrl: redirectUrl,
          returnUrl: returnUrl,
          cancelUrl: cancelUrl,
        );
      } else {
        final errorBody = response.body;
        debugPrint('PayPal API Error: $errorBody');
        return PaymentTransaction(
          isSuccess: false,
          error: 'Failed to create PayPal payment: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating PayPal payment: $e');
      debugPrint('Stack trace: $stackTrace');
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

      final response = await _httpClient.get(
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

      final response = await _httpClient.post(
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
    _httpClient.close();
  }
} 