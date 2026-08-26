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
  });

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
      pageCount: volumeInfo['pageCount'] as int?,
      dateAdded: DateTime.now(),
    );
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
      pageCount: data['pageCount'] as int?,
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
      'dateAdded': Timestamp.fromDate(dateAdded),
    };
  }
}
