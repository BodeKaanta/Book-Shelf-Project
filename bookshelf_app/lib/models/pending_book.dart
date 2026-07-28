import 'book.dart';

class PendingBook {
  final String imagePath;
  final List<Book> candidates;
  final double confidence;

  const PendingBook({
    required this.imagePath,
    required this.candidates,
    required this.confidence,
  });

  Book? get topGuess => candidates.isEmpty ? null : candidates.first;
  List<Book> get otherMatches =>
      candidates.length > 1 ? candidates.sublist(1) : const [];
  bool get hasResults => candidates.isNotEmpty;
}
