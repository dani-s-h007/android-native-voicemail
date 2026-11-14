import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemail/design_system/components/app_scaffold.dart';

class AppNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavShell({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedNavIndex: navigationShell.currentIndex,
      onNavIndexChanged: _onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.voicemail_outlined),
          selectedIcon: Icon(Icons.voicemail_rounded),
          label: 'Voicemail',
          tooltip: 'Voicemail Inbox',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: 'Modes',
          tooltip: 'Call Handling & DND',
        ),
        NavigationDestination(
          icon: Icon(Icons.record_voice_over_outlined),
          selectedIcon: Icon(Icons.record_voice_over_rounded),
          label: 'Greetings',
          tooltip: 'Custom Prompts',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
          tooltip: 'Settings & Diagnostics',
        ),
      ],
      body: navigationShell,
    );
  }
}

