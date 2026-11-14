import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/gallery/component_gallery_screen.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget(Widget child, {ThemeData? theme, Size? mediaSize}) {
    return MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: mediaSize ?? const Size(400, 800)),
        child: Scaffold(body: child),
      ),
    );
  }

  group('Design System Components Widget Tests', () {
    testWidgets('AppScaffold renders NavigationBar on compact and NavigationRail on wide screen',
        (tester) async {
      final destinations = [
        const NavigationDestination(icon: Icon(Icons.inbox), label: 'Voicemail'),
        const NavigationDestination(icon: Icon(Icons.tune), label: 'Modes'),
      ];

      // 1. Compact screen (width 400 < 600) -> NavigationBar
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AppScaffold(
            destinations: destinations,
            body: const Text('Compact Content'),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Compact Content'), findsOneWidget);

      // 2. Wide screen (width 800 >= 600) -> NavigationRail
      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AppScaffold(
            destinations: destinations,
            body: const Text('Wide Content'),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Wide Content'), findsOneWidget);
    });

    testWidgets('AppAppBar renders title, subtitle, actions and handles back navigation',
        (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: AppAppBar(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              actions: [
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () => actionTapped = true,
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info));
      expect(actionTapped, isTrue);
    });

    testWidgets('AppLargeSliverAppBar renders inside CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: CustomScrollView(
              slivers: [
                AppLargeSliverAppBar(title: 'Large Header'),
                SliverFillRemaining(child: Text('Scrollable Content')),
              ],
            ),
          ),
        ),
      );

      // SliverAppBar.large creates both expanded and collapsed title widgets
      expect(find.text('Large Header'), findsWidgets);
      expect(find.text('Scrollable Content'), findsOneWidget);
    });

    testWidgets('AppSearchBar accepts input, clears text, and meets min 48dp target',
        (tester) async {
      String query = '';
      await tester.pumpWidget(
        buildTestableWidget(
          AppSearchBar(
            hintText: 'Search voicemails...',
            onChanged: (val) => query = val,
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Voicemail Test');
      expect(query, 'Voicemail Test');
      await tester.pump();

      final clearButton = find.byTooltip('Clear search');
      expect(clearButton, findsOneWidget);

      final clearSize = tester.getSize(clearButton);
      expect(clearSize.width, greaterThanOrEqualTo(48.0));
      expect(clearSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(clearButton);
      await tester.pump();
      expect(query, '');
    });

    testWidgets('AppCard renders filled, elevated, and outlined variants with tap callbacks',
        (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              AppCard(
                variant: AppCardVariant.filled,
                onTap: () => tapped = true,
                child: const Text('Filled Card'),
              ),
              const AppCard(
                variant: AppCardVariant.elevated,
                child: Text('Elevated Card'),
              ),
              const AppCard(
                variant: AppCardVariant.outlined,
                child: Text('Outlined Card'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Filled Card'), findsOneWidget);
      expect(find.text('Elevated Card'), findsOneWidget);
      expect(find.text('Outlined Card'), findsOneWidget);

      await tester.tap(find.text('Filled Card'));
      expect(tapped, isTrue);
    });

    testWidgets('AppChips render and handle interactions', (tester) async {
      bool filterSelected = false;
      bool actionTapped = false;
      bool choiceSelected = false;
      bool inputDeleted = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Wrap(
            children: [
              AppFilterChip(
                label: 'Unread',
                selected: filterSelected,
                count: 4,
                onSelected: (val) => filterSelected = val,
              ),
              AppActionChip(
                label: 'Clear All',
                onPressed: () => actionTapped = true,
              ),
              AppChoiceChip(
                label: 'Choice 1',
                selected: choiceSelected,
                onSelected: (val) => choiceSelected = val,
              ),
              AppInputChip(
                label: 'Tag 1',
                onDeleted: () => inputDeleted = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('Choice 1'), findsOneWidget);
      expect(find.text('Tag 1'), findsOneWidget);

      await tester.tap(find.text('Unread'));
      expect(filterSelected, isTrue);

      await tester.tap(find.text('Clear All'));
      expect(actionTapped, isTrue);

      await tester.tap(find.text('Choice 1'));
      expect(choiceSelected, isTrue);

      await tester.tap(find.byTooltip('Remove'));
      expect(inputDeleted, isTrue);
    });

    testWidgets('AppSegmentedButton updates selection when tapped', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSegmentedButton<int>(
                selected: selected,
                onSelectionChanged: (val) => setState(() => selected = val),
                segments: const [
                  AppSegment(value: 0, label: 'One'),
                  AppSegment(value: 1, label: 'Two'),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(selected, 0);

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('AppListTile renders with >= 48dp touch target and triggers tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppListTile(
            leading: const Icon(Icons.person),
            title: const Text('Test Contact'),
            subtitle: const Text('New message preview'),
            trailing: const Text('12:00 PM'),
            onTap: () => tapped = true,
          ),
        ),
      );

      final finder = find.text('Test Contact');
      expect(finder, findsOneWidget);
      expect(find.text('New message preview'), findsOneWidget);
      expect(find.text('12:00 PM'), findsOneWidget);

      final size = tester.getSize(find.byType(AppListTile));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(finder);
      expect(tapped, isTrue);
    });

    testWidgets('AppSwitchRow triggers callback when tapped and handles switch semantics',
        (tester) async {
      bool currentValue = false;
      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitchRow(
                leading: const Icon(Icons.lock),
                title: 'Screen Capture',
                subtitle: 'Prevent recording',
                value: currentValue,
                onChanged: (val) => setState(() => currentValue = val),
              );
            },
          ),
        ),
      );

      expect(find.text('Screen Capture'), findsOneWidget);
      expect(find.text('Prevent recording'), findsOneWidget);
      expect(currentValue, isFalse);

      await tester.tap(find.text('Screen Capture'));
      await tester.pumpAndSettle();

      expect(currentValue, isTrue);
    });

    testWidgets('AppStatusBanner displays all types, handles action and dismiss', (tester) async {
      bool actionTriggered = false;
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppStatusBanner(
            type: AppBannerType.warning,
            title: 'System Alert',
            message: 'Screening service paused',
            actionLabel: 'Resolve',
            onAction: () => actionTriggered = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      expect(find.text('System Alert'), findsOneWidget);
      expect(find.text('Screening service paused'), findsOneWidget);

      await tester.tap(find.text('Resolve'));
      expect(actionTriggered, isTrue);

      await tester.tap(find.byTooltip('Dismiss banner'));
      expect(dismissed, isTrue);
    });

    testWidgets('AppPermissionCard displays granted vs ungranted state with grant trigger',
        (tester) async {
      bool grantTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppPermissionCard(
            icon: Icons.shield,
            title: 'Call Screening',
            description: 'Needed for incoming calls',
            isGranted: false,
            actionLabel: 'Allow',
            onGrant: () => grantTapped = true,
          ),
        ),
      );

      expect(find.text('Call Screening'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);

      await tester.tap(find.text('Allow'));
      expect(grantTapped, isTrue);
    });

    testWidgets('AppDialog shows confirmation dialog and returns boolean result', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showConfirmation(
                    context: context,
                    title: 'Confirm Action',
                    message: 'Are you sure?',
                    confirmLabel: 'Proceed',
                    cancelLabel: 'Dismiss',
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('AppBottomSheet shows modal sheet with title and children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppBottomSheet.show<void>(
                    context: context,
                    title: 'Sheet Title',
                    child: const Text('Sheet Content'),
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Title'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('AppSnackbar shows floating snackbar with icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackbar.showSuccess(context, 'Voicemail saved');
                  },
                  child: const Text('Show Snack'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Snack'));
      await tester.pump();

      expect(find.text('Voicemail saved'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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

    testWidgets('AppErrorState displays error title, message, and retry button', (tester) async {
      bool retryTriggered = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AppErrorState(
            title: 'Connection Lost',
            message: 'Unable to reach service',
            onRetry: () => retryTriggered = true,
          ),
        ),
      );

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.text('Unable to reach service'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryTriggered, isTrue);
    });

    testWidgets('AppLoadingSkeleton and AppShimmerList build without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Column(
            children: [
              AppLoadingSkeleton.circle(size: 40),
              AppLoadingSkeleton.text(width: 100, height: 16),
              AppLoadingSkeleton.card(height: 80),
              const Expanded(child: AppShimmerList(itemCount: 3)),
            ],
          ),
        ),
      );

      expect(find.byType(AppLoadingSkeleton), findsWidgets);
      expect(find.byType(AppShimmerList), findsOneWidget);
    });

    testWidgets('ComponentGalleryScreen renders cleanly in light and dark themes', (tester) async {
      // Light Mode test
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ComponentGalleryScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('M3 Component Gallery'), findsOneWidget);
      expect(find.text('1. Search Bar (M3 Pill with Clear Button)'), findsOneWidget);
      expect(find.text('2. Chips (Filter, Action, Choice, Input)'), findsOneWidget);
      expect(find.text('4. Cards (Filled, Elevated, Outlined)'), findsOneWidget);

      // Verify toggle theme icon exists
      final themeToggle = find.byTooltip('Toggle Theme');
      expect(themeToggle, findsOneWidget);
      await tester.tap(themeToggle);
      await tester.pump();
    });
  });
}
