import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/network/api_exception.dart';
import 'order_repository.dart';

class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

class RazorpayService {
  Future<RazorpayPaymentResult> pay(RazorpayCheckout checkout) async {
    final razorpay = Razorpay();
    final completer = Completer<RazorpayPaymentResult>();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (completer.isCompleted) return;
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;
      if (orderId == null || paymentId == null || signature == null) {
        completer.completeError(ApiException('Razorpay returned an incomplete payment response.'));
        return;
      }
      completer.complete(
        RazorpayPaymentResult(
          orderId: orderId,
          paymentId: paymentId,
          signature: signature,
        ),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      final detail = response.message?.trim();
      completer.completeError(
        ApiException(detail == null || detail.isEmpty ? 'Razorpay payment failed.' : detail),
      );
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {
      if (completer.isCompleted) return;
      completer.completeError(ApiException('External wallet payments are not supported yet.'));
    });

    try {
      razorpay.open(checkout.toOptions());
      return await completer.future;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    } finally {
      razorpay.clear();
    }
  }
}

final razorpayServiceProvider = Provider<RazorpayService>((ref) => RazorpayService());
