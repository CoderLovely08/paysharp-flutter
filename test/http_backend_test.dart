import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paysharp_flutter/paysharp_flutter.dart';

void main() {
  test('creates a payment through the merchant backend', () async {
    late http.Request captured;
    final backend = HttpPaySharpBackend(
      baseUri: Uri.parse('https://merchant.example/api/'),
      headersProvider: () => <String, String>{
        'authorization': 'Bearer app-session',
      },
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'orderId': 'ORDER-1',
              'status': 'PENDING',
              'intentUrl': 'upi://pay?pa=merchant@bank',
            },
          }),
          200,
        );
      }),
    );

    final session = await backend.createPayment(
      PaySharpPaymentRequest(
        orderId: 'ORDER-1',
        amount: 500,
        customerId: 'CUSTOMER-1',
        customerMobileNumber: '9111100000',
        remarks: 'Invoice ORDER-1',
      ),
    );

    expect(captured.method, 'POST');
    expect(captured.url.toString(), 'https://merchant.example/api/payments');
    expect(captured.headers['authorization'], 'Bearer app-session');
    expect(jsonDecode(captured.body), containsPair('orderId', 'ORDER-1'));
    expect(session.status, PaySharpPaymentStatus.pending);
  });

  test('URL-encodes status identifiers', () async {
    late Uri captured;
    final backend = HttpPaySharpBackend(
      baseUri: Uri.parse('https://merchant.example/api'),
      client: MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode(<String, Object?>{
            'orderId': 'ORDER/1',
            'status': 'SUCCESS',
          }),
          200,
        );
      }),
    );

    await backend.getPayment('ORDER/1');
    expect(
      captured.toString(),
      'https://merchant.example/api/payments/ORDER%2F1',
    );
  });

  test('throws structured backend errors', () async {
    final backend = HttpPaySharpBackend(
      baseUri: Uri.parse('https://merchant.example'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'message': 'Order not found',
            'errorCode': 'ORDER_NOT_FOUND',
          }),
          404,
        ),
      ),
    );

    expect(
      () => backend.getPayment('missing'),
      throwsA(
        isA<PaySharpException>()
            .having((error) => error.statusCode, 'statusCode', 404)
            .having((error) => error.code, 'code', 'ORDER_NOT_FOUND'),
      ),
    );
  });

  test('requires an HTTPS merchant backend', () {
    expect(
      () => HttpPaySharpBackend(baseUri: Uri.parse('http://merchant.example')),
      throwsArgumentError,
    );
  });
}
