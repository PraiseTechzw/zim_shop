import 'package:flutter/foundation.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/models/cart_item.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'payment_service.dart' as payment;

class PaymentResult {
  final bool success;
  final String? error;
  final String? reference;
  final String? redirectUrl;
  
  PaymentResult({
    required this.success,
    this.error,
    this.reference,
    this.redirectUrl,
  });
}

class PaymentsService {
  final payment.PaymentService _paymentService;
  final SupabaseService _supabaseService = SupabaseService();
  
  PaymentsService({required payment.PaymentService paymentService}) : _paymentService = paymentService;
  
  // Process checkout for the cart items
  Future<PaymentResult> processCheckout({
    required List<CartItem> items,
    required String email,
    required String phone,
    required payment.PaymentMethod paymentMethod,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
      
      // Create payment description
      final description = 'Payment for ${items.length} items from ZimMarket';
      
      payment.PaymentTransaction transaction;
      if (paymentMethod == payment.PaymentMethod.bank) {
        // Bank payment
        transaction = await _paymentService.createBankPayment(
          amount: totalAmount,
          description: description,
        );
      } else {
        // PayPal payment
        transaction = await _paymentService.createPayPalPayment(
          email: email,
          amount: totalAmount,
          description: description,
        );
      }
      
      if (transaction.isSuccess) {
        return PaymentResult(
          success: true,
          reference: transaction.reference,
          redirectUrl: transaction.redirectUrl,
        );
      } else {
        return PaymentResult(
          success: false,
          error: transaction.error ?? 'Payment failed',
        );
      }
    } catch (e) {
      debugPrint('Error processing checkout: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  Future<PaymentResult> checkPaymentStatus({
    required String reference,
    required double amount,
    required payment.PaymentMethod method,
  }) async {
    try {
      final transaction = await _paymentService.checkPaymentStatus(
        reference: reference,
        amount: amount,
        method: method,
      );
      
      return PaymentResult(
        success: transaction.isSuccess,
        error: transaction.error,
        reference: transaction.reference,
        redirectUrl: transaction.redirectUrl,
      );
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return PaymentResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  Stream<PaymentResult> streamPaymentStatus({
    required String reference,
    required double amount,
    required payment.PaymentMethod method,
  }) {
    return _paymentService.streamPaymentStatus(
      reference: reference,
      amount: amount,
      method: method,
    ).map((transaction) => PaymentResult(
      success: transaction.isSuccess,
      error: transaction.error,
      reference: transaction.reference,
      redirectUrl: transaction.redirectUrl,
    ));
  }
} 