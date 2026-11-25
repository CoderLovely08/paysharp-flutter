import 'package:flutter/widgets.dart';
import 'package:paysharp_flutter/paysharp_flutter.dart';

void main() => runApp(const PaySharpExampleApp());

/// Minimal checkout example using a merchant-controlled backend.
class PaySharpExampleApp extends StatefulWidget {
  /// Creates the example application.
  const PaySharpExampleApp({super.key});

  @override
  State<PaySharpExampleApp> createState() => _PaySharpExampleAppState();
}

class _PaySharpExampleAppState extends State<PaySharpExampleApp> {
  late final PaySharpCheckout checkout = PaySharpCheckout(
    backend: HttpPaySharpBackend(
      baseUri: Uri.parse('https://api.example.com/mobile/paysharp/'),
      headersProvider: () => <String, String>{
        // Replace with a short-lived token for your own merchant backend.
        'authorization': 'Bearer application-session-token',
      },
    ),
  );

  String status = 'Ready';

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFF1565C0),
    builder: (context, child) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(status),
          const SizedBox(height: 16),
          PaySharpPaymentButton(
            checkout: checkout,
            request: PaySharpPaymentRequest(
              orderId: 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
              amount: 500,
              customerId: 'CUSTOMER-7',
              customerName: 'Ram',
              customerMobileNumber: '9111100000',
              remarks: 'Mobile checkout',
            ),
            onCreated: (session) => setState(
              () =>
                  status = 'Created ${session.orderId}: ${session.status.name}',
            ),
            onError: (error, stackTrace) =>
                setState(() => status = 'Payment failed: $error'),
            child: const Text('Pay with UPI'),
          ),
        ],
      ),
    ),
  );
}
