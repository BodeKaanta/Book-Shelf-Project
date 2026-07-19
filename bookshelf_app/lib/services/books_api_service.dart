import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/book.dart';
import 'book_recognition_service.dart';

// Injected at build time: flutter run --dart-define-from-file=.env
const _apiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

class BooksApiService {
  Future<({List<Book> books, String query, double confidence})> searchBooks(
      OcrResult ocr) async {
    if (ocr.lines.isEmpty) return (books: <Book>[], query: '', confidence: 0.0);

    final query = _buildSearchQuery(ocr);
    if (query.isEmpty) return (books: <Book>[], query: '', confidence: 0.0);

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

    // Relax when the search found nothing, OR nothing that matches what we
    // actually read — a noisy line (web-shop name, junk term) can zero out
    // results or retrieve confident-but-wrong books. Retrying with just the
    // leading title words recovers the real book. Only keep the retry if it
    // matches the OCR better, so relaxation can never make things worse.
    final ocrTokens = ocr.lines.expand((l) => _tokens(l.text)).toList();
    if (books.isEmpty || _bestFuzzyScore(books, ocrTokens) < _fuzzyMatchThreshold) {
      final relaxed = _firstWords(usedQuery, 3);
      if (relaxed != usedQuery) {
        final relaxedResult = await _fetchBooks(relaxed) ?? <Book>[];
        if (_bestFuzzyScore(relaxedResult, ocrTokens) >
            _bestFuzzyScore(books, ocrTokens)) {
          books = relaxedResult;
          usedQuery = relaxed;
        }
      }
    }

    // Rescore candidates by how closely each title matches the OCR text —
    // recovers the right book when the title line was garbled but survived elsewhere
    final reranked = _rerankByFuzzyMatch(books, ocr.lines);
    return (
      books: reranked,
      query: usedQuery,
      confidence: _confidence(reranked, ocrTokens),
    );
  }

