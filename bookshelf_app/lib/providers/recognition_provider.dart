import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book.dart';
import '../services/book_recognition_service.dart';
import '../services/books_api_service.dart';

class RecognitionState {
  final AsyncValue<List<Book>> books;
  final String extractedText;
  final String searchQuery;

  const RecognitionState({
    this.books = const AsyncValue.data([]),
    this.extractedText = '',
    this.searchQuery = '',
  });

  RecognitionState copyWith({
    AsyncValue<List<Book>>? books,
    String? extractedText,
    String? searchQuery,
  }) {
    return RecognitionState(
      books: books ?? this.books,
      extractedText: extractedText ?? this.extractedText,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class RecognitionNotifier extends StateNotifier<RecognitionState> {
  RecognitionNotifier() : super(const RecognitionState());

  final _recognitionService = BookRecognitionService();
  final _booksApiService = BooksApiService();

  Future<void> recognizeFromImage(XFile image) async {
    state = state.copyWith(
      books: const AsyncValue.loading(),
      extractedText: '',
      searchQuery: '',
    );

    try {
      final text = await _recognitionService.extractTextFromImage(image);
      state = state.copyWith(extractedText: text);

      final result = await _booksApiService.searchBooks(text);
      state = state.copyWith(
        books: AsyncValue.data(result.books),
        searchQuery: result.query,
      );
    } catch (e, st) {
      state = state.copyWith(books: AsyncValue.error(e, st));
    }
  }
}

final recognitionProvider =
    StateNotifierProvider<RecognitionNotifier, RecognitionState>(
  (_) => RecognitionNotifier(),
);
