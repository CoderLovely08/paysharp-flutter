import 'package:flutter_test/flutter_test.dart';
import 'package:paysharp_flutter/paysharp_flutter.dart';

void main() {
  group('PaySharpPaymentRequest', () {
    test('serializes the merchant backend contract', () {
      final request = PaySharpPaymentRequest(
        orderId: 'ORDER-1',
        amount: 500,
        customerId: 'CUSTOMER-1',
        customerMobileNumber: '9111100000',
        remarks: 'Invoice ORDER-1',
        customerName: 'Ram',
        metadata: const <String, Object?>{'cartId': 'CART-1'},
      );

      expect(request.toJson(), <String, Object?>{
        'orderId': 'ORDER-1',
        'amount': 500,
        'customerId': 'CUSTOMER-1',
        'customerMobileNo': '9111100000',
        'remarks': 'Invoice ORDER-1',
        'mode': 'intent',
        'customerName': 'Ram',
        'metadata': const <String, Object?>{'cartId': 'CART-1'},
      });
    });

    test('validates documented constraints', () {
      expect(
        () => PaySharpPaymentRequest(
          orderId: 'ORDER-1',
          amount: 0,
          customerId: 'CUSTOMER-1',
          customerMobileNumber: '9111100000',
          remarks: 'Invoice',
        ),
        throwsArgumentError,
      );
      expect(
        () => PaySharpPaymentRequest(
          orderId: 'ORDER-1',
          amount: 1,
          customerId: 'CUSTOMER-1',
          customerMobileNumber: '123',
          remarks: 'Invoice',
        ),
        throwsArgumentError,
      );
    });

    test('requires a VPA for collect mode', () {
      expect(
        () => PaySharpPaymentRequest(
          orderId: 'ORDER-1',
          amount: 1,
          customerId: 'CUSTOMER-1',
          customerMobileNumber: '9111100000',
          remarks: 'Invoice',
          mode: PaySharpPaymentMode.collect,
        ),
        throwsArgumentError,
      );
    });
  });

  test('parses every documented payment status', () {
    expect(
      PaySharpPaymentStatus.fromWireValue('ON PROGRESS'),
      PaySharpPaymentStatus.onProgress,
    );
    expect(PaySharpPaymentStatus.fromWireValue('SUCCESS').isTerminal, isTrue);
    expect(
      PaySharpPaymentStatus.fromWireValue('FUTURE_STATUS'),
      PaySharpPaymentStatus.unknown,
    );
  });

  test('parses a forward-compatible payment session', () {
    final session = PaySharpPaymentSession.fromJson(<String, Object?>{
      'orderId': 'ORDER-1',
      'amount': 500,
      'status': 'SUCCESS',
      'paysharpReferenceNo': 'upi_reference',
      'intentUrl': 'upi://pay?pa=merchant@bank',
      'transactionDate': '2026-11-25T10:00:00+05:30',
      'futureField': true,
    });

    expect(session.status, PaySharpPaymentStatus.success);
    expect(session.intentUri?.scheme, 'upi');
    expect(session.raw['futureField'], isTrue);
  });
}
