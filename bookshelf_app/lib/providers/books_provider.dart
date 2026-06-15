import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import 'recognition_provider.dart';

final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(bookRepositoryProvider).watchBooks();
});
