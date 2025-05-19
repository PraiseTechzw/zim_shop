import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum PaymentMethod { paypal, bank }

class PaymentTransaction {
  final String reference;
  final double amount;
  final String? redirectUrl;
  final String status;
  final String? error;
  
  PaymentTransaction({
    required this.reference,
    required this.amount,
    this.redirectUrl,
    required this.status,
    this.error,
  });
  
  bool get isSuccess => status == 'success' || status == 'completed';
  bool get isPending => status == 'pending';
  bool get isError => status == 'error' || error != null;
}

class PaymentService {
  // PayPal Configuration
  final String _clientId;
  final String _secret;
  final bool _isSandbox;
  String? _accessToken;
  
  // API Endpoints
  String get _baseUrl => _isSandbox 
    ? 'https://api-m.sandbox.paypal.com'
    : 'https://api-m.paypal.com';
  
  // Singleton pattern
  static PaymentService? _instance;
  
  factory PaymentService({
    required String clientId,
    required String secret,
    bool isSandbox = true,
  }) {
    _instance ??= PaymentService._internal(
      clientId: clientId,
      secret: secret,
      isSandbox: isSandbox,
    );
    return _instance!;
  }
  
  PaymentService._internal({
    required String clientId,
    required String secret,
    required bool isSandbox,
  }) : 
    _clientId = clientId,
    _secret = secret,
    _isSandbox = isSandbox;
  
  // Get PayPal access token
  Future<String> _getAccessToken() async {
    if (_accessToken != null) {
      return _accessToken!;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_secret'))}',
        },
        body: {
          'grant_type': 'client_credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting access token: $e');
    }
  }
  
  // Create a PayPal payment
  Future<PaymentTransaction> createPayPalPayment({
    required String email,
    required double amount,
    required String description,
    String? reference,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/v2/checkout/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'reference_id': reference ?? description,
              'amount': {
                'currency_code': 'USD',
                'value': amount.toStringAsFixed(2),
              },
              'description': description,
            }
          ],
          'application_context': {
            'return_url': 'https://example.com/return',
            'cancel_url': 'https://example.com/cancel',
          }
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PaymentTransaction(
          reference: reference ?? description,
          amount: amount,
          redirectUrl: data['links'][1]['href'], // Approval URL
          status: 'success',
        );
      } else {
        throw Exception('Failed to create PayPal payment: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating PayPal payment: $e');
      return PaymentTransaction(
        reference: reference ?? description,
        amount: amount,
        status: 'error',
        error: e.toString(),
      );
    }
  }
  
  // Create a bank payment
  Future<PaymentTransaction> createBankPayment({
    required double amount,
    required String description,
    String? reference,
  }) async {
    try {
      // TODO: Implement bank payment integration
      // This is a placeholder for bank payment implementation
      return PaymentTransaction(
        reference: reference ?? description,
        amount: amount,
        status: 'pending',
      );
    } catch (e) {
      debugPrint('Error creating bank payment: $e');
      return PaymentTransaction(
        reference: reference ?? description,
        amount: amount,
        status: 'error',
        error: e.toString(),
      );
    }
  }
  
  // Check payment status
  Future<PaymentTransaction> checkPaymentStatus({
    required String reference,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      switch (method) {
        case PaymentMethod.paypal:
          final accessToken = await _getAccessToken();
          
          final response = await http.get(
            Uri.parse('$_baseUrl/v2/checkout/orders/$reference'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return PaymentTransaction(
              reference: reference,
              amount: amount,
              status: data['status'].toLowerCase(),
            );
          } else {
            throw Exception('Failed to check PayPal payment status: ${response.body}');
          }
        case PaymentMethod.bank:
          // TODO: Implement bank payment status check
          return PaymentTransaction(
            reference: reference,
            amount: amount,
            status: 'pending',
          );
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return PaymentTransaction(
        reference: reference,
        amount: amount,
        status: 'error',
        error: e.toString(),
      );
    }
  }
  
  // Stream payment status updates
  Stream<PaymentTransaction> streamPaymentStatus({
    required String reference,
    required double amount,
    required PaymentMethod method,
  }) async* {
    while (true) {
      final status = await checkPaymentStatus(
        reference: reference,
        amount: amount,
        method: method,
      );
      
      yield status;
      
      if (status.isSuccess || status.isError) {
        break;
      }
      
      await Future.delayed(const Duration(seconds: 5));
    }
  }
} 