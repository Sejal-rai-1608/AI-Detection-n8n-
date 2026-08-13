// This is a basic Flutter widget test for TruthTraceApp.
import 'package:flutter_test/flutter_test.dart';
import 'package:n8ntrial/main.dart';

void main() {
  testWidgets('TruthTrace load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TruthTraceApp());

    // Verify that our app main title loads.
    expect(find.text('TRUTHTRACE'), findsOneWidget);
  });
}
