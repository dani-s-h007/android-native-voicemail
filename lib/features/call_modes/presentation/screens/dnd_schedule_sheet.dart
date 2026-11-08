import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/modes_controller.dart';

class DndScheduleSheet extends ConsumerWidget {
  const DndScheduleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modesControllerProvider);
    final controller = ref.read(modesControllerProvider.notifier);
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.do_not_disturb_on_rounded, color: colorScheme.primary, size: 28),
              AppSpacing.hSpace12,
              Text(
                'Do Not Disturb Hub',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.vSpace16,

          // Quick Start Options
          Text('Quick Silence (Lecture / Meeting)', style: context.textTheme.labelLarge),
          AppSpacing.vSpace8,
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: const Text('30 Mins'),
                onPressed: () {
                  controller.startDndForDuration(const Duration(minutes: 30));
                  Navigator.pop(context);
                  context.showSnackBar('DND active for 30 minutes');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: const Text('1 Hour'),
                onPressed: () {
                  controller.startDndForDuration(const Duration(hours: 1));
                  Navigator.pop(context);
                  context.showSnackBar('DND active for 1 hour');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: const Text('2 Hours'),
                onPressed: () {
                  controller.startDndForDuration(const Duration(hours: 2));
                  Navigator.pop(context);
                  context.showSnackBar('DND active for 2 hours (Class mode)');
                },
              ),
              if (state.dndUntil != null) ...[
                ActionChip(
                  avatar: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('Cancel DND', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    controller.cancelDnd();
                    Navigator.pop(context);
                    context.showSnackBar('DND timer cancelled');
                  },
                ),
              ],
            ],
          ),
          AppSpacing.vSpace20,

          // Recurring College / Class Schedule
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 20),
                        AppSpacing.hSpace8,
                        Text(
                          'College / Class Routine',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: state.dndSchedule.isEnabled,
                      onChanged: (val) {
                        controller.updateSchedule(
                          state.dndSchedule.copyWith(isEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
                AppSpacing.vSpace4,
                Text(
                  'Monday to Friday • 9:00 AM – 4:00 PM',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vSpace8,
                Text(
                  'Automatically declines non-essential callers with your custom greeting: "Hi, Danish here. In class right now."',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,
        ],
      ),
    );
  }
}

