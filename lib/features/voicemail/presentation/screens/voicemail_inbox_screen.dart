import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicemail/core/constants/app_constants.dart';
import 'package:voicemail/core/extensions/context_extensions.dart';
import 'package:voicemail/core/extensions/datetime_extensions.dart';
import 'package:voicemail/design_system/components/components.dart';
import 'package:voicemail/design_system/tokens/spacing_tokens.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';
import 'package:voicemail/features/voicemail/presentation/controllers/voicemail_controller.dart';

class VoicemailInboxScreen extends ConsumerStatefulWidget {
  const VoicemailInboxScreen({super.key});

  @override
  ConsumerState<VoicemailInboxScreen> createState() => _VoicemailInboxScreenState();
}

class _VoicemailInboxScreenState extends ConsumerState<VoicemailInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showReliabilityNotice = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voicemailControllerProvider);
    final controller = ref.read(voicemailControllerProvider.notifier);

    // Normal AppBar vs Multi-Select AppBar
    PreferredSizeWidget appBar;
    if (state.isMultiSelecting) {
      appBar = AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel selection',
          onPressed: controller.clearSelection,
        ),
        title: Text('${state.selectedIds.length} selected'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Select all',
            onPressed: controller.selectAll,
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: 'Mark as read',
            onPressed: () => controller.markSelectedAsRead(true),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete selected',
            onPressed: () async {
              final confirmed = await AppDialog.showConfirmation(
                context: context,
                title: 'Delete ${state.selectedIds.length} voicemails?',
                message:
                    'These recordings will be permanently removed from your phone.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed == true) {
                await controller.deleteSelected();
              }
            },
          ),
        ],
      );
    } else {
      appBar = AppAppBar(
        title: 'Voicemail',
        subtitle: '100% On-Device Private Inbox',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'M3 Component Gallery',
            onPressed: () => context.push(AppConstants.routeComponentGallery),
          ),
        ],
      );
    }

    return AppScaffold(
      appBar: appBar,
      body: RefreshIndicator(
        onRefresh: controller.loadVoicemails,
        child: Column(
          children: [
            // Search Bar & Filter Chips (hidden during multi-select)
            if (!state.isMultiSelecting) ...[
              if (_showReliabilityNotice) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AppStatusBanner(
                    type: AppBannerType.warning,
                    title: 'Device Health Notice',
                    message: 'Review background screening exemptions to ensure calls never drop.',
                    actionLabel: 'Check Health',
                    onAction: () => context.push(AppConstants.routeReliability),
                    onDismiss: () => setState(() => _showReliabilityNotice = false),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search voicemails, contacts, transcripts...',
                  onChanged: controller.setSearchQuery,
                  onClear: () => controller.setSearchQuery(''),
                ),
              ),
              AppSpacing.vSpace8,
              AppFilterBar(
                chips: [
                  AppFilterChip(
                    label: 'All',
                    selected: state.filter == VoicemailFilter.all,
                    count: state.voicemails.length,
                    onSelected: (_) => controller.setFilter(VoicemailFilter.all),
                  ),
                  AppFilterChip(
                    label: 'Unread',
                    selected: state.filter == VoicemailFilter.unread,
                    count: state.unreadCount,
                    onSelected: (_) => controller.setFilter(VoicemailFilter.unread),
                  ),
                  AppFilterChip(
                    label: 'Starred',
                    selected: state.filter == VoicemailFilter.starred,
                    count: state.starredCount,
                    avatar: const Icon(Icons.star, size: 16),
                    onSelected: (_) => controller.setFilter(VoicemailFilter.starred),
                  ),
                  AppFilterChip(
                    label: 'Contacts',
                    selected: state.filter == VoicemailFilter.contacts,
                    avatar: const Icon(Icons.person, size: 16),
                    onSelected: (_) => controller.setFilter(VoicemailFilter.contacts),
                  ),
                ],
              ),
              const Divider(height: 1),
            ],

            // Content List
            Expanded(
              child: state.isLoading
                  ? _buildLoadingState()
                  : state.filteredVoicemails.isEmpty
                      ? _buildEmptyState(state)
                      : _buildGroupedList(state.filteredVoicemails, state, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: AppSpacing.padding16,
      itemCount: 6,
      separatorBuilder: (_, __) => AppSpacing.vSpace12,
      itemBuilder: (_, __) => AppLoadingSkeleton.listItem(),
    );
  }

  Widget _buildEmptyState(VoicemailState state) {
    if (state.searchQuery.isNotEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Matching Voicemails',
        description: 'Try adjusting your search query or removing filters.',
        actionLabel: 'Clear Search',
        onAction: () {
          _searchController.clear();
          ref.read(voicemailControllerProvider.notifier).setSearchQuery('');
        },
      );
    }

    return const AppEmptyState(
      icon: Icons.voicemail_rounded,
      title: 'Inbox Zero',
      description:
          'When callers reach your automated assistant, recordings and offline transcripts will appear here.',
    );
  }

  Widget _buildGroupedList(
    List<Voicemail> voicemails,
    VoicemailState state,
    VoicemailController controller,
  ) {
    // Group voicemails by dateGroupHeader: Today, Yesterday, Earlier
    final Map<String, List<Voicemail>> grouped = {};
    for (final vm in voicemails) {
      final header = vm.createdAt.dateGroupHeader;
      grouped.putIfAbsent(header, () => []).add(vm);
    }

    return ListView.builder(
      itemCount: grouped.keys.length,
      itemBuilder: (context, groupIndex) {
        final header = grouped.keys.elementAt(groupIndex);
        final list = grouped[header]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                header.toUpperCase(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...list.map((vm) => _buildVoicemailTile(vm, state, controller)),
          ],
        );
      },
    );
  }

  Widget _buildVoicemailTile(
    Voicemail vm,
    VoicemailState state,
    VoicemailController controller,
  ) {
    final isSelected = state.selectedIds.contains(vm.id);
    final colorScheme = context.colorScheme;

    return Dismissible(
      key: ValueKey(vm.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: colorScheme.primaryContainer,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          vm.isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          return await AppDialog.showConfirmation(
            context: context,
            title: 'Delete this voicemail?',
            message: 'Permanently remove recording from ${vm.displayName}?',
            confirmLabel: 'Delete',
            isDestructive: true,
          );
        } else {
          // Toggle read
          await controller.markAsRead(vm.id, !vm.isRead);
          return false;
        }
      },
      onDismissed: (_) {
        controller.deleteSingle(vm.id);
      },
      child: AppListTile(
        selected: isSelected,
        onLongPress: () => controller.toggleSelection(vm.id),
        onTap: () {
          if (state.isMultiSelecting) {
            controller.toggleSelection(vm.id);
          } else {
            controller.markAsRead(vm.id, true);
            context.push('/voicemail/${vm.id}');
          }
        },
        leading: CircleAvatar(
          backgroundColor: vm.isRead
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          foregroundColor: vm.isRead
              ? colorScheme.onSurfaceVariant
              : colorScheme.onPrimaryContainer,
          child: isSelected
              ? const Icon(Icons.check, size: 20)
              : Text(
                  vm.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                vm.displayName,
                style: TextStyle(
                  fontWeight: vm.isRead ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!vm.isRead) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              vm.createdAt.formattedTime,
              style: context.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.transcriptText != null && vm.transcriptText!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                vm.transcriptText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                Text(
                  Duration(seconds: vm.durationSeconds).formattedMinutesSeconds,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: colorScheme.outline)),
                const SizedBox(width: 8),
                Text(
                  vm.callHandlingMode,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    vm.isStarred ? Icons.star : Icons.star_border,
                    size: 20,
                    color: vm.isStarred ? Colors.amber.shade700 : colorScheme.outline,
                  ),
                  onPressed: () => controller.toggleStarred(vm.id, vm.isStarred),
                  tooltip: vm.isStarred ? 'Unstar' : 'Star',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
