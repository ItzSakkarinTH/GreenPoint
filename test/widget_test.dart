import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenpoint/main.dart';
import 'package:greenpoint/features/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that our app's title exists.
    expect(find.text('GreenPoint'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
