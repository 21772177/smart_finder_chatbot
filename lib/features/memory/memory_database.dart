import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'memory_model.dart';
import 'embedding_service.dart';

part 'memory_database.g.dart';

const _kDbKey = 'second_brain_db_key';

final _embedder = EmbeddingService();

class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn? get sourceApp => text().nullable()();
  TextColumn? get ocrText => text().nullable()();
  TextColumn get tags => text()();
  TextColumn get embedding => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(memories, memories.embedding);
      }
    },
  );

  Future<void> insertMemoryEntry(MemoryEntry entry) async {
    final text = '${entry.title} ${entry.content} ${entry.ocrText ?? ''} ${entry.tags.join(' ')}';
    final embedding = _embedder.vectorToJson(_embedder.embed(text));

    await into(memories).insertOnConflictUpdate(MemoriesCompanion(
      id: Value(entry.id),
      title: Value(entry.title),
      content: Value(entry.content),
      sourceApp: Value(entry.sourceApp),
      ocrText: Value(entry.ocrText),
      tags: Value(jsonEncode(entry.tags)),
      embedding: Value(embedding),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
    ));
  }

  Future<void> deleteMemoryEntry(String id) async {
    await (delete(memories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAllEntries() async {
    await delete(memories).go();
  }

  Future<List<MemoryEntry>> getAllEntries() async {
    final rows = await select(memories).get();
    return rows.map(_rowToEntry).toList();
  }

  Future<List<MemorySearchResult>> search(String query) async {
    final rows = await select(memories).get();
    if (rows.isEmpty) return [];

    final queryEmbedding = _embedder.embed(query);
    final results = <MemorySearchResult>[];

    for (final row in rows) {
      final raw = row.embedding;
      if (raw.isEmpty) continue;
      final vec = _embedder.jsonToVector(raw);
      final score = _embedder.cosineSimilarity(vec, queryEmbedding);
      if (score > 0.05) {
        results.add(MemorySearchResult(memoryEntry: _rowToEntry(row), score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(20).toList();
  }

  MemoryEntry _rowToEntry(Memory row) {
    final tags = jsonDecode(row.tags) as List<dynamic>;
    return MemoryEntry(
      id: row.id,
      title: row.title,
      content: row.content,
      sourceApp: row.sourceApp,
      ocrText: row.ocrText,
      tags: tags.cast<String>(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

Future<String> _getOrCreateKey() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_kDbKey);
  if (existing != null && existing.isNotEmpty) return existing;

  final hexChars = '0123456789abcdef';
  final random = _SimpleRandom();
  final key = List.generate(64, (_) => hexChars[random.nextInt(16)]).join();
  await prefs.setString(_kDbKey, key);
  return key;
}

class _SimpleRandom {
  int _seed = DateTime.now().microsecondsSinceEpoch;

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'second_brain_enc.db'));

    final nativeDb = sqlite3.sqlite3.open(file.path);

    final key = await _getOrCreateKey();
    nativeDb.execute('PRAGMA key = "$key"');
    nativeDb.execute('PRAGMA cipher_compatibility = 4');

    return NativeDatabase.opened(nativeDb);
  });
}
