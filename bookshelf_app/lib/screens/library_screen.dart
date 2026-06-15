import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            onPressed: () {}, // sort logic in a future issue
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(booksAsync),
          const Divider(height: 1),
          const Expanded(
            child: Center(
              child: Text(
                'Grid coming in #33',
                style: TextStyle(color: Colors.grey),
              ),
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
