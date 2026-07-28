import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book.dart';
import '../providers/import_provider.dart';
import '../providers/recognition_provider.dart';
import 'approval_screen.dart';

class PocScreen extends ConsumerStatefulWidget {
  const PocScreen({super.key});

  @override
  ConsumerState<PocScreen> createState() => _PocScreenState();
}

class _PocScreenState extends ConsumerState<PocScreen> {
  XFile? _selectedImage;
  bool _saving = false;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _selectedImage = image);
    await ref.read(recognitionProvider.notifier).recognizeFromImage(image);
  }

  Future<void> _batchImport() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;
    await ref.read(importProvider.notifier).importImages(images);
  }

  Future<void> _saveBook(Book book) async {
    setState(() => _saving = true);
    final saved = await ref.read(recognitionProvider.notifier).saveBook(book);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Book saved!' : 'Already in your library.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recognitionProvider);
    final importState = ref.watch(importProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookedex — Recognition POC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Photo from Gallery'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _batchImport,
              icon: const Icon(Icons.library_add),
              label: const Text('Batch Import (dev)'),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
            ],
            state.books.when(
              data: (books) => _buildResults(
                  books, state.extractedText, state.searchQuery, state.confidence),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            if (importState.importing)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Importing…'),
                ]),
              ),
            if (!importState.importing &&
                (importState.addedCount > 0 || importState.reviewCount > 0))
              _buildImportSummary(importState),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSummary(ImportState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          'Batch import: ${s.addedCount} auto-added · ${s.reviewCount} to review',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (s.autoAdded.isNotEmpty) ...[
          const Text('Auto-added (≥75%)',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ...s.autoAdded.map((a) => Text(
              '• ${a.book.title}${a.book.author != null ? ' — ${a.book.author}' : ''}')),
          const SizedBox(height: 8),
        ],
        if (s.queue.isNotEmpty) ...[
          const Text('To review (<75%)',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ...s.queue.map((p) => Text(
              '• ${(p.confidence * 100).toStringAsFixed(0)}% — ${p.topGuess?.title ?? '(no match)'}')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ApprovalScreen()),
            ),
            icon: const Icon(Icons.rate_review),
            label: const Text('Open Review Queue (dev)'),
          ),
        ],
      ],
    );
  }

  Widget _buildResults(List<Book> books, String extractedText,
      String searchQuery, double confidence) {
    if (extractedText.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (books.isNotEmpty) ...[
          const Text(
            'Best Match',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _BookResultCard(book: books.first, isTopResult: true),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _saveBook(books.first),
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Book'),
            ),
          ),
          if (books.length > 1) ...[
            const SizedBox(height: 12),
            const Text(
              'Other Matches',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            ...books.skip(1).map(
                  (b) => _BookResultCard(book: b, isTopResult: false),
                ),
          ],
        ] else ...[
          const Text(
            'No match found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const Divider(height: 24),
        Text(
          'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: confidence >= 0.8 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Query sent to Books API (debug)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          searchQuery.isEmpty ? '(none)' : searchQuery,
          style: const TextStyle(fontSize: 12, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        const Text(
          'Raw OCR text (debug)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          extractedText.isEmpty ? '(nothing extracted)' : extractedText,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _BookResultCard extends StatelessWidget {
  final Book book;
  final bool isTopResult;

  const _BookResultCard({required this.book, required this.isTopResult});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  // Google Books returns http URLs — force https to avoid cleartext errors
                  book.coverUrl!.replaceFirst('http://', 'https://'),
                  width: isTopResult ? 60 : 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 40),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontWeight:
                          isTopResult ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (book.author != null)
                    Text(
                      book.author!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
