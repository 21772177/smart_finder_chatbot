import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'memory_model.dart';

part 'memory_database.g.dart';

class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn? get sourceApp => text().nullable()();
  TextColumn? get ocrText => text().nullable()();
  TextColumn get tags => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> insertMemoryEntry(MemoryEntry entry) async {
    await into(memories).insertOnConflictUpdate(MemoriesCompanion(
      id: Value(entry.id),
      title: Value(entry.title),
      content: Value(entry.content),
      sourceApp: Value(entry.sourceApp),
      ocrText: Value(entry.ocrText),
      tags: Value(jsonEncode(entry.tags)),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
    ));
  }

  Future<void> deleteMemoryEntry(String id) async {
    await (delete(memories)..where((t) => t.id.equals(id))).go();
  }

  Future<List<MemoryEntry>> getAllEntries() async {
    final rows = await select(memories).get();
    return rows.map(_rowToEntry).toList();
  }

  Future<List<MemorySearchResult>> search(String query) async {
    final queryTerms = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (queryTerms.isEmpty) return [];

    final rows = await select(memories).get();
    final results = <MemorySearchResult>[];

    for (final row in rows) {
      final entry = _rowToEntry(row);
      final score = _score(entry, queryTerms);
      if (score > 0) {
        results.add(MemorySearchResult(memoryEntry: entry, score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(20).toList();
  }

  double _score(MemoryEntry entry, List<String> queryTerms) {
    final text = '${entry.title} ${entry.content} ${entry.ocrText ?? ''} ${entry.tags.join(' ')}'.toLowerCase();
    final words = text.split(RegExp(r'\W+')).where((w) => w.length > 2).toList();
    final total = words.length;

    if (total == 0) return 0;

    double score = 0;
    for (final term in queryTerms) {
      final count = words.where((w) => w == term).length;
      if (count > 0) {
        final tf = count / total;
        if (entry.title.toLowerCase().contains(term)) {
          score += tf * 3;
        } else if (entry.tags.join(' ').toLowerCase().contains(term)) {
          score += tf * 2;
        } else {
          score += tf;
        }
      }
    }
    return score / queryTerms.length;
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
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'second_brain.db'));
    return NativeDatabase(file);
  });
}
