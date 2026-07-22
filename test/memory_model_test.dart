import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/memory/memory_model.dart';

void main() {
  group('MemoryEntry', () {
    test('creates with required fields', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final entry = MemoryEntry(
        id: 'test-id',
        title: 'Test Title',
        content: 'Test content',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.id, 'test-id');
      expect(entry.title, 'Test Title');
      expect(entry.content, 'Test content');
      expect(entry.sourceApp, isNull);
      expect(entry.ocrText, isNull);
      expect(entry.tags, isEmpty);
      expect(entry.createdAt, now);
      expect(entry.updatedAt, now);
    });

    test('creates with all fields', () {
      final now = DateTime(2026, 1, 15);
      final entry = MemoryEntry(
        id: 'id',
        title: 'Title',
        content: 'Content',
        sourceApp: 'com.example',
        ocrText: 'OCR text',
        tags: ['tag1', 'tag2'],
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.sourceApp, 'com.example');
      expect(entry.ocrText, 'OCR text');
      expect(entry.tags, ['tag1', 'tag2']);
    });

    test('toJson produces valid JSON', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final entry = MemoryEntry(
        id: 'id-123',
        title: 'My Title',
        content: 'My Content',
        tags: ['a', 'b'],
        createdAt: now,
        updatedAt: now,
      );

      final json = entry.toJson();

      expect(json['id'], 'id-123');
      expect(json['title'], 'My Title');
      expect(json['content'], 'My Content');
      expect(json['tags'], ['a', 'b']);
      expect(json['createdAt'], now.toIso8601String());
      expect(json['updatedAt'], now.toIso8601String());
    });

    test('fromJson restores entry correctly', () {
      final now = DateTime(2026, 6, 15, 14, 30, 0, 0);
      final json = {
        'id': 'restored-id',
        'title': 'Restored Title',
        'content': 'Restored Content',
        'sourceApp': 'com.test',
        'ocrText': 'OCR data',
        'tags': ['x', 'y', 'z'],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.id, 'restored-id');
      expect(entry.title, 'Restored Title');
      expect(entry.sourceApp, 'com.test');
      expect(entry.ocrText, 'OCR data');
      expect(entry.tags, ['x', 'y', 'z']);
      expect(entry.createdAt.year, 2026);
      expect(entry.createdAt.month, 6);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'id',
        'title': 'Title',
        'content': 'Content',
        'tags': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final entry = MemoryEntry.fromJson(json);

      expect(entry.sourceApp, isNull);
      expect(entry.ocrText, isNull);
      expect(entry.tags, isEmpty);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final now = DateTime(2026, 3, 20);
      final original = MemoryEntry(
        id: 'roundtrip',
        title: 'Round Trip',
        content: 'Content body',
        sourceApp: 'com.roundtrip',
        ocrText: 'OCR',
        tags: ['one', 'two'],
        createdAt: now,
        updatedAt: now,
      );

      final restored = MemoryEntry.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.sourceApp, original.sourceApp);
      expect(restored.tags, original.tags);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('MemorySearchResult', () {
    test('holds entry and score', () {
      final entry = MemoryEntry(
        id: 'id',
        title: 'T',
        content: 'C',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = MemorySearchResult(memoryEntry: entry, score: 0.85);

      expect(result.memoryEntry, entry);
      expect(result.score, 0.85);
    });
  });
}
