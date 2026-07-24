import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite3/open.dart' as sqlite3_open;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import '../security/secure_key_service.dart';
import 'memory_model.dart';
import 'embedding_service.dart';
import 'vector_index.dart';

part 'memory_database.g.dart';

final _embedder = EmbeddingService();
final _vectorIndex = VectorIndex(256);
bool _sqlCipherInitialized = false;

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
    final embeddingVec = _embedder.embed(text);
    final embedding = _embedder.vectorToJson(embeddingVec);

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

    _vectorIndex.add(entry.id, Float32List.fromList(embeddingVec));
  }

  Future<void> updateMemoryEntry(MemoryEntry entry) async {
    final text = '${entry.title} ${entry.content} ${entry.ocrText ?? ''} ${entry.tags.join(' ')}';
    final embeddingVec = _embedder.embed(text);
    final embedding = _embedder.vectorToJson(embeddingVec);

    await (update(memories)..where((t) => t.id.equals(entry.id))).write(MemoriesCompanion(
      title: Value(entry.title),
      content: Value(entry.content),
      sourceApp: Value(entry.sourceApp),
      ocrText: Value(entry.ocrText),
      tags: Value(jsonEncode(entry.tags)),
      embedding: Value(embedding),
      updatedAt: Value(entry.updatedAt),
    ));

    _vectorIndex.add(entry.id, Float32List.fromList(embeddingVec));
  }

  Future<void> deleteMemoryEntry(String id) async {
    await (delete(memories)..where((t) => t.id.equals(id))).go();
    _vectorIndex.remove(id);
  }

  Future<void> deleteAllEntries() async {
    await delete(memories).go();
    _vectorIndex.clear();
  }

  Future<List<MemoryEntry>> getAllEntries() async {
    final rows = await select(memories).get();
    return rows.map(_rowToEntry).toList();
  }

  Future<List<MemorySearchResult>> search(String query, {int limit = 20, int offset = 0}) async {
    final queryEmbedding = _embedder.embed(query);

    // Use vector index for fast search
    if (_vectorIndex.size > 0) {
      final results = _vectorIndex.search(Float32List.fromList(queryEmbedding), limit + offset);
      final searchResults = <MemorySearchResult>[];

      for (final r in results) {
        final row = await (select(memories)..where((t) => t.id.equals(r.id))).getSingleOrNull();
        if (row != null) {
          searchResults.add(MemorySearchResult(memoryEntry: _rowToEntry(row), score: 1.0 - r.distance / 2));
        }
      }
      return searchResults.skip(offset).take(limit).toList();
    }

    // Fallback to full scan
    final rows = await select(memories).get();
    if (rows.isEmpty) return [];

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
    return results.skip(offset).take(limit).toList();
  }

  Future<void> rebuildVectorIndex() async {
    _vectorIndex.clear();
    final rows = await select(memories).get();
    for (final row in rows) {
      final raw = row.embedding;
      if (raw.isNotEmpty) {
        final vec = _embedder.jsonToVector(raw);
        _vectorIndex.add(row.id, Float32List.fromList(vec));
      }
    }
    _vectorIndex.rebuild();
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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Ensure SQLCipher native library is loaded instead of standard SQLite
    if (!_sqlCipherInitialized) {
      sqlite3_open.open.overrideFor(sqlite3_open.OperatingSystem.android, openCipherOnAndroid);
      _sqlCipherInitialized = true;
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'second_brain_enc.db'));

    final nativeDb = sqlite3.sqlite3.open(file.path);

    // Verify SQLCipher is actually loaded
    final cipherVersion = nativeDb.select('PRAGMA cipher_version;');
    if (cipherVersion.isEmpty) {
      throw StateError(
        'SQLCipher library is not available. Database encryption cannot be guaranteed.',
      );
    }

    final secureKeyService = SecureKeyService();
    final key = await secureKeyService.getDbKey();
    nativeDb.execute("PRAGMA key = '$key'");
    nativeDb.execute('PRAGMA cipher_compatibility = 4');

    return NativeDatabase.opened(nativeDb);
  });
}
