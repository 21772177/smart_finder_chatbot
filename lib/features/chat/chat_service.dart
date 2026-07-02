import '../memory/memory_model.dart';
import '../memory/memory_repository.dart';

class ChatService {
  final MemoryRepository _repository;

  ChatService(this._repository);

  Future<List<MemorySearchResult>> search(String query) async {
    return _repository.search(query);
  }

  Future<List<MemoryEntry>> recentMemories() async {
    final all = await _repository.getAllEntries();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(20).toList();
  }
}
