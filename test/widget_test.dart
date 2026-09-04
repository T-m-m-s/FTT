import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/main.dart';
import 'package:ftt/services/database_service.dart';
import 'package:ftt/services/update_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    UpdateService.enableAutoCheck = false;
    await DatabaseService().init();
  });

  testWidgets('FreeTimeTracker smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FreeTimeTrackerApp());
    await tester.pump();

    // Verify Home tab is active and visible
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.sports_esports_rounded), findsWidgets);
    expect(find.byIcon(Icons.shelves), findsOneWidget);
    expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pie_chart_outline_rounded), findsOneWidget);

    // Switch to Library tab
    await tester.tap(find.byIcon(Icons.shelves));
    await tester.pumpAndSettle();
    expect(find.text('Library'), findsOneWidget);

    // Switch to Timeline tab
    await tester.tap(find.byIcon(Icons.timeline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Timeline'), findsOneWidget);
  });
}
