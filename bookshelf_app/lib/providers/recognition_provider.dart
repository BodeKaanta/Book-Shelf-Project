import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book.dart';
import '../services/book_recognition_service.dart';
import '../services/book_repository.dart';
import '../services/books_api_service.dart';

final bookRepositoryProvider = Provider<BookRepository>((_) => BookRepository());

class RecognitionState {
  final AsyncValue<List<Book>> books;
  final String extractedText;
  final String searchQuery;
  final double confidence;

  const RecognitionState({
    this.books = const AsyncValue.data([]),
    this.extractedText = '',
    this.searchQuery = '',
    this.confidence = 0.0,
  });

  RecognitionState copyWith({
    AsyncValue<List<Book>>? books,
    String? extractedText,
    String? searchQuery,
    double? confidence,
  }) {
    return RecognitionState(
      books: books ?? this.books,
      extractedText: extractedText ?? this.extractedText,
      searchQuery: searchQuery ?? this.searchQuery,
      confidence: confidence ?? this.confidence,
    );
  }
}

class RecognitionNotifier extends StateNotifier<RecognitionState> {
  RecognitionNotifier(this._ref) : super(const RecognitionState());

  final Ref _ref;
  final _recognitionService = BookRecognitionService();
  final _booksApiService = BooksApiService();

  Future<void> recognizeFromImage(XFile image) async {
    state = state.copyWith(
      books: const AsyncValue.loading(),
      extractedText: '',
      searchQuery: '',
      confidence: 0.0,
    );

    try {
      final ocr = await _recognitionService.extractTextFromImage(image);
      state = state.copyWith(extractedText: ocr.rawText);

      final result = await _booksApiService.searchBooks(ocr);
      state = state.copyWith(
        books: AsyncValue.data(result.books),
        searchQuery: result.query,
        confidence: result.confidence,
      );
    } catch (e, st) {
      state = state.copyWith(books: AsyncValue.error(e, st));
    }
  }

  Future<bool> saveBook(Book book) async {
    return await _ref.read(bookRepositoryProvider).addBook(book);
  }
}

final recognitionProvider =
    StateNotifierProvider<RecognitionNotifier, RecognitionState>(
  (ref) => RecognitionNotifier(ref),
);
