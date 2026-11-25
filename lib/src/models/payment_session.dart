import 'payment_status.dart';

/// Payment session returned by the merchant backend.
final class PaySharpPaymentSession {
  /// Creates an immutable payment session.
  const PaySharpPaymentSession({
    required this.orderId,
    required this.status,
    this.amount,
    this.paysharpReferenceNumber,
    this.intentUri,
    this.phonePeUri,
    this.googlePayUri,
    this.qrCode,
    this.failureCode,
    this.failureReason,
    this.transactionDate,
    this.raw = const <String, Object?>{},
  });

  /// Parses a session returned by the merchant backend.
  factory PaySharpPaymentSession.fromJson(Map<String, Object?> json) {
    final orderId = _string(json, 'orderId');
    if (orderId == null || orderId.isEmpty) {
      throw const FormatException('Payment response is missing orderId');
    }

    final amount = json['amount'];
    return PaySharpPaymentSession(
      orderId: orderId,
      status: PaySharpPaymentStatus.fromWireValue(json['status']),
      amount: amount is num ? amount : null,
      paysharpReferenceNumber: _string(json, 'paysharpReferenceNo'),
      intentUri: _uri(json, 'intentUrl'),
      phonePeUri: _uri(json, 'phonepeUrl'),
      googlePayUri: _uri(json, 'gpayUrl'),
      qrCode: _string(json, 'qrCode'),
      failureCode: _string(json, 'failureCode'),
      failureReason: _string(json, 'failureReason'),
      transactionDate: _dateTime(json, 'transactionDate'),
      raw: Map<String, Object?>.unmodifiable(json),
    );
  }

  /// Merchant order identifier.
  final String orderId;

  /// Current payment state.
  final PaySharpPaymentStatus status;

  /// Payment amount when returned by the backend.
  final num? amount;

  /// PaySharp-generated payment reference.
  final String? paysharpReferenceNumber;

  /// Generic UPI intent URI.
  final Uri? intentUri;

  /// PhonePe-specific intent URI.
  final Uri? phonePeUri;

  /// Google Pay-specific intent URI.
  final Uri? googlePayUri;

  /// Base64 data URI or base64 payload for a PaySharp-generated QR image.
  final String? qrCode;

  /// Bank or PaySharp failure code when present.
  final String? failureCode;

  /// Human-readable failure reason when present.
  final String? failureReason;

  /// Transaction timestamp when present.
  final DateTime? transactionDate;

  /// Unmodified response fields for forward compatibility.
  final Map<String, Object?> raw;

  static String? _string(Map<String, Object?> json, String key) {
    final value = json[key];
    return value is String ? value : null;
  }

  static Uri? _uri(Map<String, Object?> json, String key) {
    final value = _string(json, key);
    return value == null || value.isEmpty ? null : Uri.tryParse(value);
  }

  static DateTime? _dateTime(Map<String, Object?> json, String key) {
    final value = _string(json, key);
    return value == null ? null : DateTime.tryParse(value);
  }
}
