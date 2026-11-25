import '../models/payment_request.dart';
import '../models/payment_session.dart';

/// Merchant-controlled boundary used by the Flutter checkout package.
///
/// Implementations must call the merchant's own backend. PaySharp merchant API
/// tokens must never be embedded in Flutter application binaries.
abstract interface class PaySharpBackend {
  /// Creates a PaySharp payment through the merchant backend.
  Future<PaySharpPaymentSession> createPayment(PaySharpPaymentRequest request);

  /// Retrieves the latest payment status through the merchant backend.
  Future<PaySharpPaymentSession> getPayment(String orderId);
}
