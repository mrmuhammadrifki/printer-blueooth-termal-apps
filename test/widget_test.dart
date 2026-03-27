// OrbitPrint widget tests

import 'package:flutter_test/flutter_test.dart';
import 'package:printer_bluetooth_server_app/main.dart';

void main() {
  testWidgets('OrbitPrint app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OrbitPrintApp());

    // Verify that the app title is present
    expect(find.text('OrbitPrint'), findsOneWidget);
  });
}
