import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../widgets/book_grid_tile.dart';
import '../providers/books_provider.dart';
import 'library_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Bookedex',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Full Library'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bookedex',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (books) => _buildContent(books),
      ),
    );
  }

  Widget _buildContent(List<Book> books) {
    final Map<String, List<Book>> byGenre = {};
    for (final book in books) {
      if (book.genre != null && book.genre!.isNotEmpty) {
        byGenre.putIfAbsent(book.genre!, () => []).add(book);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _BookRow(title: 'Your Library', books: books, showSeeAll: true),
        ...byGenre.entries.map(
          (entry) => _BookRow(title: entry.key, books: entry.value),
        ),
      ],
    );
  }
}

class _BookRow extends StatelessWidget {
  final String title;
  final List<Book> books;
  final bool showSeeAll;

  const _BookRow({
    required this.title,
    required this.books,
    this.showSeeAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showSeeAll)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  ),
                  child: const Text('See all'),
                ),
            ],
          ),
        ),
        if (books.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              'No books yet — tap Import to add your first book.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            // The cover keeps its 160 and the caption is measured from the same
            // constants the tile uses, so the row grows with text scaling.
            height: 160 + BookGridTile.captionHeight(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: books.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 110,
                  child: BookGridTile(book: books[index]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
