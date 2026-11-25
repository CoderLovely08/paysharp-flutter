import 'dart:async';

import '../backend/paysharp_backend.dart';
import '../models/payment_request.dart';
import '../models/payment_session.dart';
import 'paysharp_upi_launcher.dart';

/// Receives each payment status while polling.
typedef PaySharpStatusCallback =
    FutureOr<void> Function(PaySharpPaymentSession session);

/// Cooperative cancellation signal for payment polling.
final class PaySharpCancellationToken {
  bool _cancelled = false;

  /// Whether cancellation has been requested.
  bool get isCancelled => _cancelled;

  /// Requests cancellation before the next status request.
  void cancel() => _cancelled = true;
}

/// Coordinates payment creation, UPI launch, and status polling.
final class PaySharpCheckout {
  /// Creates a checkout coordinator.
  PaySharpCheckout({required this.backend, PaySharpUpiLauncher? launcher})
    : launcher = launcher ?? PaySharpUpiLauncher();

  /// Merchant-controlled backend implementation.
  final PaySharpBackend backend;

  /// UPI application launcher.
  final PaySharpUpiLauncher launcher;

  /// Creates a payment and optionally opens a UPI application.
  Future<PaySharpPaymentSession> createPayment(
    PaySharpPaymentRequest request, {
    bool launch = false,
    PaySharpUpiApp app = PaySharpUpiApp.automatic,
  }) async {
    final session = await backend.createPayment(request);
    if (launch) await launcher.launch(session, app: app);
    return session;
  }

  /// Retrieves the latest state of an existing payment.
  Future<PaySharpPaymentSession> refresh(String orderId) =>
      backend.getPayment(orderId);

  /// Polls until PaySharp reports a terminal state or [timeout] elapses.
  Future<PaySharpPaymentSession> pollUntilTerminal(
    String orderId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 2),
    PaySharpStatusCallback? onUpdate,
    PaySharpCancellationToken? cancellationToken,
  }) async {
    if (interval <= Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'must be positive');
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }

    final stopwatch = Stopwatch()..start();
    while (true) {
      if (cancellationToken?.isCancelled ?? false) {
        throw const PaySharpPollingCancelledException();
      }

      final session = await backend.getPayment(orderId);
      await onUpdate?.call(session);
      if (session.status.isTerminal) return session;
      if (stopwatch.elapsed >= timeout) {
        throw TimeoutException(
          'Payment $orderId did not reach a terminal state',
          timeout,
        );
      }

      final remaining = timeout - stopwatch.elapsed;
      await Future<void>.delayed(remaining < interval ? remaining : interval);
    }
  }
}

/// Indicates that status polling was cancelled by the application.
final class PaySharpPollingCancelledException implements Exception {
  /// Creates the cancellation marker.
  const PaySharpPollingCancelledException();

  @override
  String toString() => 'PaySharp payment polling was cancelled';
}
