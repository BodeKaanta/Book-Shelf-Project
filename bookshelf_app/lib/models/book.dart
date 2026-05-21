class Book {
  final String title;
  final String? author;
  final String? coverUrl;
  final String? description;

  const Book({
    required this.title,
    this.author,
    this.coverUrl,
    this.description,
  });

  factory Book.fromGoogleBooksJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;

    return Book(
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      author: authors?.isNotEmpty == true ? authors!.first as String : null,
      coverUrl: imageLinks?['thumbnail'] as String?,
      description: volumeInfo['description'] as String?,
    );
  }
}
