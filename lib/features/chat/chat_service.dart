import '../memory/memory_model.dart';
import '../memory/memory_repository.dart';

class ChatService {
  final MemoryRepository _repository;

  ChatService(this._repository);

  Future<List<MemorySearchResult>> search(String query, {int limit = 20, int offset = 0}) async {
    return _repository.search(query, limit: limit, offset: offset);
  }

  Future<List<MemoryEntry>> recentMemories({int limit = 20}) async {
    final all = await _repository.getAllEntries();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList();
  }
}