  // 0..1 confidence that the top result is the right book: how well it matches
  // the OCR, plus how clearly it beats the runner-up (a common title with many
  // near-equal editions is ambiguous -> lower confidence -> should be reviewed).
  // HOMEMADE HEURISTIC — the auto-add threshold is meaningless until calibrated
  // against real photos (#42).
  double _confidence(List<Book> books, List<String> ocrTokens) {
    if (books.isEmpty || ocrTokens.isEmpty) return 0.0;
    final top = _candidateMatchScore(books.first, ocrTokens);
    final second =
        books.length > 1 ? _candidateMatchScore(books[1], ocrTokens) : 0.0;
    final margin = (top - second).clamp(0.0, 1.0);
    return (0.7 * top + 0.3 * margin).clamp(0.0, 1.0);
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

  double _bestFuzzyScore(List<Book> books, List<String> ocrTokens) {
    if (books.isEmpty || ocrTokens.isEmpty) return 0.0;
    return books.map((b) => _candidateMatchScore(b, ocrTokens)).reduce(max);
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
        .where((l) => l.text.trim().length <= 40) // drop review blurbs / long quotes
        .where((l) => !RegExp(r'^\d[\d:.,\s]*$').hasMatch(l.text.trim())) // pure numbers
        .where((l) => !RegExp(r'^\d{1,2}:\d{2}').hasMatch(l.text.trim())) // timestamps "13:24 A"
        .where((l) => !_isOcrGarbage(l.text.trim())) // mixed-case OCR noise like "NoTEB O OK"
        .where((l) => !_isPromotionalLine(l.text.trim())) // award/promo/bestseller-band text
        .where((l) => !_isGenericTagline(l.text.trim())) // "A NOVEL", "A MEMOIR"
        .where((l) => !_isPublisher(l.text.trim())) // publisher name lines like "BLOOMSBURY"
        .where((l) => !_isAttribution(l.text.trim())) // "— Dallas Morning News"
        .where((l) => !_isEditionInfo(l.text.trim())) // "10th Anniversary Edition", "Book 2 of"
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

    final joined = candidates.take(3).map((l) => l.text.trim()).join(' ');
    final query = _collapseSpacedLetters(joined);
    return query.length > 120 ? query.substring(0, 120) : query;
  }

  String _firstWords(String query, int n) =>
      query.split(RegExp(r'\s+')).take(n).join(' ');

  // Cover letter-spacing makes OCR split a word into single letters
  // ("NoTEB O O K"). Glue standalone letters onto the preceding word so the
  // title survives as one token ("NoTEBOOK"). Leaves author initials searchable.
  String _collapseSpacedLetters(String query) {
    final result = <String>[];
    for (var token in query.split(RegExp(r'\s+'))) {
      token = token.replaceFirst(RegExp(r'^[-+]+'), ''); // never send Google an operator
      if (token.isEmpty) continue;
      if (token.length == 1 &&
          RegExp(r'[A-Za-z]').hasMatch(token) &&
          result.isNotEmpty) {
        result[result.length - 1] += token;
      } else {
        result.add(token);
      }
    }
    return result.join(' ');
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

  // Strip to letters only so OCR word-splitting ("BLOO M S BURY", "A NO VEL")
  // still matches its true form ("bloomsbury", "anovel")
  String _normalize(String line) =>
      line.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  // Generic cover taglines — never useful as search terms, and when they read
  // as short all-caps ("A NOVEL") they otherwise score max and hijack the query
  bool _isGenericTagline(String line) {
    const taglines = {'anovel', 'anovelby', 'amemoir', 'anovella', 'atruestory'};
    return taglines.contains(_normalize(line));
  }

  // Review-source attributions ("— Dallas Morning News", "- Sunday Times") —
  // pure noise, and the leading dash is a Google Books negation operator
  bool _isAttribution(String line) => RegExp(r'^\s*[-–—]').hasMatch(line);

  // Edition/series banner text ("10th Anniversary Edition", "Book 2 of the …",
  // "Volume 3") — never a search term. Kept narrow (needs an edition keyword or
  // a number) so real titles like "Book of the Dead" aren't dropped.
  bool _isEditionInfo(String line) {
    final upper = line.toUpperCase();
    return upper.contains('ANNIVERSARY EDITION') ||
        RegExp(r'\b\d+(ST|ND|RD|TH)\s+ANNIVERSARY\b').hasMatch(upper) ||
        RegExp(r'\b(DELUXE|SPECIAL|COLLECTOR.?S|REVISED|EXPANDED|ILLUSTRATED)\s+EDITION\b')
            .hasMatch(upper) ||
        RegExp(r'\bBOOK\s+\d+\s+OF\b').hasMatch(upper) ||
        RegExp(r'\bVOL(?:UME|\.)?\s*\d+\b').hasMatch(upper);
  }

  // Publisher name lines — a whole line that is just the publisher is noise
  bool _isPublisher(String line) {
    const publishers = {
      'bloomsbury', 'penguin', 'penguinbooks', 'penguinrandomhouse', 'vintagebooks',
      'harpercollins', 'randomhouse', 'macmillan', 'panmacmillan', 'simonschuster',
      'hachette', 'faberandfaber', 'doubleday', 'scholastic', 'picador', 'littlebrown',
    };
    return publishers.contains(_normalize(line));
  }

  bool _isPromotionalLine(String line) {
    final upper = line.toUpperCase();
    const keywords = [
      'LONGLISTED', 'SHORTLISTED', 'PRIZE', 'AWARD', 'WINNER',
      'BESTSELLER', 'BESTSELLING', 'FINALIST', 'BOOKER', 'PULITZER',
      'INTRODUCTION', 'NEW YORK TIMES', 'SUNDAY TIMES', 'BEST SELLER',
      'NATIONAL BESTSELLER',
      // Film/TV adaptation banners
      'MOTION PICTURE', 'MAJOR MOTION', 'NETFLIX', 'SOON TO BE', 'NOW A MAJOR',
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
