import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../providers/recognition_provider.dart';
import '../services/books_api_service.dart';

// Change cover (#113): every edition of one book, so the user can pick the one
// matching their copy. Fetched when asked, never carried from recognition —
// that is what let import collapse duplicate editions freely (#83).
class ChangeCoverScreen extends ConsumerStatefulWidget {
  final Book book;

  const ChangeCoverScreen({super.key, required this.book});

  @override
  ConsumerState<ChangeCoverScreen> createState() => _ChangeCoverScreenState();
}

class _ChangeCoverScreenState extends ConsumerState<ChangeCoverScreen> {
  final _booksApi = BooksApiService();
  late Future<({List<Book> editions, bool failed})> _lookup;

  @override
  void initState() {
    super.initState();
    _lookup = _booksApi.findEditions(widget.book);
  }

  void _retry() =>
      setState(() => _lookup = _booksApi.findEditions(widget.book));

  void _pick(Book edition) {
    if (edition.googleBooksId != widget.book.googleBooksId) {
      // Not awaited, as with removal: offline the write would hold this screen
      // open until the server confirmed it. The local cache updates the
      // sidebar underneath immediately either way.
      unawaited(
        ref.read(bookRepositoryProvider).changeEdition(widget.book.id, edition),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Change cover'),
      ),
      body: FutureBuilder(
        future: _lookup,
        builder: (context, snapshot) {
          final result = snapshot.data;
          if (snapshot.hasError || result?.failed == true) {
            return _CouldNotLoad(onRetry: _retry);
          }
          if (result == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _EditionGrid(editions: result.editions, onPick: _pick);
        },
      ),
    );
  }
}

class _EditionGrid extends StatelessWidget {
  final List<Book> editions;
  final ValueChanged<Book> onPick;

  const _EditionGrid({required this.editions, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            editions.length > 1
                ? 'Pick the edition that matches your copy.'
                : 'Google Books has no other covers for this book.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: editions.length,
            // editionsOf puts the user's current edition first.
            itemBuilder: (context, i) => _EditionTile(
              edition: editions[i],
              isCurrent: i == 0,
              onTap: () => onPick(editions[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditionTile extends StatelessWidget {
  final Book edition;
  final bool isCurrent;
  final VoidCallback onTap;

  const _EditionTile({
    required this.edition,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final url = edition.coverUrl?.replaceFirst('http://', 'https://');
    final pages = edition.pageCount;
    // Year and pages are what tell two printings with similar art apart.
    final caption = [
      edition.year,
      if (pages != null) '$pages pages',
    ].nonNulls.join(' · ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              foregroundDecoration: isCurrent
                  ? BoxDecoration(
                      border: Border.all(color: primary, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: url == null
                        ? _placeholder()
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            // The width the sidebar and grid tiles decode at,
                            // so the picked cover is already in the image
                            // cache when the sidebar shows it.
                            cacheWidth: 400,
                            errorBuilder: (_, _, _) => _placeholder(),
                          ),
                  ),
                  if (isCurrent)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: primary,
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[200],
    child: const Icon(Icons.book, color: Colors.grey, size: 32),
  );
}

class _CouldNotLoad extends StatelessWidget {
  final VoidCallback onRetry;

  const _CouldNotLoad({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Couldn't reach Google Books."),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
