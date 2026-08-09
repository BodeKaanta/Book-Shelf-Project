import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/recognition_log.dart';
import '../models/book.dart';
import 'book_recognition_service.dart';

// Open Library needs no key. Kept for a fast switch back to Google Books (#75).
// Injected at build time: flutter run --dart-define-from-file=.env
// const _apiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

class BooksApiService {
  Future<({List<Book> books, String query, double confidence})> searchBooks(
      OcrResult ocr) async {
    if (ocr.lines.isEmpty) return (books: <Book>[], query: '', confidence: 0.0);

    final query = buildSearchQuery(ocr);
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
      for (final retry in [relaxedQuery(ocr), despacedQuery(ocr)]) {
        if (retry == null || retry.isEmpty || retry == usedQuery) continue;
        final retried = await _fetchBooks(retry) ?? <Book>[];
        if (_bestFuzzyScore(retried, ocrTokens) >
            _bestFuzzyScore(books, ocrTokens)) {
          books = retried;
          usedQuery = retry;
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

  // Free-text search for the manual search screen — no OCR scoring, just what
  // the user typed.
  Future<List<Book>> searchByText(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return <Book>[];
    return await _fetchBooks(trimmed, 10) ?? <Book>[];
  }

  Future<List<Book>?> _fetchBooks(String query, [int maxResults = 5]) async {
    final uri = Uri.parse(
      '$openLibraryBaseUrl?q=${Uri.encodeComponent(query)}&limit=$maxResults'
      '&fields=key,title,author_name,cover_i,number_of_pages_median,subject',
    );

    final http.Response response;
    try {
      response = await http
          .get(uri, headers: {'User-Agent': openLibraryUserAgent})
          .timeout(bookLookupTimeout);
    } on Exception catch (error) {
      logLookupFailure(query, 'request failed: $error');
      return null;
    }
    if (response.statusCode != 200) {
      logLookupFailure(query, 'HTTP ${response.statusCode}');
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final docs = data['docs'] as List<dynamic>?;
    // Google Books omitted `items` entirely on a miss; Open Library always
    // returns `docs`, empty. Callers distinguish null (try another query) from
    // a non-empty list, so an empty result must stay null or the retry paths
    // above are skipped.
    if (docs == null || docs.isEmpty) {
      logLookupFailure(query, 'no results');
      return null;
    }

    return docs
        .whereType<Map<String, dynamic>>()
        .map(Book.fromOpenLibraryJson)
        .toList();
  }

  // Google Books fetch — kept for a fast switch back if its corpus recovers.
  // Future<List<Book>?> _fetchBooksGoogle(String query,
  //     [int maxResults = 5]) async {
  //   final uri = Uri.parse(
  //     '$googleBooksBaseUrl?q=${Uri.encodeComponent(query)}&maxResults=$maxResults&key=$_apiKey',
  //   );
  //
  //   final response = await http.get(uri);
  //   if (response.statusCode != 200) return null;
  //
  //   final data = json.decode(response.body) as Map<String, dynamic>;
  //   final items = data['items'] as List<dynamic>?;
  //   if (items == null) return null;
  //
  //   return items
  //       .whereType<Map<String, dynamic>>()
  //       .map(Book.fromGoogleBooksJson)
  //       .toList();
  // }

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

  static const int _maxQueryLines = 3;

  // The lines that become the query, in the order they appear on the cover.
  List<OcrLine> _selectLines(OcrResult ocr, int limit) {
    // Cover text repeats — spine plus front, or OCR reading one band twice.
    // Deduping frees the slot for a line that says something new ("EMILY EMILY
    // EMILY" was a whole query). Keep the *least fragmented* reading: letter-
    // spaced type comes back in pieces ("TRAN SFOR MED") while the same words
    // often survive intact elsewhere on the cover ("Transformed"), and only the
    // intact one retrieves anything.
    final byText = <String, OcrLine>{};
    for (final line in ocr.lines) {
      if (!_isUsableLine(line, ocr)) continue;
      final key = _normalize(line.text.trim());
      final kept = byText[key];
      if (kept == null || _fragmentCount(line) < _fragmentCount(kept)) {
        byText[key] = line;
      }
    }
    // Map preserves insertion order and replacing a value keeps its original
    // position, so the index tiebreak below still follows OCR order.
    final candidates = byText.values.toList();
    if (candidates.isEmpty) return const [];

    final maxLineHeight = candidates
        .map((l) => l.boundingBox.height)
        .fold<double>(0, (a, b) => a > b ? a : b);

    final ranked = [
      for (var i = 0; i < candidates.length; i++)
        (
          line: candidates[i],
          index: i,
          score: _lineScore(candidates[i], ocr, maxLineHeight),
        ),
    ].where((e) => e.score > 0).toList()
      // Every ALL-CAPS line scores exactly 1.0, so ties are the common case and
      // List.sort is not stable — without the index tiebreak the same photo can
      // build a different query on each run.
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.index.compareTo(b.index);
      });

    // Back into reading order. A title split over several lines ("THE | LORD |
    // OF THE | RINGS") is only a title in the order it was printed; emitting it
    // in score order also made the _firstWords retry below relax to arbitrary
    // words rather than to the leading title words it documents.
    return [for (final e in ranked.take(limit)) e.line]
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
  }

  int _fragmentCount(OcrLine line) =>
      line.text.trim().split(RegExp(r'\s+')).length;

  @visibleForTesting
  String buildSearchQuery(OcrResult ocr) {
    final selected = _selectLines(ocr, _maxQueryLines);
    if (selected.isEmpty) {
      final fallback = ocr.rawText.trim();
      return _capped(fallback);
    }
    return _capped(_joinLines(selected.map((l) => l.text.trim())));
  }

  // Open Library's Solr effectively ANDs the terms, so one junk line zeroes the
  // result set. Dropping the weakest selected line is the retry: it relaxes by
  // whole lines rather than by word count, which used to cut mid-phrase
  // ("ITALO CALVINO" -> "ITALO", "Transformed Remi Adeleke" -> "ANAVY SEAL'S
  // UNLIKELY") and threw away the very words that identify the book.
  @visibleForTesting
  String? relaxedQuery(OcrResult ocr) {
    final selected = _selectLines(ocr, _maxQueryLines - 1);
    if (selected.isEmpty) return null;
    final query = _capped(_joinLines(selected.map((l) => l.text.trim())));
    return query == buildSearchQuery(ocr) ? null : query;
  }

  // Collapse per line, never across the join: a line starting "A Saga of…"
  // would otherwise glue its "A" onto the previous line's last word
  // ("THE HOUSE OF" + "A SAGA" -> "THE HOUSE OFA SAGA").
  String _joinLines(Iterable<String> lines) =>
      lines.map(_collapseSpacedLetters).join(' ');

  // Letter-spaced cover type ("NoTEB OO K") reaches us as fragments that no
  // filter can repair, and the fragments retrieve nothing. Gluing the leading
  // line back into one word gives the retry a real title to search for. Only
  // ever a retry: searchBooks keeps it if it matches the OCR better than the
  // primary query, so a wrong glue costs a request and nothing else.
  @visibleForTesting
  String? despacedQuery(OcrResult ocr) {
    final selected = _selectLines(ocr, _maxQueryLines);
    if (selected.isEmpty) return null;
    final glued = selected.first.text.trim().replaceAll(RegExp(r'\s+'), '');
    final query = _capped(
        _joinLines([glued, for (final l in selected.skip(1)) l.text.trim()]));
    return query == buildSearchQuery(ocr) ? null : query;
  }

  String _capped(String query) =>
      query.length > 120 ? query.substring(0, 120) : query;

  bool _isUsableLine(OcrLine line, OcrResult ocr) {
    final text = line.text.trim();
    if (_letterCount(text) < 4) return false; // "J.RR.", "#1", "l04", "TD D"
    if (text.length > 40) return false; // review blurbs / long quotes
    if (_isRotated(line)) return false; // spine of a neighbouring book
    if (RegExp(r'^\d[\d:.,\s]*$').hasMatch(text)) return false; // pure numbers
    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(text)) return false; // "13:24 M"
    if (_isReviewQuote(text)) return false;
    if (_isOcrGarbage(text)) return false;
    if (_isPromotionalLine(text)) return false;
    if (_isGenericTagline(text)) return false;
    if (_isPublisher(text)) return false;
    if (_isAttribution(text)) return false;
    if (_isEditionInfo(text)) return false;
    if (_isCreditLine(text)) return false;
    if (ocr.isScreenshot && _isSocialUiLine(text)) return false;
    return true;
  }

  int _letterCount(String text) => RegExp(r'[A-Za-z]').allMatches(text).length;

  // ML Kit reports rotated text with a box taller than it is wide — the spines
  // of neighbouring books on a shelf, and vertical cover bands. Horizontal
  // cover text of four or more characters is always wider than it is tall.
  bool _isRotated(OcrLine line) =>
      line.boundingBox.height > line.boundingBox.width;

  // Cover furniture ('"VERY, VERY SCARY !"-WIRED'). Titles carry no quote
  // marks, so the mark itself is the signal — anchoring to the start of the
  // line misses quotes OCR splits mid-sentence.
  bool _isReviewQuote(String line) => RegExp(r'["“”„]').hasMatch(line);

  // "EDITED BY …", "ILLUSTRATED BY …" — credits, never the title.
  bool _isCreditLine(String line) => RegExp(
        r'\b(EDITED|ILLUSTRATED|TRANSLATED|FOREWORD|AFTERWORD|PHOTOGRAPHS)\s+BY\b',
      ).hasMatch(line.toUpperCase());

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
    // Article/source chrome: "en.wikipedia.org"
    if (RegExp(r'\b\w+\.(com|org|net|edu|gov|io)\b').hasMatch(line.toLowerCase())) {
      return true;
    }
    // Compared normalized so OCR's trailing punctuation ("Add comment..")
    // still matches.
    const uiStrings = {
      'foryou', 'following', 'follow', 'addcomment', 'addacomment', 'reply',
      'originalsound', 'login', 'signup', 'sendmessage', 'viewprofile',
      'share', 'save', 'home', 'search', 'notifications', 'activity', 'visit',
      'goodreads', 'booktok', 'bookstagram', 'learnmore', 'seemore',
    };
    return uiStrings.contains(_normalize(line));
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
  // Normalized, because OCR splits these too ("mTH ANNIVERSARYONE-VOLUMEEDITION").
  bool _isEditionInfo(String line) {
    final normalized = _normalize(line);
    if (normalized.contains('anniversary')) return true;
    if (normalized.contains('edition')) return true;
    if (normalized.endsWith('series')) return true; // "SOUTHERN REACH SERIES"
    final upper = line.toUpperCase();
    return RegExp(r'\bBOOK\s+\d+\s+OF\b').hasMatch(upper) ||
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

  // Matched against the letters-only form of the line, because OCR splits these
  // bands unpredictably — "BES TSELLER", "NATIONAL BESTSELL ER", "#1 NE W YO RK
  // TIME S BES TSELLER" all normalize back onto the same keywords, and the
  // manglings cannot be enumerated.
  static const _promoKeywords = [
    'longlisted', 'shortlisted', 'prize', 'award', 'winner', 'finalist',
    'bestseller', 'bestselling', 'seller', 'booker', 'pulitzer',
    'introduction', 'newyorktimes', 'sundaytimes', 'usatoday',
    'readwith', 'bookclub', 'authorof',
    // Film/TV adaptation banners
    'motionpicture', 'majormotion', 'netflix', 'soontobe', 'nowamajor',
  ];

  // Book-club endorsements print the brand on its own line, so OCR leaves an
  // orphan ("READ WITH" / "JENNA") once the band line is dropped. Matched whole
  // -line rather than by substring, so a real title keeps its name.
  static const _bookClubBrands = {
    'jenna', 'reese', 'oprah', 'readwithjenna', 'reesesbookclub',
  };

  bool _isPromotionalLine(String line) {
    // A rank marker is never part of a title: "#1 NEW YO", "THE #L NEW YORK…"
    if (RegExp(r'#\s*[1lLiI]').hasMatch(line)) return true;
    final normalized = _normalize(line);
    if (_bookClubBrands.contains(normalized)) return true;
    return _promoKeywords.any(normalized.contains);
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
    // Checked before the all-caps shortcut below: cover garbage is usually ALL
    // CAPS ("20SE GcODE"), so it used to dodge rejection here and then score as
    // a title in _baseTextScore.
    if (_isImplausibleWord(word)) return true;
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

  // Digits fused into a word ("20SE"), or a letter run with no vowel at all —
  // OCR noise whatever the casing. No real title word looks like either.
  bool _isImplausibleWord(String word) {
    final letters = word.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 3) return false;
    if (RegExp(r'\d').hasMatch(word)) return true;
    return !RegExp(r'[AEIOUYaeiouy]').hasMatch(letters);
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
    // Single words count too: one-word titles ("Unbecoming", "Overstory",
    // "Authority") have a low caps ratio, so gating this at two words left them
    // scoring ~0.1 and losing to any title-cased junk line.
    final titleScore = words.isEmpty
        ? 0.0
        : (titleCaseWords / words.length) * 0.65 * lengthPenalty;

    return capsScore > titleScore ? capsScore : titleScore;
  }
}
