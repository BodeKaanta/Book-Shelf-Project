import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class BookRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _booksCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('books');
  }

  Future<void> addBook(Book book) async {
    await _booksCollection.add(book.toFirestore());
  }

  Stream<List<Book>> watchBooks() {
    return _booksCollection
        .orderBy('dateAdded', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Book.fromFirestore).toList());
  }
}
