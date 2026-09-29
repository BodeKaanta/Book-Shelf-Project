import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/recognition_log.dart';
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
  final int alreadyInLibrary; // confident matches skipped as duplicates

  const ImportState({
    this.queue = const [],
    this.autoAdded = const [],
    this.importing = false,
    this.processed = 0,
    this.total = 0,
    this.alreadyInLibrary = 0,
  });

  int get addedCount => autoAdded.length;
  int get reviewCount => queue.length;
  bool get picking => importing && total == 0;

  ImportState copyWith({
    List<PendingBook>? queue,
    List<AutoAdded>? autoAdded,
    bool? importing,
    int? processed,
    int? total,
    int? alreadyInLibrary,
  }) {
    return ImportState(
      queue: queue ?? this.queue,
      autoAdded: autoAdded ?? this.autoAdded,
      importing: importing ?? this.importing,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      alreadyInLibrary: alreadyInLibrary ?? this.alreadyInLibrary,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  ImportNotifier(this._ref) : super(const ImportState());

  final Ref _ref;
  final _recognition = BookRecognitionService();
  final _booksApi = BooksApiService();

  BookRepository get _repo => _ref.read(bookRepositoryProvider);

  @override
  void dispose() {
    _recognition.dispose();
    super.dispose();
  }

  // The OS picker/camera runs as its own activity, so our activity resumes and
  // renders frames again *before* the picked files arrive over the platform
  // channel. Showing the loader up front stops the start screen flashing in
  // that gap.
  void beginPicking() => state = const ImportState(importing: true);

  void cancelPicking() => state = const ImportState();

  Future<void> importImages(List<XFile> images) async {
    state = ImportState(importing: true, total: images.length);
    final confident = <Book>[];
    for (final image in images) {
      final match = await _classify(image);
      if (match != null) confident.add(match);
      state = state.copyWith(processed: state.processed + 1);
      await Future<void>.delayed(Duration.zero); // yield so the UI can render
    }
    // One batched write for all confident matches — no per-book Firestore write
    // (and no per-book Home rebuild) during the loading loop.
    final result = await _repo.addBooks(confident);
    state = state.copyWith(
      importing: false,
      autoAdded: [for (final e in result.added) AutoAdded(e.id, e.book)],
      alreadyInLibrary: result.duplicates,
    );
  }

  // Returns the confident top match to auto-add, or null after enqueuing an
  // uncertain photo for review. Does not write to the library.
  Future<Book?> _classify(XFile image) async {
    final ocr = await _recognition.extractTextFromImage(image);
    final result = await _booksApi.searchBooks(ocr);

    logRecognition(
      imagePath: image.path,
      ocr: ocr,
      query: result.query,
      books: result.books,
      confidence: result.confidence,
    );

    final isConfident =
        result.confidence >= autoAddConfidenceThreshold &&
        result.books.isNotEmpty;
    if (isConfident) return result.books.first;

    final queue = [
      ...state.queue,
      PendingBook(
        imagePath: image.path,
        candidates: result.books,
        confidence: result.confidence,
      ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));
    state = state.copyWith(queue: queue);
    return null;
  }

  // Approve the current card with the chosen book (top guess, another match, or
  // a manual-search pick), save it, and advance the queue. Returns false if the
  // book was already in the library (nothing added).
  Future<bool> approveTop(Book book) async {
    final id = await _repo.addBook(book);
    _dropTop();
    return id != null;
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
