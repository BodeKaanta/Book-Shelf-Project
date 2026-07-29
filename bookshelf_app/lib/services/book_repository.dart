import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class BookRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _booksCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('books');
  }

  // Returns the new document id, or null if the book was already in the library.
  Future<String?> addBook(Book book) async {
    final existing = await _booksCollection.get();
    if (existing.docs.any((d) => _sameBook(d.data(), book))) return null;
    final ref = await _booksCollection.add(book.toFirestore());
    return ref.id;
  }

  // A book already in the library if its googleBooksId matches, OR its title +
  // author match — the latter catches different Google Books editions of the
  // same book (which have different ids).
  bool _sameBook(Map<String, dynamic> existing, Book book) {
    final existingId = existing['googleBooksId'] as String?;
    if (existingId != null && existingId == book.googleBooksId) return true;

    final title = _titleKey(book.title);
    if (title.isEmpty || title != _titleKey(existing['title'] as String?)) {
      return false;
    }
    final author = _authorKey(book.author);
    return author.isNotEmpty && author == _authorKey(existing['author'] as String?);
  }

  String _titleKey(String? title) => (title ?? '')
      .split(':')
      .first
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]'), '');

  String _authorKey(String? author) =>
      (author ?? '').toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  Future<void> deleteBook(String id) async {
    await _booksCollection.doc(id).delete();
  }

  // Adds many books in a single WriteBatch (one write → one stream emission →
  // one Home rebuild, instead of one per book). Skips books already in the
  // library and duplicates within the batch; returns what was added (with ids)
  // and how many were skipped as already-owned.
  Future<({List<({String id, Book book})> added, int duplicates})> addBooks(
      List<Book> books) async {
    if (books.isEmpty) {
      return (added: <({String id, Book book})>[], duplicates: 0);
    }

    final existing =
        (await _booksCollection.get()).docs.map((d) => d.data()).toList();

    final batch = _firestore.batch();
    final added = <({String id, Book book})>[];
    final accepted = <Map<String, dynamic>>[]; // dedup within this batch too
    var duplicates = 0;

    for (final book in books) {
      final isDup = existing.any((d) => _sameBook(d, book)) ||
          accepted.any((d) => _sameBook(d, book));
      if (isDup) {
        duplicates++;
        continue;
      }
      final map = book.toFirestore();
      final ref = _booksCollection.doc();
      batch.set(ref, map);
      added.add((id: ref.id, book: book));
      accepted.add(map);
    }

    if (added.isNotEmpty) await batch.commit();
    return (added: added, duplicates: duplicates);
  }

  Stream<List<Book>> watchBooks() {
    return _booksCollection
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Book.fromFirestore).toList());
  }
}
