import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/book.dart';

class BooksApiService {
  Future<({List<Book> books, String query})> searchBooks(
      String rawOcrText) async {
    if (rawOcrText.trim().isEmpty) return (books: <Book>[], query: '');

    final query = _buildSearchQuery(rawOcrText);
    if (query.isEmpty) return (books: <Book>[], query: '');

    final apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
    final uri = Uri.parse(
      '$googleBooksBaseUrl?q=${Uri.encodeComponent(query)}&maxResults=5&key=$apiKey',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return (books: <Book>[], query: query);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>?;
    if (items == null) return (books: <Book>[], query: query);

    final books = items
        .whereType<Map<String, dynamic>>()
        .map(Book.fromGoogleBooksJson)
        .toList();

    return (books: books, query: query);
  }

  String _buildSearchQuery(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 4)
        .where((l) => !RegExp(r'^\d[\d:.,\s]*$').hasMatch(l)) // pure numbers
        .where((l) => !RegExp(r'^\d{1,2}:\d{2}').hasMatch(l)) // timestamps "13:24 A"
        .where((l) => !_isOcrGarbage(l)) // mixed-case OCR noise like "NoTEB O OK"
        .where((l) => !_isPromotionalLine(l)) // award/promo text like "LONGLISTED FOR THE"
        .toList();

    if (lines.isEmpty) {
      final fallback = rawText.trim();
      return fallback.length > 120 ? fallback.substring(0, 120) : fallback;
    }

    lines.sort((a, b) => _lineScore(b).compareTo(_lineScore(a)));

    final query = lines.take(3).join(' ');
    return query.length > 120 ? query.substring(0, 120) : query;
  }

  // Filters lines where more than 40% of words have suspicious mixed casing
  // e.g. "NoTEB O OK", "TENZs", "DuK" — hallmarks of OCR misreads
  bool _isPromotionalLine(String line) {
    final upper = line.toUpperCase();
    const keywords = [
      'LONGLISTED', 'SHORTLISTED', 'PRIZE', 'AWARD', 'WINNER',
      'BESTSELLER', 'BESTSELLING', 'FINALIST', 'BOOKER', 'PULITZER',
      'INTRODUCTION',
    ];
    return keywords.any((k) => upper.contains(k));
  }

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

  double _lineScore(String line) {
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
