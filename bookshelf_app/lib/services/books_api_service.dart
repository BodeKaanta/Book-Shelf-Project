import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/book.dart';
import 'book_recognition_service.dart';

// Injected at build time: flutter run --dart-define-from-file=.env
const _apiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

class BooksApiService {
  Future<({List<Book> books, String query})> searchBooks(OcrResult ocr) async {
    if (ocr.lines.isEmpty) return (books: <Book>[], query: '');

    final query = _buildSearchQuery(ocr);
    if (query.isEmpty) return (books: <Book>[], query: '');

    // Apply OCR corrections first — fall back to original if corrections break the query
    final correctedQuery = _applyOcrCorrections(query);
    List<Book> books;
    String usedQuery;
    final corrected =
        correctedQuery != query ? await _fetchBooks(correctedQuery) : null;
    if (corrected != null) {
      books = corrected;
      usedQuery = correctedQuery;
    } else {
      books = await _fetchBooks(query) ?? <Book>[];
      usedQuery = query;
    }

    // Rescore candidates by how closely each title matches the OCR text —
    // recovers the right book when the title line was garbled but survived elsewhere
    return (books: _rerankByFuzzyMatch(books, ocr.lines), query: usedQuery);
  }

  Future<List<Book>?> _fetchBooks(String query) async {
    final uri = Uri.parse(
      '$googleBooksBaseUrl?q=${Uri.encodeComponent(query)}&maxResults=5&key=$_apiKey',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>?;
    if (items == null) return null;

    return items
        .whereType<Map<String, dynamic>>()
        .map(Book.fromGoogleBooksJson)
        .toList();
  }

  // Reorder candidates so the one whose title best matches the OCR text wins.
  // Only reorders when a genuinely close match exists (>= threshold), otherwise
  // trusts Google's ranking — keeps clean-photo results stable.
  static const double _fuzzyMatchThreshold = 0.6;

  List<Book> _rerankByFuzzyMatch(List<Book> books, List<OcrLine> lines) {
    if (books.length < 2) return books;

    final ocrTokens = lines.expand((l) => _tokens(l.text)).toList();
    if (ocrTokens.isEmpty) return books;

    final scored = [
      for (var i = 0; i < books.length; i++)
        (
          book: books[i],
          index: i,
          score: _candidateMatchScore(books[i], ocrTokens),
        ),
    ];

    final best = scored.map((e) => e.score).reduce(max);
    if (best < _fuzzyMatchThreshold) return books;

    // Stable sort: highest score first, Google's order breaks ties
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.index.compareTo(b.index);
    });
    return [for (final e in scored) e.book];
  }

  double _candidateMatchScore(Book book, List<String> ocrTokens) {
    final titleScore = _avgBestSimilarity(_tokens(_coreTitle(book.title)), ocrTokens);
    final authorTokens = book.author == null ? <String>[] : _tokens(book.author!);
    if (authorTokens.isEmpty) return titleScore;
    return 0.6 * titleScore + 0.4 * _avgBestSimilarity(authorTokens, ocrTokens);
  }

  // Drop subtitle (after ':') and edition parentheticals like "(Movie Tie-In)"
  // so a longer edition title isn't penalised against a bare one
  String _coreTitle(String title) =>
      title.split(':').first.replaceAll(RegExp(r'\(.*?\)'), '');

  double _avgBestSimilarity(List<String> targets, List<String> pool) {
    if (targets.isEmpty) return 0.0;
    var sum = 0.0;
    for (final target in targets) {
      var best = 0.0;
      for (final candidate in pool) {
        final similarity = _normalizedSimilarity(target, candidate);
        if (similarity > best) best = similarity;
      }
      sum += best;
    }
    return sum / targets.length;
  }

  List<String> _tokens(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length >= 2)
      .toList();

  double _normalizedSimilarity(String a, String b) {
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    return 1.0 - _levenshtein(a, b) / maxLen;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = min(min(curr[j] + 1, prev[j + 1] + 1), prev[j] + cost);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }

  String _applyOcrCorrections(String query) {
    return query
        // V at word start before a vowel → Y (VEAR→YEAR, VELLOW→YELLOW)
        .replaceAllMapped(
          RegExp(r'\bV([AEIOU])'),
          (m) => 'Y${m[1]}',
        );
  }

  String _buildSearchQuery(OcrResult ocr) {
    final candidates = ocr.lines
        .where((l) => l.text.trim().length >= 4)
        .where((l) => !RegExp(r'^\d[\d:.,\s]*$').hasMatch(l.text.trim())) // pure numbers
        .where((l) => !RegExp(r'^\d{1,2}:\d{2}').hasMatch(l.text.trim())) // timestamps "13:24 A"
        .where((l) => !_isOcrGarbage(l.text.trim())) // mixed-case OCR noise like "NoTEB O OK"
        .where((l) => !_isPromotionalLine(l.text.trim())) // award/promo text
        .where((l) => !ocr.isScreenshot || !_isSocialUiLine(l.text.trim())) // social UI, screenshots only
        .toList();

    if (candidates.isEmpty) {
      final fallback = ocr.rawText.trim();
      return fallback.length > 120 ? fallback.substring(0, 120) : fallback;
    }

    final maxLineHeight = candidates
        .map((l) => l.boundingBox.height)
        .fold<double>(0, (a, b) => a > b ? a : b);

    candidates.sort((a, b) => _lineScore(b, ocr, maxLineHeight)
        .compareTo(_lineScore(a, ocr, maxLineHeight)));

    final query = candidates.take(3).map((l) => l.text.trim()).join(' ');
    return query.length > 120 ? query.substring(0, 120) : query;
  }

  // Social-media UI chrome: @handles, #hashtags, engagement counts, known strings.
  bool _isSocialUiLine(String line) {
    if (RegExp(r'^[@#]\w').hasMatch(line)) return true;
    if (RegExp(r'^\d+([.,]\d+)?[KMB]$').hasMatch(line)) return true; // "1.2M", "45K"
    const uiStrings = [
      'for you', 'following', 'add comment', 'add a comment', 'reply',
      'original sound', 'log in', 'sign up', 'send message', 'view profile',
    ];
    final lower = line.toLowerCase();
    return uiStrings.any((s) => lower == s);
  }

  bool _isPromotionalLine(String line) {
    final upper = line.toUpperCase();
    const keywords = [
      'LONGLISTED', 'SHORTLISTED', 'PRIZE', 'AWARD', 'WINNER',
      'BESTSELLER', 'BESTSELLING', 'FINALIST', 'BOOKER', 'PULITZER',
      'INTRODUCTION',
    ];
    return keywords.any((k) => upper.contains(k));
  }

  // Filters lines where more than 25% of words have suspicious mixed casing
  // e.g. "NoTEB O OK", "TENZs", "DuK" — hallmarks of OCR misreads
  bool _isOcrGarbage(String line) {
    final words = line.split(' ').where((w) => w.length >= 3).toList();
    if (words.isEmpty) return false;
    final garbageCount = words.where(_isSuspiciousWord).length;
    return garbageCount / words.length > 0.25;
  }

  bool _isSuspiciousWord(String word) {
    if (word == word.toUpperCase()) return false;
    if (word == word.toLowerCase()) return false;

    // Split at every lowercase→uppercase boundary to handle compound surnames
    // e.g. "McCann" → ["Mc","Cann"], "FitzGerald" → ["Fitz","Gerald"]
    // Then also split at non-alphabetic characters for names like "O'Brien"
    final segments = word
        .split(RegExp(r"(?<=[a-z])(?=[A-Z])|[^a-zA-Z]+"))
        .where((s) => s.isNotEmpty)
        .toList();

    return !segments.every((s) =>
        s == s.toUpperCase() ||
        (s[0] == s[0].toUpperCase() &&
            s.substring(1) == s.substring(1).toLowerCase()));
  }

  double _lineScore(OcrLine line, OcrResult ocr, double maxLineHeight) {
    final base = _baseTextScore(line.text.trim());
    if (!ocr.isScreenshot) return base;
    return base *
        _zoneMultiplier(line, ocr.imageHeight) *
        _sizeMultiplier(line, maxLineHeight);
  }

  // Penalise TikTok/Instagram nav (top ~15%) and caption (bottom ~30%) zones.
  double _zoneMultiplier(OcrLine line, int imageHeight) {
    final box = line.boundingBox;
    if (imageHeight == 0 || box.height == 0) return 1.0;
    final center = (box.top + box.bottom) / 2 / imageHeight;
    if (center < 0.15 || center > 0.70) return 0.4;
    return 1.0;
  }

  // Book titles are large display type; usernames/captions are small UI text.
  double _sizeMultiplier(OcrLine line, double maxLineHeight) {
    final height = line.boundingBox.height;
    if (maxLineHeight == 0 || height == 0) return 1.0;
    return 0.5 + (height / maxLineHeight);
  }

  double _baseTextScore(String line) {
    // "Title: Author, First:" format — high-value metadata, score above blurb names
    if (line.contains(':')) return 0.85;

    final letters = line
        .split('')
        .where((c) => RegExp(r'[a-zA-Z]').hasMatch(c))
        .toList();
    if (letters.isEmpty) return 0.0;

    final capsRatio =
        letters.where((c) => c == c.toUpperCase()).length / letters.length;
    // Penalise long lines — usually descriptions, captions, or subtitles
    final lengthPenalty = line.length > 25 ? 0.4 : 1.0;
    final capsScore = capsRatio * lengthPenalty;

    // Boost title-case multi-word lines — author names like "Nicholas Sparks"
    // and store labels like "House of Government" have low caps ratio but high value
    final words = line.split(' ').where((w) => w.length >= 2).toList();
    final titleCaseWords = words
        .where((w) =>
            w[0] == w[0].toUpperCase() &&
            w.substring(1) == w.substring(1).toLowerCase())
        .length;
    final titleScore = words.length >= 2
        ? (titleCaseWords / words.length) * 0.65 * lengthPenalty
        : 0.0;

    return capsScore > titleScore ? capsScore : titleScore;
  }
}
