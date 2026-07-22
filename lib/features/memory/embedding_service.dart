import 'dart:math';

class EmbeddingService {
  static const int _vectorSize = 256;

  final List<double> _projectionMatrix;

  EmbeddingService() : _projectionMatrix = _generateProjection();

  static List<double> _generateProjection() {
    final rng = Random(42);
    return List.generate(_vectorSize * 1024, (_) => rng.nextDouble() * 2 * pi);
  }

  List<double> embed(String text) {
    final vector = List.filled(_vectorSize, 0.0);

    final words = _tokenize(text);
    if (words.isEmpty) return vector;

    final tf = <String, int>{};
    for (final w in words) {
      tf[w] = (tf[w] ?? 0) + 1;
    }

    for (final entry in tf.entries) {
      final tfVal = log(1 + entry.value);
      final idfVal = _idf[entry.key] ?? _defaultIdf(entry.key);
      final weight = tfVal * idfVal;

      final hash = _hashWord(entry.key);
      for (int i = 0; i < _vectorSize; i++) {
        final angle = _projectionMatrix[hash % _projectionMatrix.length + i];
        vector[i] += weight * sin(angle);
      }
    }

    // Word bigrams for local context
    for (int i = 0; i < words.length - 1; i++) {
      final bigram = '${words[i]}_${words[i + 1]}';
      final hash = _hashWord(bigram);
      for (int j = 0; j < _vectorSize; j++) {
        final angle = _projectionMatrix[(hash + j * 7) % _projectionMatrix.length];
        vector[j] += 0.4 * sin(angle);
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

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 2 && !_stopwords.contains(w))
        .toList();
  }

  double _defaultIdf(String word) {
    final len = word.length;
    if (len <= 2) return 0.3;
    if (len <= 4) return 0.5;
    if (len <= 6) return 0.7;
    return 0.9;
  }

  int _hashWord(String s) {
    int h = 0x811c9dc5;
    for (int i = 0; i < s.length; i++) {
      h ^= s.codeUnitAt(i);
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
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

  static final Set<String> _stopwords = {
    'the', 'be', 'to', 'of', 'and', 'in', 'that', 'have', 'it', 'for',
    'on', 'with', 'as', 'at', 'by', 'from', 'or', 'an', 'do', 'if',
    'this', 'but', 'not', 'they', 'is', 'are', 'was', 'were', 'been',
    'has', 'had', 'can', 'could', 'will', 'would', 'shall', 'should',
    'may', 'might', 'must', 'am', 'being', 'having', 'doing',
    'a', 'i', 'you', 'he', 'she', 'we',
    'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its',
    'our', 'their', 'what', 'which', 'who', 'whom', 'how', 'when',
    'where', 'why', 'all', 'each', 'every', 'both', 'few', 'more',
    'most', 'other', 'some', 'such', 'no', 'nor', 'only',
    'own', 'same', 'so', 'than', 'too', 'very', 'just', 'because',
    'about', 'above', 'after', 'again', 'also', 'any', 'before',
    'between', 'here', 'into', 'then', 'there', 'these', 'those',
    'through', 'under', 'until', 'while',
  };

  static final Map<String, double> _idf = {
    'information': 0.85, 'data': 0.82, 'system': 0.80, 'process': 0.78,
    'function': 0.76, 'method': 0.75, 'class': 0.74, 'value': 0.73,
    'type': 0.72, 'file': 0.70, 'code': 0.69, 'test': 0.68, 'error': 0.67,
    'result': 0.66, 'return': 0.65, 'string': 0.64, 'number': 0.63,
    'text': 0.62, 'image': 0.61, 'video': 0.60, 'audio': 0.59,
    'screen': 0.58, 'app': 0.57, 'device': 0.55,
    'user': 0.54, 'password': 0.88, 'email': 0.87, 'address': 0.86,
    'phone': 0.84, 'date': 0.83, 'time': 0.81, 'name': 0.79,
    'question': 0.77, 'answer': 0.71, 'problem': 0.60, 'solution': 0.59,
    'model': 0.85, 'network': 0.83, 'algorithm': 0.82, 'memory': 0.81,
    'search': 0.78, 'database': 0.77, 'server': 0.76, 'client': 0.75,
    'request': 0.74, 'response': 0.73, 'security': 0.80, 'encryption': 0.86,
    'permission': 0.82, 'authentication': 0.88, 'backup': 0.84,
    'financial': 0.90, 'payment': 0.89, 'transaction': 0.87,
    'stock': 0.91, 'market': 0.88, 'investment': 0.92, 'profit': 0.90,
    'revenue': 0.89, 'budget': 0.87, 'expense': 0.88, 'salary': 0.91,
    'health': 0.86, 'medical': 0.89, 'doctor': 0.90, 'hospital': 0.88,
    'medicine': 0.87, 'treatment': 0.85, 'diagnosis': 0.91,
    'car': 0.70, 'vehicle': 0.85, 'automobile': 0.92, 'drive': 0.65,
    'engine': 0.80, 'motor': 0.78, 'fuel': 0.82,
    'run': 0.40, 'walk': 0.55, 'move': 0.45, 'go': 0.30,
    'happy': 0.75, 'sad': 0.70, 'angry': 0.72, 'excited': 0.78,
    'love': 0.73, 'hate': 0.71, 'like': 0.35, 'enjoy': 0.65,
    'big': 0.40, 'small': 0.42, 'large': 0.50, 'tiny': 0.68,
    'fast': 0.55, 'slow': 0.52, 'quick': 0.53, 'rapid': 0.72,
    'book': 0.65, 'read': 0.50, 'write': 0.48, 'story': 0.70,
    'novel': 0.80, 'chapter': 0.82, 'page': 0.60, 'paper': 0.68,
    'learn': 0.55, 'study': 0.60, 'teach': 0.65, 'education': 0.85,
    'school': 0.75, 'university': 0.82, 'student': 0.78, 'teacher': 0.80,
    'work': 0.40, 'job': 0.45, 'career': 0.75, 'office': 0.65,
    'meeting': 0.70, 'project': 0.68, 'deadline': 0.80, 'task': 0.62,
    'food': 0.60, 'eat': 0.45, 'drink': 0.50, 'cook': 0.55,
    'restaurant': 0.80, 'recipe': 0.82, 'meal': 0.70, 'dinner': 0.68,
    'travel': 0.75, 'trip': 0.65, 'flight': 0.78, 'hotel': 0.80,
    'vacation': 0.82, 'destination': 0.85, 'journey': 0.78,
    'music': 0.70, 'song': 0.65, 'album': 0.72, 'concert': 0.78,
    'movie': 0.68, 'film': 0.66, 'watch': 0.50, 'listen': 0.55,
    'game': 0.60, 'play': 0.42, 'score': 0.65, 'team': 0.68,
    'weather': 0.75, 'rain': 0.68, 'sun': 0.60, 'cold': 0.58,
    'hot': 0.50, 'temperature': 0.82, 'forecast': 0.85,
    'price': 0.65, 'cost': 0.55, 'buy': 0.48, 'sell': 0.50,
    'shop': 0.60, 'store': 0.58, 'sale': 0.55, 'discount': 0.78,
  };
}
