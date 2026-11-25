import 'package:flutter_test/flutter_test.dart';
import 'package:paysharp_flutter/paysharp_flutter.dart';

void main() {
  final request = PaySharpPaymentRequest(
    orderId: 'ORDER-1',
    amount: 500,
    customerId: 'CUSTOMER-1',
    customerMobileNumber: '9111100000',
    remarks: 'Invoice ORDER-1',
  );

  test('creates and launches a payment', () async {
    Uri? launched;
    final backend = _FakeBackend(<PaySharpPaymentSession>[
      _session(
        PaySharpPaymentStatus.pending,
        intentUri: Uri.parse('upi://pay?pa=merchant@bank'),
      ),
    ]);
    final checkout = PaySharpCheckout(
      backend: backend,
      launcher: PaySharpUpiLauncher(
        launchUri: (uri) async {
          launched = uri;
          return true;
        },
      ),
    );

    final session = await checkout.createPayment(request, launch: true);

    expect(session.status, PaySharpPaymentStatus.pending);
    expect(launched?.scheme, 'upi');
    expect(backend.created, same(request));
  });

  test('selects a preferred app URI with generic fallback', () async {
    Uri? launched;
    final launcher = PaySharpUpiLauncher(
      launchUri: (uri) async {
        launched = uri;
        return true;
      },
    );
    final session = _session(
      PaySharpPaymentStatus.pending,
      intentUri: Uri.parse('upi://generic'),
      googlePayUri: Uri.parse('tez://specific'),
    );

    await launcher.launch(session, app: PaySharpUpiApp.googlePay);
    expect(launched, Uri.parse('tez://specific'));

    await launcher.launch(session, app: PaySharpUpiApp.phonePe);
    expect(launched, Uri.parse('upi://generic'));
  });

  test('throws when no application can open an intent', () async {
    final launcher = PaySharpUpiLauncher(launchUri: (_) async => false);
    await expectLater(
      launcher.launch(
        _session(
          PaySharpPaymentStatus.pending,
          intentUri: Uri.parse('upi://pay'),
        ),
      ),
      throwsA(isA<PaySharpException>()),
    );
  });

  test('polls until a terminal payment status', () async {
    final updates = <PaySharpPaymentStatus>[];
    final checkout = PaySharpCheckout(
      backend: _FakeBackend(<PaySharpPaymentSession>[
        _session(PaySharpPaymentStatus.pending),
        _session(PaySharpPaymentStatus.onProgress),
        _session(PaySharpPaymentStatus.success),
      ]),
    );

    final result = await checkout.pollUntilTerminal(
      'ORDER-1',
      interval: const Duration(microseconds: 1),
      timeout: const Duration(seconds: 1),
      onUpdate: (session) => updates.add(session.status),
    );

    expect(result.status, PaySharpPaymentStatus.success);
    expect(updates, <PaySharpPaymentStatus>[
      PaySharpPaymentStatus.pending,
      PaySharpPaymentStatus.onProgress,
      PaySharpPaymentStatus.success,
    ]);
  });

  test('honors polling cancellation before a request', () async {
    final token = PaySharpCancellationToken()..cancel();
    final backend = _FakeBackend(<PaySharpPaymentSession>[
      _session(PaySharpPaymentStatus.pending),
    ]);
    final checkout = PaySharpCheckout(backend: backend);

    await expectLater(
      checkout.pollUntilTerminal('ORDER-1', cancellationToken: token),
      throwsA(isA<PaySharpPollingCancelledException>()),
    );
    expect(backend.statusRequests, 0);
  });
}

PaySharpPaymentSession _session(
  PaySharpPaymentStatus status, {
  Uri? intentUri,
  Uri? phonePeUri,
  Uri? googlePayUri,
}) => PaySharpPaymentSession(
  orderId: 'ORDER-1',
  status: status,
  intentUri: intentUri,
  phonePeUri: phonePeUri,
  googlePayUri: googlePayUri,
);

final class _FakeBackend implements PaySharpBackend {
  _FakeBackend(this.sessions);

  final List<PaySharpPaymentSession> sessions;
  PaySharpPaymentRequest? created;
  int statusRequests = 0;

  @override
  Future<PaySharpPaymentSession> createPayment(
    PaySharpPaymentRequest request,
  ) async {
    created = request;
    return sessions.first;
  }

  @override
  Future<PaySharpPaymentSession> getPayment(String orderId) async {
    final index = statusRequests.clamp(0, sessions.length - 1);
    statusRequests += 1;
    return sessions[index];
  }
}
