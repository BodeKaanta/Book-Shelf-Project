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
    if (book.googleBooksId != null) {
      final existing = await _booksCollection
          .where('googleBooksId', isEqualTo: book.googleBooksId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return null;
    }
    final ref = await _booksCollection.add(book.toFirestore());
    return ref.id;
  }

  Future<void> deleteBook(String id) async {
    await _booksCollection.doc(id).delete();
  }

  Stream<List<Book>> watchBooks() {
    return _booksCollection
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Book.fromFirestore).toList());
  }
}
