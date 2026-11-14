import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/app/app.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';

class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends ConsumerState<ComponentGalleryScreen> {
  int _selectedSegment = 0;
  bool _switchVal1 = true;
  bool _switchVal2 = false;
  bool _filterAll = true;
  bool _filterUnread = false;
  bool _filterStarred = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = context.isDark;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'M3 Component Gallery',
        subtitle: 'Material 3 Google Design System',
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.padding16,
        children: [
          // Section 1: Search Bar
          _buildSectionHeader('1. Pill Search Bar (M3)'),
          const AppSearchBar(
            hintText: 'Search voicemails, transcripts, contacts...',
          ),
          AppSpacing.vSpace16,

          // Section 2: Filter Chips
          _buildSectionHeader('2. Filter Chips'),
          AppFilterBar(
            padding: EdgeInsets.zero,
            chips: [
              AppFilterChip(
                label: 'All Calls',
                selected: _filterAll,
                count: 24,
                onSelected: (val) => setState(() {
                  _filterAll = true;
                  _filterUnread = false;
                  _filterStarred = false;
                }),
              ),
              AppFilterChip(
                label: 'Unread',
                selected: _filterUnread,
                count: 5,
                onSelected: (val) => setState(() {
                  _filterUnread = val;
                  _filterAll = !_filterUnread && !_filterStarred;
                }),
              ),
              AppFilterChip(
                label: 'Starred',
                selected: _filterStarred,
                count: 3,
                avatar: const Icon(Icons.star, size: 16),
                onSelected: (val) => setState(() {
                  _filterStarred = val;
                  _filterAll = !_filterUnread && !_filterStarred;
                }),
              ),
            ],
          ),
          AppSpacing.vSpace16,

          // Section 3: Segmented Buttons
          _buildSectionHeader('3. Segmented Buttons'),
          AppSegmentedButton<int>(
            selected: _selectedSegment,
            onSelectionChanged: (val) => setState(() => _selectedSegment = val),
            segments: const [
              AppSegment(value: 0, label: 'Standard', icon: Icon(Icons.phone)),
              AppSegment(value: 1, label: 'Assistant', icon: Icon(Icons.smart_toy)),
              AppSegment(value: 2, label: 'DND', icon: Icon(Icons.do_not_disturb_on)),
            ],
          ),
          AppSpacing.vSpace16,

          // Section 4: Cards
          _buildSectionHeader('4. Cards (Filled, Elevated, Outlined)'),
          AppCard(
            variant: AppCardVariant.filled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filled Card (Default)', style: context.textTheme.titleMedium),
                AppSpacing.vSpace4,
                Text(
                  'Material 3 surfaceContainerLow with smooth corner radius.',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          AppSpacing.vSpace8,
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Outlined Card', style: context.textTheme.titleMedium),
                AppSpacing.vSpace4,
                Text(
                  'Subtle outline with surface container background.',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // Section 5: List Tiles
          _buildSectionHeader('5. Clean List Tiles'),
          AppListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Text('DK', style: TextStyle(color: context.colorScheme.onPrimaryContainer)),
            ),
            title: const Text('Danish K'),
            subtitle: const Text('Call handled by Server Assistant • 0:42'),
            trailing: const Text('10:45 AM'),
            onTap: () => context.showSnackBar('Tapped Danish K voicemail'),
          ),
          AppListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.secondaryContainer,
              child: const Icon(Icons.phone_missed, size: 20),
            ),
            title: const Text('+91 98450 12345'),
            subtitle: const Text('Auto-declined with WhatsApp prompt'),
            trailing: const Icon(Icons.star_border),
            onTap: () {},
          ),
          AppSpacing.vSpace16,

          // Section 6: Switch Rows
          _buildSectionHeader('6. Switch Rows'),
          AppCard(
            child: Column(
              children: [
                AppSwitchRow(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: 'Auto-Answer Assistant',
                  subtitle: 'Transcribe caller speech locally in real-time',
                  value: _switchVal1,
                  onChanged: (val) => setState(() => _switchVal1 = val),
                ),
                const Divider(),
                AppSwitchRow(
                  leading: const Icon(Icons.security),
                  title: 'Block Screen Capture',
                  subtitle: 'Prevent screenshots of private voicemails',
                  value: _switchVal2,
                  onChanged: (val) => setState(() => _switchVal2 = val),
                ),
              ],
            ),
          ),
          AppSpacing.vSpace16,

          // Section 7: Status Banners
          _buildSectionHeader('7. Status Banners (Reliability Alerts)'),
          AppStatusBanner(
            type: AppBannerType.warning,
            title: 'Battery Optimization Enabled',
            message: 'Realme UI may sleep background call screening. Tap Fix to exempt.',
            actionLabel: 'Fix',
            onAction: () => context.showSnackBar('Opening Battery Settings...'),
          ),
          AppSpacing.vSpace8,
          AppStatusBanner(
            type: AppBannerType.success,
            title: 'Call Forwarding Active',
            message: 'All declined calls forward to +914954268791 (Kerala DID).',
          ),
          AppSpacing.vSpace16,

          // Section 8: Permission Cards
          _buildSectionHeader('8. Permission Rationale Card'),
          AppPermissionCard(
            icon: Icons.shield,
            title: 'Call Screening Role',
            description:
                'Required to identify incoming callers and invoke the assistant without ring latency.',
            isGranted: false,
            actionLabel: 'Grant',
            onGrant: () => context.showSnackBar('Requesting Call Screening Role...'),
          ),
          AppSpacing.vSpace16,

          // Section 9: Dialogs & Bottom Sheet Triggers
          _buildSectionHeader('9. Interactive Overlays'),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    AppDialog.showConfirmation(
                      context: context,
                      icon: const Icon(Icons.delete_outline, size: 28),
                      title: 'Delete Voicemail?',
                      message: 'This will permanently remove this recording from your phone.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
              AppSpacing.hSpace12,
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    AppBottomSheet.show(
                      context: context,
                      title: 'Voicemail Actions',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.share),
                            title: const Text('Share Audio & Transcript'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.block),
                            title: const Text('Block Caller'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Sheet'),
                ),
              ),
            ],
          ),
          AppSpacing.vSpace16,

          // Section 10: Loading Skeleton
          _buildSectionHeader('10. Loading Skeleton (Shimmer)'),
          const AppLoadingSkeleton(width: double.infinity, height: 64),
          AppSpacing.vSpace8,
          const AppLoadingSkeleton(width: 220, height: 20),
          AppSpacing.vSpace32,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

