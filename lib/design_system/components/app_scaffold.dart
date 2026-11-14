import 'package:flutter/material.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final List<NavigationDestination>? destinations;
  final List<NavigationRailDestination>? railDestinations;
  final Widget? trailingRailWidget;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.selectedNavIndex = 0,
    this.onNavIndexChanged,
    this.destinations,
    this.railDestinations,
    this.trailingRailWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final colorScheme = context.colorScheme;

    // Compact layout (Phone): Bottom NavigationBar
    if (isCompact || destinations == null || destinations!.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor ?? colorScheme.surface,
        appBar: appBar,
        body: SafeArea(top: false, child: body),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: destinations != null && destinations!.isNotEmpty
            ? NavigationBar(
                selectedIndex: selectedNavIndex,
                onDestinationSelected: onNavIndexChanged,
                destinations: destinations!,
              )
            : null,
      );
    }

    // Medium & Expanded layout (Foldable / Tablet): NavigationRail + Body
    final defaultRailDestinations = destinations!.map((d) {
      return NavigationRailDestination(
        icon: d.icon,
        selectedIcon: d.selectedIcon,
        label: Text(d.label),
      );
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedNavIndex,
            onDestinationSelected: onNavIndexChanged,
            labelType: NavigationRailLabelType.all,
            destinations: railDestinations ?? defaultRailDestinations,
            trailing: trailingRailWidget != null
                ? Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: trailingRailWidget,
                      ),
                    ),
                  )
                : null,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: SafeArea(top: false, child: body)),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

