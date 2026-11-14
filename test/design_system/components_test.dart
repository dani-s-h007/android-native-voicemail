import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  group('Design System Components Widget Tests', () {
    testWidgets('AppSearchBar accepts input and clears text', (tester) async {
      String query = '';
      await tester.pumpWidget(
        buildTestableWidget(
          AppSearchBar(
            onChanged: (val) => query = val,
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Danish');
      expect(query, 'Danish');
      await tester.pump();

      // Clear button should appear when text is present
      final clearButton = find.byTooltip('Clear search');
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump();
      expect(query, '');
    });

    testWidgets('AppListTile renders with minimum 48dp touch target and triggers tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppListTile(
            title: const Text('Test Caller'),
            subtitle: const Text('New message'),
            onTap: () => tapped = true,
          ),
        ),
      );

      final finder = find.text('Test Caller');
      expect(finder, findsOneWidget);

      final size = tester.getSize(find.byType(AppListTile));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(finder);
      expect(tapped, isTrue);
    });

    testWidgets('AppSwitchRow triggers callback when tapped', (tester) async {
      bool currentValue = false;
      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitchRow(
                title: 'Screen Capture',
                value: currentValue,
                onChanged: (val) => setState(() => currentValue = val),
              );
            },
          ),
        ),
      );

      expect(find.text('Screen Capture'), findsOneWidget);
      expect(currentValue, isFalse);

      await tester.tap(find.text('Screen Capture'));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('AppStatusBanner displays title and triggers action', (tester) async {
      bool fixed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppStatusBanner(
            type: AppBannerType.warning,
            title: 'Battery Optimization',
            message: 'May cause delays',
            actionLabel: 'Fix',
            onAction: () => fixed = true,
          ),
        ),
      );

      expect(find.text('Battery Optimization'), findsOneWidget);
      expect(find.text('May cause delays'), findsOneWidget);

      await tester.tap(find.text('Fix'));
      expect(fixed, isTrue);
    });

    testWidgets('AppEmptyState displays content and triggers action button', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppEmptyState(
            icon: Icons.inbox,
            title: 'No Voicemails Yet',
            description: 'Calls will appear here',
            actionLabel: 'Refresh',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Voicemails Yet'), findsOneWidget);
      expect(find.text('Calls will appear here'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionTriggered, isTrue);
    });
  });
}

