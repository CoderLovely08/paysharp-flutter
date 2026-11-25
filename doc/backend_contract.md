# Merchant backend contract

The Flutter application communicates only with a merchant-controlled HTTPS backend. The backend authenticates the app user, validates the order, calls PaySharp using server-side credentials, stores webhook results, and returns a minimal response to the app.

Paths shown below are defaults and can be configured in `HttpPaySharpBackend`.

## Create payment

```http
POST /payments
content-type: application/json
authorization: Bearer <application-session-token>
```

```json
{
  "orderId": "ORDER-1001",
  "amount": 500,
  "customerId": "CUSTOMER-7",
  "customerMobileNo": "9111100000",
  "customerName": "Ram",
  "customerEmail": "ram@example.com",
  "remarks": "Invoice ORDER-1001",
  "mode": "intent"
}
```

Supported `mode` values are `intent`, `qr_code`, `offline_dynamic_qr`, and `collect`. A collect request also contains `customerVPA`.

The backend must derive or verify the amount and order ownership from trusted server-side data. It must not accept an arbitrary amount merely because the app sent it.

## Retrieve payment

```http
GET /payments/{orderId}
authorization: Bearer <application-session-token>
```

The backend must confirm that the authenticated user may access the order.

## Successful response

The adapter accepts a direct object or a `{ "data": { ... } }` envelope:

```json
{
  "data": {
    "orderId": "ORDER-1001",
    "amount": 500,
    "status": "PENDING",
    "paysharpReferenceNo": "upi_reference",
    "intentUrl": "upi://pay?...",
    "phonepeUrl": "phonepe://pay?...",
    "gpayUrl": "tez://upi/pay?...",
    "qrCode": null,
    "failureCode": null,
    "failureReason": null,
    "transactionDate": null
  }
}
```

PaySharp status values currently handled are `PENDING`, `ON PROGRESS`, `SUCCESS`, `FAILED`, and `EXPIRED`. Future values are preserved as `PaySharpPaymentStatus.unknown` and remain non-terminal.

## Error response

```json
{
  "message": "Order not found",
  "errorCode": "ORDER_NOT_FOUND"
}
```

The adapter exposes the HTTP status, error code, message, and response details through `PaySharpException`.

## Backend requirements

- Keep PaySharp tokens and merchant URLs in server-side secret storage.
- Authenticate and authorize every mobile request.
- Generate or validate amounts from server-side order data.
- Make order creation idempotent.
- Treat PaySharp webhooks or server-to-server status checks as authoritative.
- Verify current webhook security requirements directly with PaySharp.
- Redact credentials, VPA values, bank data, and customer information from logs.
- Rate-limit create and status endpoints.
- Return only fields required by the app.
