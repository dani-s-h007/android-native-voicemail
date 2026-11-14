import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemail/app/router/app_nav_shell.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/design_system/gallery/component_gallery_screen.dart';
import 'package:voicemail/features/about/presentation/screens/about_screen.dart';
import 'package:voicemail/features/call_modes/presentation/screens/auto_messaging_screen.dart';
import 'package:voicemail/features/call_modes/presentation/screens/call_modes_screen.dart';
import 'package:voicemail/features/diagnostics/presentation/screens/call_diagnostics_screen.dart';
import 'package:voicemail/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:voicemail/features/greetings/presentation/screens/greetings_screen.dart';
import 'package:voicemail/features/legal/presentation/screens/legal_document_screen.dart';
import 'package:voicemail/features/legal/presentation/screens/legal_hub_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/consent_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/permission_rationale_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/setup_wizard_screen.dart';
import 'package:voicemail/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:voicemail/features/reliability/presentation/screens/reliability_check_screen.dart';
import 'package:voicemail/features/settings/presentation/screens/region_carrier_screen.dart';
import 'package:voicemail/features/settings/presentation/settings_screen.dart';
import 'package:voicemail/features/voicemail/presentation/screens/voicemail_detail_screen.dart';
import 'package:voicemail/features/voicemail/presentation/screens/voicemail_inbox_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorVoicemail = GlobalKey<NavigatorState>();
final _shellNavigatorModes = GlobalKey<NavigatorState>();
final _shellNavigatorGreetings = GlobalKey<NavigatorState>();
final _shellNavigatorSettings = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppConstants.routeSplash,
    debugLogDiagnostics: false,
    routes: [
      // Splash Route
      GoRoute(
        path: AppConstants.routeSplash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding & Setup Flow
      GoRoute(
        path: AppConstants.routeOnboarding,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppConstants.routeConsent,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: AppConstants.routePermissions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PermissionRationaleScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSetupWizard,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SetupWizardScreen(),
      ),

      // Design System Gallery
      GoRoute(
        path: AppConstants.routeComponentGallery,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ComponentGalleryScreen(),
      ),

      // System Health & Reliability Check
      GoRoute(
        path: AppConstants.routeReliability,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReliabilityCheckScreen(),
      ),

      // Call Log Diagnostics
      GoRoute(
        path: AppConstants.routeDiagnostics,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CallDiagnosticsScreen(),
      ),

      // Region & Carrier Settings
      GoRoute(
        path: AppConstants.routeRegionCarrier,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegionCarrierScreen(),
      ),

      // About & Licenses
      GoRoute(
        path: AppConstants.routeAbout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),

      // Feedback & Support
      GoRoute(
        path: AppConstants.routeFeedback,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),

      // Smart Auto-Messaging & Select Numbers
      GoRoute(
        path: '/auto-messaging',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AutoMessagingScreen(),
      ),

      // Legal Hub & Markdown Documents
      GoRoute(
        path: '/legal',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LegalHubScreen(),
        routes: [
          GoRoute(
            path: ':document',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final doc = state.pathParameters['document'] ?? 'privacy';
              return LegalDocumentScreen(documentId: doc);
            },
          ),
        ],
      ),

      // 4-Tab Adaptive Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Voicemail Inbox
          StatefulShellBranch(
            navigatorKey: _shellNavigatorVoicemail,
            routes: [
              GoRoute(
                path: AppConstants.routeVoicemail,
                builder: (context, state) => const VoicemailInboxScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return VoicemailDetailScreen(voicemailId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Modes & DND
          StatefulShellBranch(
            navigatorKey: _shellNavigatorModes,
            routes: [
              GoRoute(
                path: AppConstants.routeModes,
                builder: (context, state) => const CallModesScreen(),
              ),
            ],
          ),

          // Tab 3: Greetings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorGreetings,
            routes: [
              GoRoute(
                path: AppConstants.routeGreetings,
                builder: (context, state) => const GreetingsScreen(),
              ),
            ],
          ),

          // Tab 4: Settings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettings,
            routes: [
              GoRoute(
                path: AppConstants.routeSettings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

