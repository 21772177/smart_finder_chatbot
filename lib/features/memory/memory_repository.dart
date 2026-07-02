import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'memory_model.dart';
import 'memory_database.dart';

class MemoryRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  MemoryRepository(this._db);

  Future<void> saveMemoryEntry({
    required String title,
    required String content,
    String? sourceApp,
    String? ocrText,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final entry = MemoryEntry(
      id: _uuid.v4(),
      title: title,
      content: content,
      sourceApp: sourceApp,
      ocrText: ocrText,
      tags: tags ?? [],
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertMemoryEntry(entry);
  }

  Future<List<MemoryEntry>> getAllEntries() => _db.getAllEntries();

  Future<List<MemorySearchResult>> search(String query) => _db.search(query);

  Future<void> deleteEntry(String id) => _db.deleteMemoryEntry(id);

  Future<void> deleteAllEntries() => _db.deleteAllEntries();
}

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(ref.watch(databaseProvider));
});
