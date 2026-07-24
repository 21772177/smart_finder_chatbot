import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../memory/memory_model.dart';
import '../memory/memory_repository.dart';
import 'chat_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatState {
  final List<ChatMessage> messages;
  final List<MemorySearchResult> results;
  final bool isSearching;
  final bool isLoadingMore;
  final bool hasMore;
  final String? lastQuery;
  final int searchOffset;

  const ChatState({
    this.messages = const [],
    this.results = const [],
    this.isSearching = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.lastQuery,
    this.searchOffset = 0,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<MemorySearchResult>? results,
    bool? isSearching,
    bool? isLoadingMore,
    bool? hasMore,
    String? lastQuery,
    int? searchOffset,
    bool clearLastQuery = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastQuery: clearLastQuery ? null : (lastQuery ?? this.lastQuery),
      searchOffset: searchOffset ?? this.searchOffset,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _service;
  static const int _pageSize = 20;

  ChatNotifier(this._service) : super(const ChatState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: query, isUser: true)],
      isSearching: true,
    );

    final results = await _service.search(query, limit: _pageSize);

    final responseText = results.isEmpty
        ? 'No memories found matching "$query".'
        : 'Found ${results.length} result(s):\n${results.take(5).map((r) => '• ${r.memoryEntry.title}').join('\n')}';

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: responseText, isUser: false)],
      results: results,
      isSearching: false,
      hasMore: results.length >= _pageSize,
      lastQuery: query,
      searchOffset: results.length,
    );
  }

  Future<void> loadMore() async {
    final query = state.lastQuery;
    if (query == null || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final moreResults = await _service.search(query, limit: _pageSize, offset: state.searchOffset);

    state = state.copyWith(
      results: [...state.results, ...moreResults],
      isLoadingMore: false,
      hasMore: moreResults.length >= _pageSize,
      searchOffset: state.searchOffset + moreResults.length,
    );
  }

  Future<void> updateMemory(String id, {String? title, String? content, List<String>? tags}) async {
    final updatedResults = <MemorySearchResult>[];
    for (final r in state.results) {
      if (r.memoryEntry.id == id) {
        final updated = MemoryEntry(
          id: r.memoryEntry.id,
          title: title ?? r.memoryEntry.title,
          content: content ?? r.memoryEntry.content,
          sourceApp: r.memoryEntry.sourceApp,
          ocrText: r.memoryEntry.ocrText,
          tags: tags ?? r.memoryEntry.tags,
          createdAt: r.memoryEntry.createdAt,
          updatedAt: DateTime.now(),
        );
        updatedResults.add(MemorySearchResult(memoryEntry: updated, score: r.score));
      } else {
        updatedResults.add(r);
      }
    }
    state = state.copyWith(results: updatedResults);
  }

  Future<void> loadRecent() async {
    final recent = await _service.recentMemories();
    if (recent.isNotEmpty) {
      state = state.copyWith(
        messages: [
          ChatMessage(
            text: 'Welcome! Here are your recent memories:\n${recent.take(5).map((m) => '• ${m.title}').join('\n')}',
            isUser: false,
          ),
        ],
      );
    } else {
      state = state.copyWith(
        messages: [
          ChatMessage(
            text: 'No memories yet. Use the overlay to capture your first one!',
            isUser: false,
          ),
        ],
      );
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(memoryRepositoryProvider));
});

final chatStateProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatServiceProvider));
});
