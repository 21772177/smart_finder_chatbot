import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'memory_model.dart';

part 'memory_database.g.dart';

const _kDbKey = 'second_brain_db_key';

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

  Future<void> deleteAllEntries() async {
    await delete(memories).go();
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
