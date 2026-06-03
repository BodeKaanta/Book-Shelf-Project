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
      coverUrl: imageLinks?['thumbnail'] as String?,
      description: volumeInfo['description'] as String?,
      genre: categories?.isNotEmpty == true ? categories!.first as String : null,
      pageCount: volumeInfo['pageCount'] as int?,
      dateAdded: DateTime.now(),
    );
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
