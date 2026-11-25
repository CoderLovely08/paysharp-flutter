import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment_session.dart';
import '../models/paysharp_exception.dart';

/// UPI application preferred for an intent launch.
enum PaySharpUpiApp {
  /// Use an app-specific URI when available, then fall back to generic UPI.
  automatic,

  /// Prefer PaySharp's PhonePe-specific URI.
  phonePe,

  /// Prefer PaySharp's Google Pay-specific URI.
  googlePay,

  /// Use the generic UPI URI.
  generic,
}

/// Testable function that opens a URI on the current platform.
typedef PaySharpLaunchUri = Future<bool> Function(Uri uri);

/// Opens PaySharp intent URIs using an installed UPI application.
final class PaySharpUpiLauncher {
  /// Creates a launcher, optionally replacing platform launch behavior.
  PaySharpUpiLauncher({PaySharpLaunchUri? launchUri})
    : _launchUri = launchUri ?? _platformLaunch;

  final PaySharpLaunchUri _launchUri;

  /// Launches the best URI for [app].
  ///
  /// Throws [PaySharpException] when the session contains no suitable URI or
  /// the operating system cannot open it.
  Future<void> launch(
    PaySharpPaymentSession session, {
    PaySharpUpiApp app = PaySharpUpiApp.automatic,
  }) async {
    final uri = _selectUri(session, app);
    if (uri == null) {
      throw const PaySharpException(
        'Payment session does not contain a usable UPI intent URI',
      );
    }

    try {
      if (!await _launchUri(uri)) {
        throw PaySharpException('No application could open ${uri.scheme} URI');
      }
    } on PaySharpException {
      rethrow;
    } on Object catch (error) {
      throw PaySharpException(
        'Unable to launch a UPI application',
        cause: error,
      );
    }
  }

  static Uri? _selectUri(PaySharpPaymentSession session, PaySharpUpiApp app) =>
      switch (app) {
        PaySharpUpiApp.phonePe => session.phonePeUri ?? session.intentUri,
        PaySharpUpiApp.googlePay => session.googlePayUri ?? session.intentUri,
        PaySharpUpiApp.generic => session.intentUri,
        PaySharpUpiApp.automatic =>
          session.intentUri ?? session.googlePayUri ?? session.phonePeUri,
      };

  static Future<bool> _platformLaunch(Uri uri) => launchUrl(
    uri,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
  );
}
