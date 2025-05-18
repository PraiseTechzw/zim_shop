import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

enum PaymentMethod { ecocash, onemoney, innbucks, bank }

class PaynowTransaction {
  final String reference;
  final double amount;
  final String? pollUrl;
  final String? redirectUrl;
  final String status;
  final String? error;
  
  PaynowTransaction({
    required this.reference,
    required this.amount,
    this.pollUrl,
    this.redirectUrl,
    required this.status,
    this.error,
  });
  
  bool get isSuccess => status == 'success' || status == 'Ok';
  bool get isPending => status == 'pending';
  bool get isError => status == 'error' || error != null;
}

class PaynowService {
  // Paynow Integration Details
  final String _integrationId;
  final String _integrationKey;
  final String _resultUrl;
  final String _returnUrl;
  
  // API Endpoints
  final String _initiateTransactionUrl = 'https://www.paynow.co.zw/interface/initiatetransaction';
  final String _initiatePatinateUrl = 'https://www.paynow.co.zw/interface/remotetransaction';
  
  // Singleton pattern
  static PaynowService? _instance;
  
  factory PaynowService({
    required String integrationId,
    required String integrationKey,
    required String resultUrl,
    required String returnUrl,
  }) {
    _instance ??= PaynowService._internal(
      integrationId: integrationId,
      integrationKey: integrationKey,
      resultUrl: resultUrl,
      returnUrl: returnUrl,
    );
    return _instance!;
  }
  
  PaynowService._internal({
    required String integrationId,
    required String integrationKey,
    required String resultUrl,
    required String returnUrl,
  }) : 
    _integrationId = integrationId,
    _integrationKey = integrationKey,
    _resultUrl = resultUrl,
    _returnUrl = returnUrl;
  
  // Generate a unique reference for each transaction
  String _generateReference() {
    return const Uuid().v4().substring(0, 8);
  }
  
  // Create hash for the request
  String _createHash(Map<String, String> data) {
    // Sort the data alphabetically by key
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    // Create string from all values
    final values = entries.map((e) => e.value).join('');
    
    // Combine with integration key
    final string = values + _integrationKey;
    
    // Generate hash
    final bytes = utf8.encode(string);
    final hash = md5.convert(bytes);
    
    return hash.toString().toUpperCase();
  }
  
  // Make a POST request to Paynow
  Future<Map<String, String>> _makeRequest(String url, Map<String, String> data) async {
    data['hash'] = _createHash(data);
    
    try {
      final response = await http.post(
        Uri.parse(url),
        body: data,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
      
      if (response.statusCode == 200) {
        // Parse the response from Paynow
        final responseStr = response.body;
        final responseMap = <String, String>{};
        
        for (final pair in responseStr.split('&')) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            responseMap[parts[0]] = Uri.decodeComponent(parts[1]);
          }
        }
        
        return responseMap;
      } else {
        throw Exception('Failed to connect to Paynow: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error making request to Paynow: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }
  
  // Initiate a web-based transaction
  Future<PaynowTransaction> createWebPayment({
    required String email,
    required double amount,
    required String description,
    String? reference,
  }) async {
    final ref = reference ?? _generateReference();
    
    final data = {
      'id': _integrationId,
      'reference': ref,
      'amount': amount.toStringAsFixed(2),
      'description': description,
      'email': email,
      'resulturl': _resultUrl,
      'returnurl': _returnUrl,
    };
    
    try {
      final response = await _makeRequest(_initiateTransactionUrl, data);
      
      if (response['status']?.toLowerCase() == 'ok') {
        return PaynowTransaction(
          reference: ref,
          amount: amount,
          pollUrl: response['pollurl'],
          redirectUrl: response['browserurl'],
          status: 'success',
        );
      } else {
        return PaynowTransaction(
          reference: ref,
          amount: amount,
          status: 'error',
          error: response['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      return PaynowTransaction(
        reference: ref,
        amount: amount,
        status: 'error',
        error: e.toString(),
      );
    }
  }
  
  // Initiate a mobile money payment
  Future<PaynowTransaction> createMobilePayment({
    required String phone,
    required double amount,
    required String description,
    required PaymentMethod method,
    String? reference,
  }) async {
    final ref = reference ?? _generateReference();
    
    String methodValue;
    switch (method) {
      case PaymentMethod.ecocash:
        methodValue = 'ecocash';
        break;
      case PaymentMethod.onemoney:
        methodValue = 'onemoney';
        break;
      case PaymentMethod.innbucks:
        methodValue = 'innbucks';
        break;
      case PaymentMethod.bank:
        methodValue = 'bank';
        break;
    }
    
    final data = {
      'id': _integrationId,
      'reference': ref,
      'amount': amount.toStringAsFixed(2),
      'description': description,
      'phone': phone,
      'method': methodValue,
      'resulturl': _resultUrl,
    };
    
    try {
      final response = await _makeRequest(_initiatePatinateUrl, data);
      
      if (response['status']?.toLowerCase() == 'ok') {
        return PaynowTransaction(
          reference: ref,
          amount: amount,
          pollUrl: response['pollurl'],
          status: 'success',
        );
      } else {
        return PaynowTransaction(
          reference: ref,
          amount: amount,
          status: 'error',
          error: response['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      return PaynowTransaction(
        reference: ref,
        amount: amount,
        status: 'error',
        error: e.toString(),
      );
    }
  }
  
  // Check payment status
  Future<PaynowTransaction> checkPaymentStatus(String pollUrl, String reference, double amount) async {
    try {
      final response = await http.get(Uri.parse(pollUrl));
      
      if (response.statusCode == 200) {
        final responseStr = response.body;
        final responseMap = <String, String>{};
        
        for (final pair in responseStr.split('&')) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            responseMap[parts[0]] = Uri.decodeComponent(parts[1]);
          }
        }
        
        if (responseMap['status']?.toLowerCase() == 'paid') {
          return PaynowTransaction(
            reference: reference,
            amount: amount,
            status: 'success',
          );
        } else if (responseMap['status']?.toLowerCase() == 'awaiting delivery') {
          return PaynowTransaction(
            reference: reference,
            amount: amount,
            status: 'pending',
          );
        } else {
          return PaynowTransaction(
            reference: reference,
            amount: amount,
            status: 'error',
            error: responseMap['error'] ?? 'Payment not completed',
          );
        }
      } else {
        throw Exception('Failed to check payment status: ${response.statusCode}');
      }
    } catch (e) {
      return PaynowTransaction(
        reference: reference,
        amount: amount,
        status: 'error',
        error: e.toString(),
      );
    }
  }
} 