import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/call_modes/domain/auto_reply_rules.dart';
import 'package:voicemail/features/call_modes/presentation/controllers/auto_messaging_controller.dart';

class AutoMessagingScreen extends ConsumerStatefulWidget {
  const AutoMessagingScreen({super.key});

  @override
  ConsumerState<AutoMessagingScreen> createState() => _AutoMessagingScreenState();
}

class _AutoMessagingScreenState extends ConsumerState<AutoMessagingScreen> {
  late final TextEditingController _messageController;
  late final TextEditingController _waNumberController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(autoMessagingControllerProvider);
    _messageController = TextEditingController(text: state.customMessage);
    _waNumberController = TextEditingController(text: state.whatsAppNumber);
  }

  @override
  void dispose() {
    _messageController.disposeDisposeSafe();
    _waNumberController.disposeDisposeSafe();
    super.dispose();
  }

  Future<void> _pickContactFromPhone() async {
    try {
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        if (mounted) context.showSnackBar('Contacts permission is required to select numbers.');
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        final phone = contact.phones.first.number;
        final name = contact.displayName.isNotEmpty ? contact.displayName : 'Contact';
        ref.read(autoMessagingControllerProvider.notifier).addContact(
              AutoReplyContact(name: name, number: phone),
            );
        if (mounted) context.showSnackBar('Added $name ($phone)');
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Could not pick contact: $e');
    }
  }

  Future<void> _showAddManualDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name (Optional)',
                hintText: 'e.g. John Doe / Colleague',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            AppSpacing.vSpace12,
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g. 9845012345 or +91...',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final rawNumber = phoneController.text.trim();
              if (rawNumber.isEmpty) return;
              final name = nameController.text.trim().isEmpty ? 'Custom Number' : nameController.text.trim();
              ref.read(autoMessagingControllerProvider.notifier).addContact(
                    AutoReplyContact(name: name, number: rawNumber),
                  );
              Navigator.pop(ctx);
              context.showSnackBar('Added $name ($rawNumber)');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoMessagingControllerProvider);
    final controller = ref.read(autoMessagingControllerProvider.notifier);
    final colorScheme = context.colorScheme;

    // Sync message controller if changed via preset
    if (_messageController.text != state.customMessage) {
      _messageController.text = state.customMessage;
      _messageController.selection = TextSelection.collapsed(offset: state.customMessage.length);
    }

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Smart Auto-Messaging',
        subtitle: 'Audience Targeting & Dynamic SMS',
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // 1. Audience Target Selector
          Text(
            'WHO RECEIVES AUTO-MESSAGES?',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          Text(
            'Choose exactly who receives automated SMS replies when you are in class, driving, or decline calls.',
            style: context.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          AppSpacing.vSpace12,

          ...AutoMsgTargetMode.values.map((mode) {
            final isSelected = state.targetMode == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AppCard(
                variant: isSelected ? AppCardVariant.filled : AppCardVariant.outlined,
                color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
                borderSide: isSelected
                    ? BorderSide(color: colorScheme.primary, width: 1.8)
                    : BorderSide(color: colorScheme.outlineVariant),
                onTap: () => controller.setTargetMode(mode),
                child: Row(
                  children: [
                    Radio<AutoMsgTargetMode>(
                      value: mode,
                      groupValue: state.targetMode,
                      onChanged: (val) {
                        if (val != null) controller.setTargetMode(val);
                      },
                    ),
                    AppSpacing.hSpace8,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(mode.icon, size: 18, color: isSelected ? colorScheme.primary : colorScheme.onSurface),
                              AppSpacing.hSpace8,
                              Text(
                                mode.title,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  mode.badgeText,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vSpace4,
                          Text(
                            mode.subtitle,
                            style: context.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          AppSpacing.vSpace16,

          // 2. Selected Numbers Management Section
          if (state.targetMode == AutoMsgTargetMode.selectedOnly ||
              state.targetMode == AutoMsgTargetMode.excludeSelected) ...[
            Text(
              state.targetMode == AutoMsgTargetMode.selectedOnly
                  ? 'WHITELIST NUMBERS (${state.selectedContacts.length})'
                  : 'BLACKLIST NUMBERS (${state.selectedContacts.length})',
              style: context.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            AppSpacing.vSpace8,
            AppCard(
              variant: AppCardVariant.outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.contacts_rounded, size: 18),
                          label: const Text('From Contacts'),
                          onPressed: _pickContactFromPhone,
                        ),
                      ),
                      AppSpacing.hSpace8,
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Manually'),
                          onPressed: _showAddManualDialog,
                        ),
                      ),
                    ],
                  ),
                  if (state.selectedContacts.isNotEmpty) ...[
                    AppSpacing.vSpace12,
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.selectedContacts.length} numbers configured',
                          style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () => controller.clearAllContacts(),
                          child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    AppSpacing.vSpace4,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.selectedContacts.map((c) {
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '#',
                              style: TextStyle(fontSize: 11, color: colorScheme.onPrimaryContainer),
                            ),
                          ),
                          label: Text('${c.name} (${c.number})'),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () => controller.removeContact(c),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    AppSpacing.vSpace12,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: colorScheme.outline),
                          AppSpacing.hSpace12,
                          Expanded(
                            child: Text(
                              state.targetMode == AutoMsgTargetMode.selectedOnly
                                  ? 'No numbers selected yet. Tap above to pick contacts who should receive auto-replies.'
                                  : 'No numbers excluded yet. Tap above to add numbers to exclude from auto-replies.',
                              style: context.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vSpace20,
          ],

          // 3. Innovative Smart Enhancements
          Text(
            'INNOVATIVE SMART ENHANCEMENTS',
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
                // Enhancement 1: Click-to-WhatsApp Direct Link
                AppSwitchRow(
                  leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green),
                  title: 'Click-to-WhatsApp Link',
                  subtitle: 'Appends 1-tap WhatsApp link so callers can message or send free voice notes',
                  value: state.includeWhatsAppLink,
                  onChanged: (val) => controller.toggleIncludeWhatsApp(val),
                ),
                if (state.includeWhatsAppLink) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _waNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Your WhatsApp Phone Number',
                        hintText: 'e.g. 7907338556',
                        prefixText: '+91 ',
                        prefixIcon: Icon(Icons.phone_iphone_rounded, color: Colors.green),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => controller.setWhatsAppNumber(val.trim()),
                    ),
                  ),
                ],
                const Divider(),

                // Enhancement 2: Emergency 2-Call Breakthrough
                AppSwitchRow(
                  leading: const Icon(Icons.emergency_outlined, color: Colors.red),
                  title: 'Emergency 2-Call Breakthrough',
                  subtitle: 'If someone calls twice within 3 minutes, bypass auto-decline and ring phone out loud',
                  value: state.emergencyBreakthrough,
                  onChanged: (val) => controller.toggleEmergencyBreakthrough(val),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace20,

          // 4. Message Presets & Composer
          Text(
            'AUTO-REPLY MESSAGE COMPOSER',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,
          Text(
            'Select a quick preset or craft your custom response:',
            style: context.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          AppSpacing.vSpace8,

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AutoReplyPreset.presets.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: Text(preset.iconEmoji, style: const TextStyle(fontSize: 14)),
                    label: Text(preset.title),
                    onPressed: () {
                      _messageController.text = preset.template;
                      controller.setCustomMessage(preset.template);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          AppSpacing.vSpace12,

          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your auto-reply text here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            onChanged: (val) => controller.setCustomMessage(val),
          ),
          AppSpacing.vSpace20,

          // 5. Live SMS Preview Bubble
          Text(
            'CALLER SMS PREVIEW',
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppSpacing.vSpace8,

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sms_outlined, size: 16, color: colorScheme.primary),
                    AppSpacing.hSpace8,
                    Text(
                      'SMS sent to caller upon call decline',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpace12,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    state.previewMessage,
                    style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
                AppSpacing.vSpace8,
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${state.previewMessage.length} characters',
                    style: context.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
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

extension on TextEditingController {
  void disposeDisposeSafe() {
    try {
      dispose();
    } catch (_) {}
  }
}
