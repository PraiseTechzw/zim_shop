import 'package:paynow/paynow.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zim_shop/models/order.dart';

class PaymentService {
  // Paynow integration ID and key (replace with your actual values)
  static const String _integrationId = '12345';
  static const String _integrationKey = 'your-integration-key';
  
  final Paynow _paynow = Paynow(
    integrationId: _integrationId,
    integrationKey: _integrationKey,
    returnUrl: 'https://zimshop.com/return',
    resultUrl: 'https://zimshop.com/result',
  );

  // Create a payment request for an order
  Future<Map<String, dynamic>> createPayment(Order order, String email) async {
    try {
      // Create payment reference
      final reference = 'INV-${order.id}-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create payment
      final payment = _paynow.createPayment(reference, email);
      
      // Add items to payment
      for (final item in order.items) {
        payment.add(
          item.product.name,
          item.product.price * item.quantity,
        );
      }
      
      // Init transaction
      final response = await _paynow.sendMobile(
        payment,
        '07XXXXXXXX', // User's phone number would be passed here
        'ecocash', // Payment method (ecocash, onemoney, telecash)
      );

      if (response.success) {
        // Save payment info to Firestore
        await _savePaymentInfo(order.id, reference, response);
        
        // Return payment details
        return {
          'success': true,
          'reference': reference,
          'instructions': response.instructions,
          'pollUrl': response.pollUrl,
        };
      } else {
        return {
          'success': false,
          'error': response.error,
        };
      }
    } catch (e) {
      debugPrint('Payment creation error: $e');
      return {
        'success': false,
        'error': 'Failed to process payment: ${e.toString()}',
      };
    }
  }

  // Save payment information to Firestore
  Future<void> _savePaymentInfo(int orderId, String reference, PnResponse response) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(reference)
          .set({
        'orderId': orderId.toString(),
        'reference': reference,
        'amount': response.amount,
        'status': 'pending',
        'pollUrl': response.pollUrl,
        'method': response.method,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving payment info: $e');
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String pollUrl) async {
    try {
      final status = await _paynow.checkTransactionStatus(pollUrl);
      
      if (status.paid) {
        // Update payment status in Firestore
        await _updatePaymentStatus(status.reference, 'paid');
        
        return {
          'success': true,
          'paid': true,
          'status': status.status,
          'reference': status.reference,
        };
      } else {
        return {
          'success': true,
          'paid': false,
          'status': status.status,
          'reference': status.reference,
        };
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return {
        'success': false,
        'error': 'Failed to check payment status: ${e.toString()}',
      };
    }
  }

  // Update payment status in Firestore
  Future<void> _updatePaymentStatus(String reference, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(reference)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }
} 