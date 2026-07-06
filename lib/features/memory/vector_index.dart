import 'dart:typed_data';

class VectorIndex {
  final List<VectorEntry> _entries = [];
  final int _vectorSize;
  bool _dirty = true;
  KDNode? _root;

  VectorIndex(this._vectorSize);

  void add(String id, Float32List vector) {
    if (vector.length != _vectorSize) {
      throw ArgumentError('Vector size must be $_vectorSize');
    }
    _entries.add(VectorEntry(id: id, vector: vector));
    _dirty = true;
  }

  void remove(String id) {
    _entries.removeWhere((e) => e.id == id);
    _dirty = true;
  }

  void clear() {
    _entries.clear();
    _dirty = true;
    _root = null;
  }

  void rebuild() {
    if (_entries.isEmpty) {
      _root = null;
      _dirty = false;
      return;
    }
    _root = _buildTree(_entries, 0);
    _dirty = false;
  }

  KDNode _buildTree(List<VectorEntry> entries, int depth) {
    if (entries.isEmpty) return KDNode.empty();

    final axis = depth % _vectorSize;
    entries.sort((a, b) => a.vector[axis].compareTo(b.vector[axis]));

    final median = entries.length ~/ 2;
    final node = KDNode(
      entry: entries[median],
      axis: axis,
      left: _buildTree(entries.sublist(0, median), depth + 1),
      right: _buildTree(entries.sublist(median + 1), depth + 1),
    );
    return node;
  }

  List<SearchResult> search(Float32List queryVector, int k) {
    if (_dirty) rebuild();
    if (_root == null || _root!.isEmpty) return [];

    final results = <SearchResult>[];
    _searchKNN(_root!, queryVector, k, results);
    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results.take(k).toList();
  }

  void _searchKNN(KDNode node, Float32List query, int k, List<SearchResult> results) {
    if (node.isEmpty) return;

    final dist = _squaredDistance(query, node.entry!.vector);
    if (results.length < k) {
      results.add(SearchResult(id: node.entry!.id, distance: dist));
      results.sort((a, b) => a.distance.compareTo(b.distance));
    } else if (dist < results.last.distance) {
      results.removeLast();
      results.add(SearchResult(id: node.entry!.id, distance: dist));
      results.sort((a, b) => a.distance.compareTo(b.distance));
    }

    final axis = node.axis;
    final diff = query[axis] - node.entry!.vector[axis];
    final first = diff <= 0 ? node.left : node.right;
    final second = diff <= 0 ? node.right : node.left;

    if (first != null) _searchKNN(first, query, k, results);
    if (second != null && diff * diff < (results.isEmpty ? double.infinity : results.last.distance)) {
      _searchKNN(second, query, k, results);
    }
  }

  double _squaredDistance(Float32List a, Float32List b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return sum;
  }

  int get size => _entries.length;
}

class VectorEntry {
  final String id;
  final Float32List vector;

  VectorEntry({required this.id, required this.vector});
}

class KDNode {
  final VectorEntry? entry;
  final int axis;
  final KDNode? left;
  final KDNode? right;

  KDNode({required this.entry, required this.axis, this.left, this.right});

  KDNode.empty() : entry = null, axis = -1, left = null, right = null;

  bool get isEmpty => entry == null;
}

class SearchResult {
  final String id;
  final double distance;

  SearchResult({required this.id, required this.distance});
}