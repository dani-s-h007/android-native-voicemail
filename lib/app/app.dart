import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/app/config/app_config.dart';
import 'package:voicemail/app/router/app_router.dart';
import 'package:voicemail/design_system/theme/app_theme.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final useDynamicColorProvider = StateProvider<bool>((ref) => true);

class VaniVoicemailApp extends ConsumerWidget {
  final bool isOnboardingCompleted;

  const VaniVoicemailApp({
    super.key,
    required this.isOnboardingCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final useDynamicColor = ref.watch(useDynamicColorProvider);
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightTheme = AppTheme.light(
          dynamicColorScheme: useDynamicColor ? lightDynamic : null,
        );
        final darkTheme = AppTheme.dark(
          dynamicColorScheme: useDynamicColor ? darkDynamic : null,
        );

        return MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
