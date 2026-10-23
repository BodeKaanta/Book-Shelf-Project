import 'package:bookshelf_app/models/book.dart';
import 'package:bookshelf_app/services/books_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Change cover (#113). The candidates are what Google Books really returned for
// "Project Hail Mary Andy Weir" in Oct 2026 — ids, titles and authors verbatim
// — so the filter is asserted against the noise it actually has to reject.
Book _volume(String id, String title, String? author, {bool cover = true}) =>
    Book(
      id: '',
      googleBooksId: id,
      title: title,
      author: author,
      coverUrl: cover ? 'https://books.google.com/$id' : null,
      dateAdded: DateTime(2026),
    );

void main() {
  final current = _volume('_RH2DwAAQBAJ', 'Project Hail Mary', 'Andy Weir');

  final googleResults = [
    _volume('-Ff2DwAAQBAJ', 'Project Hail Mary', 'Andy Weir'),
    _volume('uxAl0AEACAAJ', "Andy Weir's 3-Book Collection Set", 'Andy Weir',
        cover: false),
    _volume('9Df80QEACAAJ', 'Project Hail Mary', 'Andy Weir'),
    _volume('Vp3KEQAAQBAJ', 'Project Hail Mary (Deluxe Edition)', 'Andy Weir'),
    _volume('_RH2DwAAQBAJ', 'Project Hail Mary', 'Andy Weir'),
    _volume('CnSJEQAAQBAJ', 'Project Hail Mary (Movie Tie-In)', 'Andy Weir'),
    _volume('22WazgEACAAJ', 'Project Hail Mary', 'Weir Andy', cover: false),
    _volume('Ehj1EQAAQBAJ', 'Proyek Hail Mary (Project Hail Mary)', 'Andy Weir'),
    _volume('YNur0QEACAAJ', 'Book Club in a Box', 'Andy Weir', cover: false),
  ];

  List<String?> ids(List<Book> books) =>
      books.map((b) => b.googleBooksId).toList();

  test('offers every edition of the same book with a cover, current first', () {
    expect(ids(BooksApiService.editionsOf(current, googleResults)), [
      '_RH2DwAAQBAJ', // the user's current edition, once
      '-Ff2DwAAQBAJ',
      '9Df80QEACAAJ',
      'Vp3KEQAAQBAJ', // deluxe edition — same book, different art
      'CnSJEQAAQBAJ', // movie tie-in — same book, different art
    ]);
  });

  test('the current edition is shown even when Google did not return it', () {
    final withoutCurrent =
        googleResults.where((b) => b.googleBooksId != '_RH2DwAAQBAJ').toList();
    expect(BooksApiService.editionsOf(current, withoutCurrent).first,
        same(current));
  });

  test('a book with no author is offered nothing but itself', () {
    // Without an author there is no telling which results are this book.
    final unattributed = _volume('x', 'Project Hail Mary', null);
    expect(BooksApiService.editionsOf(unattributed, googleResults),
        [unattributed]);
  });
}
