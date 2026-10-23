import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String? googleBooksId;
  final String? author;
  final String? coverUrl;
  final String? description;
  final String? genre;
  final int? pageCount;
  final String? publishedDate;
  final String? isbn;
  final DateTime dateAdded;

  Book({
    required this.id,
    required this.title,
    required this.dateAdded,
    this.googleBooksId,
    this.author,
    this.coverUrl,
    this.description,
    this.genre,
    this.pageCount,
    this.publishedDate,
    this.isbn,
  });

  // Google gives "2018-04-03", "2018-04" or "2018" depending on the edition, so
  // the year is the leading four digits rather than a parsed date.
  String? get year =>
      RegExp(r'^\d{4}').firstMatch(publishedDate ?? '')?.group(0);

  // `googleBooksId` holds an Open Library work key ("/works/OL21745884W") while
  // Open Library is the source. Kept under the old name so existing Firestore
  // documents and the title+author dedup keep working (#75).
  factory Book.fromOpenLibraryJson(Map<String, dynamic> json) {
    final authors = json['author_name'] as List<dynamic>?;
    final coverId = json['cover_i'] as int?;

    return Book(
      id: '',
      googleBooksId: json['key'] as String?,
      title: json['title'] as String? ?? 'Unknown Title',
      author: authors?.isNotEmpty == true ? authors!.first as String : null,
      coverUrl: coverId != null
          ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
          : null,
      // search.json carries no description — that needs a second /works fetch.
      description: null,
      genre: _firstSubject(json['subject'] as List<dynamic>?),
      pageCount: json['number_of_pages_median'] as int?,
      publishedDate: (json['first_publish_year'] as int?)?.toString(),
      // No isbn: search.json lists every edition's ISBN for the work, including
      // translations, so any one of them may be a different book to buy.
      dateAdded: DateTime.now(),
    );
  }

  // Open Library subjects are noisy lowercase tags ("hard science-fiction",
  // "sci-fi"). Home rows and the Library filter chips display this, so take the
  // first and title-case it.
  static String? _firstSubject(List<dynamic>? subjects) {
    if (subjects == null || subjects.isEmpty) return null;
    return (subjects.first as String)
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  factory Book.fromGoogleBooksJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final categories = volumeInfo['categories'] as List<dynamic>?;

    return Book(
      id: '',
      googleBooksId: json['id'] as String?,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      author: authors?.isNotEmpty == true ? authors!.first as String : null,
      coverUrl: googleCoverUrl(imageLinks?['thumbnail'] as String?),
      description: volumeInfo['description'] as String?,
      genre: categories?.isNotEmpty == true ? categories!.first as String : null,
      pageCount: _knownPageCount(volumeInfo['pageCount'] as int?),
      publishedDate: volumeInfo['publishedDate'] as String?,
      isbn: _isbn(volumeInfo['industryIdentifiers'] as List<dynamic>?),
      dateAdded: DateTime.now(),
    );
  }

  // Google reports 0 for an edition it has no count for, and "0 pages" is never
  // true. Also applied on read, for books saved before this was caught.
  static int? _knownPageCount(int? count) =>
      count != null && count > 0 ? count : null;

  // Stored now so buy links (#135) need no migration. ISBN-13 first: every
  // book with an ISBN has one, while 979- books have no ISBN-10 at all.
  static String? _isbn(List<dynamic>? identifiers) {
    String? ofType(String type) => identifiers
        ?.whereType<Map<String, dynamic>>()
        .where((id) => id['type'] == type)
        .map((id) => id['identifier'] as String?)
        .firstOrNull;
    return ofType('ISBN_13') ?? ofType('ISBN_10');
  }

  // `imageLinks.thumbnail` is only 128px wide — narrower than a library grid
  // tile, so using it verbatim ships blurrier covers than Open Library did.
  // `fife` selects a wider rendition of the same image server-side (no crop, no
  // magnification), and `edge=curl` paints a fake page-curl over the artwork.
  // Stored per book in Firestore, so the width is fixed at add time: 600 leaves
  // headroom for the book detail sidebar without needing a migration.
  static String? googleCoverUrl(String? thumbnail) {
    if (thumbnail == null || thumbnail.isEmpty) return null;
    final base = thumbnail
        .replaceFirst('http://', 'https://')
        .replaceFirst('&edge=curl', '')
        .replaceAll(RegExp(r'&fife=[^&]*'), ''); // never stack two widths
    return '$base&fife=w600';
  }

  // Same book, different edition: title before any subtitle, plus author, with
  // case and punctuation stripped. Editions differ by `googleBooksId`, so the id
  // is deliberately not part of this. Null when either half is missing — two
  // books with no author are not evidence of being the same book, and the
  // library dedup has always required both.
  static String? identityKey(String? title, String? author) {
    final titleKey = _identityPart(title == null ? null : coreTitle(title));
    final authorKey = _identityPart(author);
    if (titleKey.isEmpty || authorKey.isEmpty) return null;
    return '$titleKey|$authorKey';
  }

  // The title before any subtitle, without edition parentheticals: "Project
  // Hail Mary (Movie Tie-In)" is the same book as "Project Hail Mary". One
  // definition for identity, recognition scoring and the edition search, so
  // the three can never disagree about what one book is.
  static String coreTitle(String title) =>
      title.split(':').first.replaceAll(RegExp(r'\(.*?\)'), '').trim();

  static String _identityPart(String? value) =>
      (value ?? '').toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      googleBooksId: data['googleBooksId'] as String?,
      title: data['title'] as String? ?? 'Unknown Title',
      author: data['author'] as String?,
      coverUrl: data['coverUrl'] as String?,
      description: data['description'] as String?,
      genre: data['genre'] as String?,
      pageCount: _knownPageCount(data['pageCount'] as int?),
      publishedDate: data['publishedDate'] as String?,
      isbn: data['isbn'] as String?,
      dateAdded: (data['dateAdded'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'googleBooksId': googleBooksId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'genre': genre,
      'pageCount': pageCount,
      'publishedDate': publishedDate,
      'isbn': isbn,
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}
