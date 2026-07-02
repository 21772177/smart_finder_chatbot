import 'dart:math';

class EmbeddingService {
  static const int _vectorSize = 256;
  static const int _ngramMin = 2;
  static const int _ngramMax = 4;

  final List<int> _hashSeeds;

  EmbeddingService() : _hashSeeds = _generateSeeds();

  static List<int> _generateSeeds() {
    final rng = Random(42);
    return List.generate(_vectorSize, (_) => rng.nextInt(1 << 31));
  }

  List<double> embed(String text) {
    final vector = List.filled(_vectorSize, 0.0);
    final normalized = text.toLowerCase();
    final ngrams = <String>{};

    for (int n = _ngramMin; n <= _ngramMax; n++) {
      for (int i = 0; i <= normalized.length - n; i++) {
        ngrams.add(normalized.substring(i, i + n));
      }
    }

    for (final ngram in ngrams) {
      for (int i = 0; i < _vectorSize; i++) {
        final hash = _hash(ngram, _hashSeeds[i]);
        vector[i] += hash;
      }
    }

    final magnitude = sqrt(vector.fold(0.0, (sum, v) => sum + v * v));
    if (magnitude > 0) {
      for (int i = 0; i < _vectorSize; i++) {
        vector[i] /= magnitude;
      }
    }

    return vector;
  }

  int _hash(String s, int seed) {
    int h = seed;
    for (int i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return h % 2 == 0 ? 1 : -1;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final denom = sqrt(magA) * sqrt(magB);
    return denom == 0 ? 0 : dot / denom;
  }

  String vectorToJson(List<double> v) {
    return v.map((e) => e.toStringAsFixed(6)).join(',');
  }

  List<double> jsonToVector(String json) {
    return json.split(',').map((e) => double.tryParse(e) ?? 0.0).toList();
  }
}
