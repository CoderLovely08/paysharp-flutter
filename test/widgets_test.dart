import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paysharp_flutter/paysharp_flutter.dart';

void main() {
  testWidgets('payment button creates a session once', (tester) async {
    final backend = _WidgetBackend();
    final checkout = PaySharpCheckout(backend: backend);
    PaySharpPaymentSession? created;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PaySharpPaymentButton(
            checkout: checkout,
            request: _request(),
            launch: false,
            onCreated: (session) => created = session,
            child: const Text('Pay now'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pay now'));
    await tester.pumpAndSettle();

    expect(backend.createCalls, 1);
    expect(created?.orderId, 'ORDER-1');
  });

  testWidgets('payment button reports backend errors', (tester) async {
    final expected = StateError('backend unavailable');
    Object? reported;
    final checkout = PaySharpCheckout(backend: _WidgetBackend(error: expected));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PaySharpPaymentButton(
          checkout: checkout,
          request: _request(),
          launch: false,
          onError: (error, stackTrace) => reported = error,
          child: const Text('Pay now'),
        ),
      ),
    );

    await tester.tap(find.text('Pay now'));
    await tester.pumpAndSettle();
    expect(reported, same(expected));
  });

  testWidgets('QR image uses safe fallback for invalid payloads', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PaySharpQrImage(data: 'not-base64'),
      ),
    );

    expect(find.text('QR image unavailable'), findsOneWidget);
  });
}

PaySharpPaymentRequest _request() => PaySharpPaymentRequest(
  orderId: 'ORDER-1',
  amount: 500,
  customerId: 'CUSTOMER-1',
  customerMobileNumber: '9111100000',
  remarks: 'Invoice ORDER-1',
);

final class _WidgetBackend implements PaySharpBackend {
  _WidgetBackend({this.error});

  final Object? error;
  int createCalls = 0;

  @override
  Future<PaySharpPaymentSession> createPayment(
    PaySharpPaymentRequest request,
  ) async {
    createCalls += 1;
    if (error case final error?) throw error;
    return const PaySharpPaymentSession(
      orderId: 'ORDER-1',
      status: PaySharpPaymentStatus.pending,
    );
  }

  @override
  Future<PaySharpPaymentSession> getPayment(String orderId) async =>
      const PaySharpPaymentSession(
        orderId: 'ORDER-1',
        status: PaySharpPaymentStatus.pending,
      );
}
