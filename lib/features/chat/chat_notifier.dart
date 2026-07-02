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

  const ChatState({
    this.messages = const [],
    this.results = const [],
    this.isSearching = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<MemorySearchResult>? results,
    bool? isSearching,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _service;

  ChatNotifier(this._service) : super(const ChatState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: query, isUser: true)],
      isSearching: true,
    );

    final results = await _service.search(query);

    final responseText = results.isEmpty
        ? 'No memories found matching "$query".'
        : 'Found ${results.length} result(s):\n${results.take(5).map((r) => '• ${r.memoryEntry.title}').join('\n')}';

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: responseText, isUser: false)],
      results: results,
      isSearching: false,
    );
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
