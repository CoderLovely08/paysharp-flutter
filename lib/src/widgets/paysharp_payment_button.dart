import 'dart:async';

import 'package:flutter/widgets.dart';

import '../checkout/paysharp_checkout.dart';
import '../checkout/paysharp_upi_launcher.dart';
import '../models/payment_request.dart';
import '../models/payment_session.dart';

/// Callback invoked after payment creation succeeds.
typedef PaySharpPaymentCreated =
    FutureOr<void> Function(PaySharpPaymentSession session);

/// Callback invoked when payment creation or UPI launch fails.
typedef PaySharpPaymentError =
    FutureOr<void> Function(Object error, StackTrace stackTrace);

/// Builds the visual button while the package owns its payment behavior.
typedef PaySharpButtonBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback? onPressed,
      Widget child,
    );

/// Button that creates and optionally launches a PaySharp payment.
class PaySharpPaymentButton extends StatefulWidget {
  /// Creates a payment button.
  const PaySharpPaymentButton({
    required this.checkout,
    required this.request,
    required this.child,
    this.onCreated,
    this.onError,
    this.launch = true,
    this.app = PaySharpUpiApp.automatic,
    this.loadingChild,
    this.builder,
    this.enabled = true,
    super.key,
  });

  /// Checkout coordinator used for the request.
  final PaySharpCheckout checkout;

  /// Payment request created when the button is pressed.
  final PaySharpPaymentRequest request;

  /// Normal button content.
  final Widget child;

  /// Content displayed while the request is running.
  final Widget? loadingChild;

  /// Optional application-specific button builder.
  final PaySharpButtonBuilder? builder;

  /// Called after payment creation and optional app launch.
  final PaySharpPaymentCreated? onCreated;

  /// Called for request and launch failures.
  final PaySharpPaymentError? onError;

  /// Whether to launch a UPI application after creation.
  final bool launch;

  /// Preferred UPI application.
  final PaySharpUpiApp app;

  /// Whether the button accepts input.
  final bool enabled;

  @override
  State<PaySharpPaymentButton> createState() => _PaySharpPaymentButtonState();
}

class _PaySharpPaymentButtonState extends State<PaySharpPaymentButton> {
  bool _loading = false;

  Future<void> _pay() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final session = await widget.checkout.createPayment(
        widget.request,
        launch: widget.launch,
        app: widget.app,
      );
      await widget.onCreated?.call(session);
    } on Object catch (error, stackTrace) {
      await widget.onError?.call(error, stackTrace);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.enabled && !_loading ? _pay : null;
    final child = _loading
        ? widget.loadingChild ?? const Text('Processing…')
        : widget.child;
    return widget.builder?.call(context, onPressed, child) ??
        _DefaultPaySharpButton(onPressed: onPressed, child: child);
  }
}

class _DefaultPaySharpButton extends StatelessWidget {
  const _DefaultPaySharpButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    child: GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.55 : 1,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF1565C0),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
