# PaySharp Flutter

An unofficial Flutter checkout package for PaySharp UPI payments.

`paysharp_flutter` keeps PaySharp merchant credentials on your server. The app asks your merchant backend to create or inspect a payment, then launches the returned UPI URI or displays the returned QR image.

> **Security:** Never embed a PaySharp merchant API token or production API base URL in a Flutter application. Mobile binaries and network traffic can be inspected by users.

## Features

- Typed intent, QR, offline dynamic QR, and collect requests
- Validated PaySharp request limits
- Merchant-backend HTTP adapter with application-auth headers
- Generic UPI, Google Pay, and PhonePe intent launching
- Payment-status polling with timeouts and cancellation
- Base64 PaySharp QR image widget
- Customizable payment button with loading and error callbacks
- Structured backend errors and forward-compatible response models

## Install

```yaml
dependencies:
  paysharp_flutter: ^0.1.0
```

Until the first pub.dev release, use the Git repository:

```yaml
dependencies:
  paysharp_flutter:
    git:
      url: https://github.com/CoderLovely08/paysharp-flutter.git
```

## Architecture

```text
Flutter app ── app authentication ──> Merchant backend
                                           │
                                           │ PaySharp merchant token
                                           ▼
                                      PaySharp API
```

Your backend owns order authorization, idempotency, amount verification, PaySharp credentials, webhook processing, and final payment state. The Flutter app must never be the authority for whether an order is paid.

See the complete [merchant backend contract](doc/backend_contract.md).

## Configure

```dart
import 'package:paysharp_flutter/paysharp_flutter.dart';

final backend = HttpPaySharpBackend(
  baseUri: Uri.parse('https://api.example.com/mobile/paysharp/'),
  headersProvider: () async => {
    // This is your app-session token, not a PaySharp merchant token.
    'authorization': 'Bearer ${await loadAppSessionToken()}',
  },
);

final checkout = PaySharpCheckout(backend: backend);
```

By default the adapter uses:

- `POST /mobile/paysharp/payments` to create a payment
- `GET /mobile/paysharp/payments/{orderId}` to retrieve status

Both paths are configurable.

## Create and launch a payment

```dart
final session = await checkout.createPayment(
  PaySharpPaymentRequest(
    orderId: 'ORDER-1001',
    amount: 500,
    customerId: 'CUSTOMER-7',
    customerName: 'Ram',
    customerMobileNumber: '9111100000',
    customerEmail: 'ram@example.com',
    remarks: 'Invoice ORDER-1001',
  ),
  launch: true,
  app: PaySharpUpiApp.automatic,
);
```

Launching a UPI application does **not** prove payment success. Refresh the order from your backend after the user returns, or poll until the backend reports a terminal state:

```dart
final finalSession = await checkout.pollUntilTerminal(
  session.orderId,
  timeout: const Duration(minutes: 2),
  onUpdate: (update) => print(update.status),
);

if (finalSession.status == PaySharpPaymentStatus.success) {
  // Ask your backend for the fulfilled order; do not fulfill locally.
}
```

## Payment button

```dart
PaySharpPaymentButton(
  checkout: checkout,
  request: request,
  child: const Text('Pay with UPI'),
  onCreated: (session) => print(session.orderId),
  onError: (error, stackTrace) => reportPaymentError(error),
)
```

Pass `builder` to render your own design system button while the package manages loading and duplicate taps.

## QR payments

```dart
final session = await checkout.createPayment(
  PaySharpPaymentRequest(
    orderId: 'ORDER-1002',
    amount: 500,
    customerId: 'CUSTOMER-7',
    customerMobileNumber: '9111100000',
    remarks: 'Invoice ORDER-1002',
    mode: PaySharpPaymentMode.qrCode,
  ),
);

if (session.qrCode case final qr?) {
  PaySharpQrImage(data: qr);
}
```

## Error handling

```dart
try {
  await checkout.refresh('ORDER-1001');
} on PaySharpException catch (error) {
  print(error.statusCode);
  print(error.code);
  print(error.message);
}
```

## Supported platforms

The model, backend, polling, and QR APIs work anywhere supported by Flutter. UPI intent availability depends on the operating system, installed applications, and the URI returned by PaySharp. Test real payment handoff on physical Android and iOS devices.

## PaySharp documentation

- [UPI API](https://www.paysharp.in/developer/api/v1/upi/reference)
- [Offline dynamic QR API](https://www.paysharp.in/developer/api/v1/upi-dynamic-qr/reference)

## Disclaimer

This is an independent, unofficial open-source package. It is not affiliated with, endorsed by, or maintained by PaySharp Private Limited. “PaySharp” and related marks belong to their respective owner. Users must have their own authorized PaySharp merchant relationship and comply with PaySharp's current terms and documentation.
