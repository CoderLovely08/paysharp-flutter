# Security policy

## Reporting

Use GitHub private vulnerability reporting for suspected security issues. Do not open a public issue containing merchant tokens, customer data, production payloads, bank details, or exploitable instructions.

## Credential boundary

This package intentionally does not accept a PaySharp merchant token. Flutter applications are distributed to user-controlled devices, so embedded secrets cannot be protected reliably. All PaySharp API calls requiring merchant credentials must be made by a trusted merchant backend.

Application-session tokens supplied to `headersProvider` authenticate only against that merchant backend. Applications should use short-lived tokens and platform-appropriate secure storage.

## Payment authority

UPI application handoff and client-side callbacks are not proof of payment. Fulfilment decisions must use the merchant backend's authoritative state after webhook processing or a server-to-server status lookup.
