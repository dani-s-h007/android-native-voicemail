import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/data/repositories/local_voicemail_repository.dart';
import 'package:voicemail/domain/repositories/voicemail_repository.dart';
import 'package:voicemail/features/voicemail/domain/voicemail.dart';

enum VoicemailFilter { all, unread, starred, contacts }

class VoicemailState {
  final List<Voicemail> voicemails;
  final bool isLoading;
  final String? errorMessage;
  final VoicemailFilter filter;
  final String searchQuery;
  final Set<String> selectedIds;

  const VoicemailState({
    this.voicemails = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filter = VoicemailFilter.all,
    this.searchQuery = '',
    this.selectedIds = const {},
  });

  bool get isMultiSelecting => selectedIds.isNotEmpty;

  int get unreadCount => voicemails.where((v) => !v.isRead).length;
  int get starredCount => voicemails.where((v) => v.isStarred).length;

  List<Voicemail> get filteredVoicemails {
    var list = voicemails;

    // Apply Filter Chips
    switch (filter) {
      case VoicemailFilter.all:
        break;
      case VoicemailFilter.unread:
        list = list.where((v) => !v.isRead).toList();
      case VoicemailFilter.starred:
        list = list.where((v) => v.isStarred).toList();
      case VoicemailFilter.contacts:
        list = list.where((v) => v.callerName != null && v.callerName!.isNotEmpty).toList();
    }

    // Apply Search Query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((v) {
        final nameMatch = v.callerName?.toLowerCase().contains(q) ?? false;
        final numMatch = v.callerNumber.toLowerCase().contains(q);
        final transcriptMatch = v.transcriptText?.toLowerCase().contains(q) ?? false;
        return nameMatch || numMatch || transcriptMatch;
      }).toList();
    }

    return list;
  }

  VoicemailState copyWith({
    List<Voicemail>? voicemails,
    bool? isLoading,
    String? errorMessage,
    VoicemailFilter? filter,
    String? searchQuery,
    Set<String>? selectedIds,
  }) {
    return VoicemailState(
      voicemails: voicemails ?? this.voicemails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

final voicemailRepositoryProvider = Provider<VoicemailRepository>((ref) {
  return LocalVoicemailRepository();
});

final voicemailControllerProvider =
    StateNotifierProvider<VoicemailController, VoicemailState>((ref) {
  final repo = ref.watch(voicemailRepositoryProvider);
  return VoicemailController(repo);
});

class VoicemailController extends StateNotifier<VoicemailState> {
  final VoicemailRepository _repository;

  VoicemailController(this._repository) : super(const VoicemailState()) {
    loadVoicemails();
  }

  Future<void> loadVoicemails() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getVoicemails();

    result.fold(
      onSuccess: (list) {
        state = state.copyWith(
          voicemails: list,
          isLoading: false,
        );
      },
      onFailure: (err) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: err.message,
        );
      },
    );
  }

  void setFilter(VoicemailFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSelection(String id) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedIds: current);
  }

  void selectAll() {
    final allIds = state.filteredVoicemails.map((v) => v.id).toSet();
    state = state.copyWith(selectedIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> deleteSelected() async {
    final ids = state.selectedIds;
    if (ids.isEmpty) return;

    await _repository.deleteMultiple(ids);
    clearSelection();
    await loadVoicemails();
  }

  Future<void> markSelectedAsRead(bool isRead) async {
    final ids = state.selectedIds;
    if (ids.isEmpty) return;

    await _repository.markMultipleAsRead(ids, isRead);
    clearSelection();
    await loadVoicemails();
  }

  Future<void> deleteSingle(String id) async {
    await _repository.deleteVoicemail(id);
    await loadVoicemails();
  }

  Future<void> toggleStarred(String id, bool currentStarred) async {
    await _repository.toggleStarred(id, !currentStarred);
    await loadVoicemails();
  }

  Future<void> markAsRead(String id, bool isRead) async {
    await _repository.markAsRead(id, isRead);
    await loadVoicemails();
  }
}

