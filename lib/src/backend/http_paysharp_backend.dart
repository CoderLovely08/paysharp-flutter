import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment_request.dart';
import '../models/payment_session.dart';
import '../models/paysharp_exception.dart';
import 'paysharp_backend.dart';

/// Supplies application-session headers for calls to the merchant backend.
typedef PaySharpHeadersProvider = FutureOr<Map<String, String>> Function();

/// Builds the status path for a merchant order identifier.
typedef PaySharpStatusPathBuilder = String Function(String orderId);

/// HTTP implementation of [PaySharpBackend] for a merchant-controlled server.
///
/// The server is responsible for authenticating the app user and calling
/// PaySharp with its server-side merchant token.
final class HttpPaySharpBackend implements PaySharpBackend {
  /// Creates a backend client.
  HttpPaySharpBackend({
    required Uri baseUri,
    http.Client? client,
    this.headersProvider,
    this.createPath = 'payments',
    this.statusPathBuilder = _defaultStatusPath,
    this.timeout = const Duration(seconds: 30),
  }) : _baseUri = _normalizeBaseUri(baseUri),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  /// Optional application-authentication headers.
  ///
  /// These headers authenticate against the merchant backend, not PaySharp.
  final PaySharpHeadersProvider? headersProvider;

  /// Relative path that accepts payment creation requests.
  final String createPath;

  /// Function that maps an order ID to a relative status path.
  final PaySharpStatusPathBuilder statusPathBuilder;

  /// Maximum duration for each merchant-backend request.
  final Duration timeout;

  @override
  Future<PaySharpPaymentSession> createPayment(
    PaySharpPaymentRequest request,
  ) async {
    final response = await _client
        .post(
          _resolve(createPath),
          headers: await _headers(),
          body: jsonEncode(request.toJson()),
        )
        .timeout(timeout);
    return _decode(response);
  }

  @override
  Future<PaySharpPaymentSession> getPayment(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'must not be empty');
    }
    final response = await _client
        .get(_resolve(statusPathBuilder(orderId)), headers: await _headers())
        .timeout(timeout);
    return _decode(response);
  }

  Future<Map<String, String>> _headers() async {
    final customHeaders = await headersProvider?.call();
    return <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      ...?customHeaders,
    };
  }

  PaySharpPaymentSession _decode(http.Response response) {
    Map<String, Object?>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) body = decoded;
    } on FormatException catch (error) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw PaySharpException(
          'Merchant backend returned invalid JSON',
          statusCode: response.statusCode,
          cause: error,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaySharpException(
        _string(body, 'message') ?? 'Merchant backend request failed',
        statusCode: response.statusCode,
        code: body?['errorCode'] ?? body?['code'],
        details: body,
      );
    }
    if (body == null) {
      throw PaySharpException(
        'Merchant backend returned an empty response',
        statusCode: response.statusCode,
      );
    }

    final data = body['data'];
    final sessionJson = data is Map<String, Object?> ? data : body;
    try {
      return PaySharpPaymentSession.fromJson(sessionJson);
    } on FormatException catch (error) {
      throw PaySharpException(
        error.message,
        statusCode: response.statusCode,
        details: body,
        cause: error,
      );
    }
  }

  Uri _resolve(String path) =>
      _baseUri.resolve(path.replaceFirst(RegExp(r'^/+'), ''));

  static Uri _normalizeBaseUri(Uri uri) {
    if (!uri.hasScheme || uri.host.isEmpty || uri.scheme != 'https') {
      throw ArgumentError.value(
        uri,
        'baseUri',
        'must be an absolute HTTPS URI',
      );
    }
    return Uri.parse('${uri.toString().replaceFirst(RegExp(r'/+$'), '')}/');
  }

  static String _defaultStatusPath(String orderId) =>
      'payments/${Uri.encodeComponent(orderId)}';

  static String? _string(Map<String, Object?>? json, String key) {
    final value = json?[key];
    return value is String ? value : null;
  }
}
