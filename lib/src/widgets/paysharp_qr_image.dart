import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Builds fallback content when a PaySharp QR payload cannot be decoded.
typedef PaySharpQrErrorBuilder =
    Widget Function(BuildContext context, Object error);

/// Displays the base64 PNG returned by PaySharp's dynamic QR APIs.
class PaySharpQrImage extends StatelessWidget {
  /// Creates a QR image from a data URI or raw base64 string.
  const PaySharpQrImage({
    required this.data,
    this.size = 240,
    this.semanticLabel = 'UPI payment QR code',
    this.errorBuilder,
    super.key,
  });

  /// Base64 data URI or raw base64 image payload.
  final String data;

  /// Square display size.
  final double size;

  /// Accessibility description.
  final String semanticLabel;

  /// Optional invalid-payload builder.
  final PaySharpQrErrorBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = _decode(data);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) =>
            _buildError(context, error),
      );
    } on Object catch (error) {
      return _buildError(context, error);
    }
  }

  Widget _buildError(BuildContext context, Object error) =>
      errorBuilder?.call(context, error) ??
      SizedBox.square(
        dimension: size,
        child: const Center(child: Text('QR image unavailable')),
      );

  static Uint8List _decode(String value) {
    final trimmed = value.trim();
    final separator = trimmed.indexOf(',');
    final payload = trimmed.startsWith('data:') && separator >= 0
        ? trimmed.substring(separator + 1)
        : trimmed;
    if (payload.isEmpty) throw const FormatException('QR payload is empty');
    return base64Decode(payload);
  }
}
