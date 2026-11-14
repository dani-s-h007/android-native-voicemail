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
            title: const Text('Enable On-Device Assistant'),
            content: const Text(
              'Enables your device to answer incoming calls locally, play your greeting, '
              'and transcribe caller speech in real-time without carrier forwarding.\n\n'
              'Android requires setting this app as your Phone / Call Assistant role.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enable Role'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          await ReliabilityService.requestDefaultDialerRole();
        }
      }
    }

    await controller.setMode(mode);
  }

  void _showAddWhitelistDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Whitelist Number'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1 (555) 010-0000',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final number = textController.text.trim();
              if (number.isNotEmpty) {
                ref.read(modesControllerProvider.notifier).addWhitelistNumber(number);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomDndTime(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
    );
    if (time != null) {
      var target = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      await ref.read(modesControllerProvider.notifier).startDndUntil(target);
    }
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
                ? (state.isDndActive
                    ? colorScheme.tertiaryContainer.withValues(alpha: 0.6)
                    : colorScheme.primaryContainer)
                : colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isAssistantActive
                          ? (state.isDndActive ? Icons.do_not_disturb_on : Icons.verified_user)
                          : Icons.pause_circle_outline,
                      size: 36,
                      color: state.isAssistantActive
                          ? (state.isDndActive
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onPrimaryContainer)
                          : colorScheme.outline,
                    ),
                    AppSpacing.hSpace14,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.statusTitle,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: state.isAssistantActive
                                  ? (state.isDndActive
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onPrimaryContainer)
                                  : colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.vSpace2,
                          Text(
                            state.isAssistantActive
                                ? 'Calls are screened according to your active handling mode.'
                                : 'Assistant is paused. Calls ring through directly.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: state.isAssistantActive
                                  ? (state.isDndActive
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onPrimaryContainer)
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
                if (state.dndUntil != null && state.dndUntil!.isAfter(DateTime.now())) ...[
                  AppSpacing.vSpace12,
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active DND timer ends at ${state.dndUntil!.hour}:${state.dndUntil!.minute.toString().padLeft(2, '0')}',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cancel DND'),
                        onPressed: controller.cancelDnd,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // 2. Quick DND Timer Chips
          Text(
            'QUICK DND TIMER',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('30m'),
                  onPressed: () => controller.startDndForDuration(const Duration(minutes: 30)),
                ),
                AppSpacing.hSpace8,
                ActionChip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('1h'),
                  onPressed: () => controller.startDndForDuration(const Duration(hours: 1)),
                ),
                AppSpacing.hSpace8,
                ActionChip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('2h'),
                  onPressed: () => controller.startDndForDuration(const Duration(hours: 2)),
                ),
                AppSpacing.hSpace8,
                ActionChip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('4h'),
                  onPressed: () => controller.startDndForDuration(const Duration(hours: 4)),
                ),
                AppSpacing.hSpace8,
                ActionChip(
                  avatar: const Icon(Icons.bedtime_outlined, size: 18),
                  label: const Text('Until 08:00 AM'),
                  onPressed: () {
                    final now = DateTime.now();
                    var morning = DateTime(now.year, now.month, now.day, 8, 0);
                    if (now.hour >= 8) morning = morning.add(const Duration(days: 1));
                    controller.startDndUntil(morning);
                  },
                ),
                AppSpacing.hSpace8,
                ActionChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: const Text('Custom...'),
                  onPressed: () => _pickCustomDndTime(context, ref),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace12,
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Configure Recurring Focus Schedule'),
            onPressed: () {
              AppBottomSheet.show<void>(
                context: context,
                child: const DndScheduleSheet(),
              );
            },
          ),
          AppSpacing.vSpace20,

          // 3. Mode Selector Cards
          Text(
            'CALL HANDLING MODES',
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
                color: isSelected ? colorScheme.secondaryContainer.withValues(alpha: 0.35) : null,
                borderSide: isSelected
                    ? BorderSide(color: colorScheme.primary, width: 1.8)
                    : BorderSide(color: colorScheme.outlineVariant),
                onTap: () => _handleModeChange(context, ref, mode),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ignore: deprecated_member_use
                    Radio<CallHandlingMode>(
                      value: mode,
                      // ignore: deprecated_member_use
                      groupValue: state.currentMode,
                      // ignore: deprecated_member_use
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
                              Icon(Icons.shield_outlined, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                mode.costDescription,
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

          // 4. Exceptions & Whitelist Rules
          Text(
            'EXCEPTIONS & WHITELIST',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSwitchRow(
                  leading: const Icon(Icons.star_rounded, color: Colors.amber),
                  title: 'Starred Contacts',
                  subtitle: 'VIP & starred contacts bypass DND and always ring',
                  value: state.exceptions.allowStarredContacts,
                  onChanged: (val) => controller.updateExceptions(allowStarred: val),
                ),
                const Divider(),
                AppSwitchRow(
                  leading: const Icon(Icons.repeat_rounded, color: Colors.blue),
                  title: 'Repeated Callers Within 15 Min',
                  subtitle: 'Allows calls through if the caller dials a second time within 15 minutes',
                  value: state.exceptions.allowRepeatCallersWithin15Min,
                  onChanged: (val) => controller.updateExceptions(allowRepeatCallers: val),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Custom Whitelist Numbers',
                            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            onPressed: () => _showAddWhitelistDialog(context, ref),
                          ),
                        ],
                      ),
                      if (state.exceptions.whitelistNumbers.isEmpty) ...[
                        Text(
                          'No custom numbers added yet. Add numbers that should always ring.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ] else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: state.exceptions.whitelistNumbers.map((number) {
                            return Chip(
                              label: Text(number),
                              onDeleted: () => controller.removeWhitelistNumber(number),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
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
                              'Emergency Numbers (${state.exceptions.emergencyNumbers.join(', ')})',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.vSpace2,
                            Text(
                              'National emergency services are permanently exempt and never screened.',
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
