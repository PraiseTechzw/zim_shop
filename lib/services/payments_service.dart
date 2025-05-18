import 'package:flutter/foundation.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/services/paynow_service.dart';
import 'package:zim_shop/services/supabase_service.dart';

class PaymentResult {
  final bool success;
  final String? paymentUrl;
  final String? pollUrl;
  final String? error;
  final String? reference;
  
  PaymentResult({
    required this.success,
    this.paymentUrl,
    this.pollUrl,
    this.error,
    this.reference,
  });
}

class PaymentsService {
  final PaynowService _paynowService;
  final SupabaseService _supabaseService = SupabaseService();
  
  PaymentsService({required PaynowService paynowService}) : _paynowService = paynowService;
  
  // Process checkout for the cart items
  Future<PaymentResult> processCheckout({
    required List<CartItem> items,
    required String userId,
    required String email,
    required String phone,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // 1. Calculate total
      final totalAmount = items.fold(0.0, (total, item) => 
        total + (item.product.price * item.quantity));
      
      // 2. Create order in database
      final order = Order(
        id: 0, // Will be assigned by the database
        userId: int.parse(userId),
        items: items,
        totalAmount: totalAmount,
        date: DateTime.now(),
        status: 'pending',
      );
      
      final orderCreated = await _supabaseService.createOrder(order);
      if (!orderCreated) {
        return PaymentResult(
          success: false,
          error: 'Failed to create order. Please try again.',
        );
      }
      
      // 3. Process payment based on method
      final description = 'Payment for ${items.length} items from ZimMarket';
      
      PaynowTransaction transaction;
      if (paymentMethod == PaymentMethod.bank) {
        // Web payment for bank transfers
        transaction = await _paynowService.createWebPayment(
          email: email,
          amount: totalAmount,
          description: description,
        );
      } else {
        // Mobile money payment
        transaction = await _paynowService.createMobilePayment(
          phone: phone,
          amount: totalAmount,
          description: description,
          method: paymentMethod,
        );
      }
      
      if (transaction.isSuccess) {
        // 4. Store payment info in database
        await _storePaymentInfo(
          orderId: '', // Get this from the created order
          amount: totalAmount,
          reference: transaction.reference,
          pollUrl: transaction.pollUrl,
        );
        
        return PaymentResult(
          success: true,
          paymentUrl: transaction.redirectUrl,
          pollUrl: transaction.pollUrl,
          reference: transaction.reference,
        );
      } else {
        return PaymentResult(
          success: false,
          error: transaction.error ?? 'Payment processing failed',
        );
      }
    } catch (e) {
      debugPrint('Error processing checkout: $e');
      return PaymentResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }
  
  // Store payment information in database
  Future<void> _storePaymentInfo({
    required String orderId,
    required double amount,
    required String reference,
    required String? pollUrl,
  }) async {
    try {
      await _supabaseService.client.from('payments').insert({
        'order_id': orderId,
        'amount': amount,
        'paynow_reference': reference,
        'paynow_poll_url': pollUrl,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error storing payment info: $e');
    }
  }
  
  // Check payment status
  Future<bool> checkPaymentStatus({
    required String pollUrl,
    required String reference,
    required double amount,
  }) async {
    try {
      final transaction = await _paynowService.checkPaymentStatus(
        pollUrl,
        reference,
        amount,
      );
      
      if (transaction.isSuccess) {
        // Update payment status in database
        await _updatePaymentStatus(reference, 'completed');
        return true;
      } else if (transaction.isPending) {
        return false; // Still waiting for payment
      } else {
        // Payment failed
        await _updatePaymentStatus(reference, 'failed');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return false;
    }
  }
  
  // Update payment status in database
  Future<void> _updatePaymentStatus(String reference, String status) async {
    try {
      await _supabaseService.client
          .from('payments')
          .update({'status': status})
          .eq('paynow_reference', reference);
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }
} 