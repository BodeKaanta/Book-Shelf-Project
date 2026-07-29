import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../models/book.dart';
import '../models/pending_book.dart';
import '../services/book_recognition_service.dart';
import '../services/book_repository.dart';
import '../services/books_api_service.dart';
import 'recognition_provider.dart';

class AutoAdded {
  final String id;
  final Book book;
  const AutoAdded(this.id, this.book);
}

class ImportState {
  final List<PendingBook> queue; // needs review, most-confident-first
  final List<AutoAdded> autoAdded; // silently added this import
  final bool importing;
  final int processed; // photos routed so far this import
  final int total; // photos in the current import

  const ImportState({
    this.queue = const [],
    this.autoAdded = const [],
    this.importing = false,
    this.processed = 0,
    this.total = 0,
  });

  int get addedCount => autoAdded.length;
  int get reviewCount => queue.length;

  ImportState copyWith({
    List<PendingBook>? queue,
    List<AutoAdded>? autoAdded,
    bool? importing,
    int? processed,
    int? total,
  }) {
    return ImportState(
      queue: queue ?? this.queue,
      autoAdded: autoAdded ?? this.autoAdded,
      importing: importing ?? this.importing,
      processed: processed ?? this.processed,
      total: total ?? this.total,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  ImportNotifier(this._ref) : super(const ImportState());

  final Ref _ref;
  final _recognition = BookRecognitionService();
  final _booksApi = BooksApiService();

  BookRepository get _repo => _ref.read(bookRepositoryProvider);

  Future<void> importImages(List<XFile> images) async {
    state = ImportState(importing: true, total: images.length);
    for (final image in images) {
      await _route(image);
      state = state.copyWith(processed: state.processed + 1);
    }
    state = state.copyWith(importing: false);
  }

  Future<void> _route(XFile image) async {
    final ocr = await _recognition.extractTextFromImage(image);
    final result = await _booksApi.searchBooks(ocr);

    final confident = result.confidence >= autoAddConfidenceThreshold &&
        result.books.isNotEmpty;
    if (confident) {
      final id = await _repo.addBook(result.books.first);
      if (id != null) {
        state = state.copyWith(
          autoAdded: [...state.autoAdded, AutoAdded(id, result.books.first)],
        );
      }
      return; // duplicate (id == null) is silently skipped — already in library
    }

    final queue = [
      ...state.queue,
      PendingBook(
        imagePath: image.path,
        candidates: result.books,
        confidence: result.confidence,
      ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
    state = state.copyWith(queue: queue);
  }

  // Approve the current card with the chosen book (top guess, another match, or
  // a manual-search pick), save it, and advance the queue.
  Future<void> approveTop(Book book) async {
    await _repo.addBook(book);
    _dropTop();
  }

  // Skip the current card without saving, and advance the queue.
  void rejectTop() => _dropTop();

  void _dropTop() {
    if (state.queue.isNotEmpty) {
      state = state.copyWith(queue: state.queue.sublist(1));
    }
  }

  Future<void> undoAutoAdd(String id) async {
    await _repo.deleteBook(id);
    state = state.copyWith(
      autoAdded: state.autoAdded.where((e) => e.id != id).toList(),
    );
  }
}

final importProvider = StateNotifierProvider<ImportNotifier, ImportState>(
  (ref) => ImportNotifier(ref),
);
