import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/books_api_service.dart';

class ManualSearchScreen extends StatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  State<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends State<ManualSearchScreen> {
  final _booksApi = BooksApiService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Book> _results = [];
  bool _loading = false;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    final books = await _booksApi.searchByText(query);
    if (!mounted || requestId != _requestId) return; // ignore stale responses
    setState(() {
      _results = books;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search title or author…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_controller.text.trim().length < 3) {
      return const Center(child: Text('Type at least 3 characters to search.'));
    }
    if (_results.isEmpty) return const Center(child: Text('No results.'));

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final book = _results[i];
        return ListTile(
          leading: _cover(book),
          title: Text(book.title),
          subtitle: book.author != null ? Text(book.author!) : null,
          onTap: () => Navigator.of(context).pop(book),
        );
      },
    );
  }

  Widget _cover(Book book) {
    const width = 40.0;
    final placeholder = Container(
      width: width,
      height: width * 1.5,
      color: Colors.grey.shade300,
      child: const Icon(Icons.book, size: 18, color: Colors.grey),
    );
    if (book.coverUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        book.coverUrl!.replaceFirst('http://', 'https://'),
        width: width,
        height: width * 1.5,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
