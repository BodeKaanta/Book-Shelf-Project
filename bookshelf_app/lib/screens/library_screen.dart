import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedGenre = 'All';

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(booksAsync),
          const Divider(height: 1),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (books) {
                final sorted = [...books]
                  ..sort((a, b) => a.title.compareTo(b.title));
                final filtered = _selectedGenre == 'All'
                    ? sorted
                    : sorted
                        .where((b) => b.genre == _selectedGenre)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedGenre == 'All'
                          ? 'No books yet — tap Import to add your first book.'
                          : 'No books tagged "$_selectedGenre" yet.',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.67,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _GridTile(book: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AsyncValue booksAsync) {
    final genres = booksAsync.maybeWhen(
      data: (books) {
        final seen = <String>{};
        for (final book in books) {
          if (book.genre != null && book.genre!.isNotEmpty) {
            seen.add(book.genre!);
          }
        }
        return seen.toList()..sort();
      },
      orElse: () => <String>[],
    );

    final chips = ['All', ...genres];

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final label = chips[index];
          final isSelected = label == _selectedGenre;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedGenre = label),
              showCheckmark: false,
              selectedColor: const Color(0xFF4A3728),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF4A3728)
                    : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final Book book;

  const _GridTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final url = book.coverUrl?.replaceFirst('http://', 'https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          url != null
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
          if (book.genre != null && book.genre!.isNotEmpty)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  book.genre!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 32),
    );
  }
}
