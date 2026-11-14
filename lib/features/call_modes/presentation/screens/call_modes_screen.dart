import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/reliability/reliability_service.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/call_modes/domain/call_mode.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/auto_messaging_controller.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/modes_controller.dart';
import 'package:voicemail/features/call_modes/presentation/screens/dnd_schedule_sheet.dart';

class CallModesScreen extends ConsumerWidget {
  const CallModesScreen({super.key});

  Future<void> _handleModeChange(
    BuildContext context,
    WidgetRef ref,
    CallHandlingMode mode,
  ) async {
    final controller = ref.read(modesControllerProvider.notifier);

    if (mode == CallHandlingMode.autoAnswer) {
      final isDefault = await ReliabilityService.isDefaultDialer();
      if (!isDefault && context.mounted) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.voicemail_rounded, size: 40, color: Colors.deepPurple),
            title: const Text('Enable On-Device Live Voicemail'),
            content: const Text(
              'Just like iPhone iOS 17 Live Voicemail, this enables your phone to automatically pick up incoming calls locally, '
              'speak your greeting ("Hi, Danish here..."), and record the caller without any carrier forwarding or cloud charges.\n\n'
              'Android requires setting this app as your Phone / Assistant to allow local answering.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enable & Set Role'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          await ReliabilityService.requestDefaultDialerRole();
        }
      }
    }

    controller.setMode(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modesControllerProvider);
    final autoMsgState = ref.watch(autoMessagingControllerProvider);
    final controller = ref.read(modesControllerProvider.notifier);
    final colorScheme = context.colorScheme;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Call Handling & DND',
        subtitle: 'Assistant Intelligence Modes',
        showBackButton: false,
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // 1. Large Status Hero Card
          AppCard(
            variant: AppCardVariant.filled,
            color: state.isAssistantActive
                ? (state.isDndActive ? Colors.deepPurple.shade50 : colorScheme.primaryContainer)
                : colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  state.isAssistantActive
                      ? (state.isDndActive ? Icons.do_not_disturb_on : Icons.verified_user)
                      : Icons.pause_circle_outline,
                  size: 40,
                  color: state.isAssistantActive
                      ? (state.isDndActive ? Colors.deepPurple : colorScheme.onPrimaryContainer)
                      : colorScheme.outline,
                ),
                AppSpacing.hSpace16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.statusTitle,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: state.isAssistantActive
                              ? (state.isDndActive ? Colors.deepPurple.shade900 : colorScheme.onPrimaryContainer)
                              : colorScheme.onSurface,
                        ),
                      ),
                      AppSpacing.vSpace4,
                      Text(
                        state.isAssistantActive
                            ? 'Incoming calls are screened according to your selected mode.'
                            : 'Assistant is paused. Calls ring through normally to Google Phone.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: state.isAssistantActive
                              ? (state.isDndActive ? Colors.deepPurple.shade800 : colorScheme.onPrimaryContainer)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.isAssistantActive,
                  onChanged: (val) => controller.toggleAssistant(val),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // 2. Quick DND Button
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(
                    state.dndUntil != null ? 'Adjust DND Schedule' : 'Schedule DND / College Hours',
                  ),
                  onPressed: () {
                    AppBottomSheet.show(
                      context: context,
                      child: const DndScheduleSheet(),
                    );
                  },
                ),
              ),
            ],
          ),
          AppSpacing.vSpace20,

          // 3. Mode Selector Cards
          Text(
            'SELECT CALL HANDLING MODE',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace12,

          ...CallHandlingMode.values.map((mode) {
            final isSelected = state.currentMode == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: AppCard(
                variant: isSelected ? AppCardVariant.filled : AppCardVariant.outlined,
                color: isSelected ? colorScheme.secondaryContainer.withValues(alpha: 0.4) : null,
                borderSide: isSelected
                    ? BorderSide(color: colorScheme.primary, width: 1.8)
                    : BorderSide(color: colorScheme.outlineVariant),
                onTap: () => _handleModeChange(context, ref, mode),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<CallHandlingMode>(
                      value: mode,
                      groupValue: state.currentMode,
                      onChanged: (val) {
                        if (val != null) _handleModeChange(context, ref, val);
                      },
                    ),
                    AppSpacing.hSpace8,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mode.title,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.hSpace8,
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mode.badgeText,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vSpace4,
                          Text(
                            mode.subtitle,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.vSpace6,
                          Row(
                            children: [
                              Icon(Icons.bolt, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Credit cost: ${mode.costDescription}',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (mode == CallHandlingMode.autoDecline) ...[
                            AppSpacing.vSpace10,
                            InkWell(
                              onTap: () => context.push('/auto-messaging'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colorScheme.outlineVariant),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.tune_rounded, size: 16, color: colorScheme.primary),
                                    AppSpacing.hSpace8,
                                    Expanded(
                                      child: Text(
                                        'Configure Auto-Reply (${autoMsgState.targetMode.title})',
                                        style: context.textTheme.labelMedium?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 12, color: colorScheme.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.vSpace16,

          // 4. Exceptions Hub (Always Ring Through)
          Text(
            'EXCEPTIONS & BYPASS RULES',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace12,

          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              children: [
                AppSwitchRow(
                  leading: const Icon(Icons.star_rounded, color: Colors.amber),
                  title: 'Starred Contacts',
                  subtitle: 'Family & VIP contacts bypass DND and always ring',
                  value: state.exceptions.allowStarredContacts,
                  onChanged: (val) => controller.updateExceptions(allowStarred: val),
                ),
                const Divider(),
                AppSwitchRow(
                  leading: const Icon(Icons.repeat_rounded, color: Colors.blue),
                  title: 'Repeat Callers',
                  subtitle: 'If someone calls a second time within 3 minutes',
                  value: state.exceptions.allowRepeatCallers,
                  onChanged: (val) => controller.updateExceptions(allowRepeatCallers: val),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_outlined, color: Colors.red),
                      AppSpacing.hSpace16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Numbers (112, 100, 108, 101)',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.vSpace2,
                            Text(
                              'National emergency services are never blocked or screened.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'LOCKED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace24,
        ],
      ),
    );
  }
}
