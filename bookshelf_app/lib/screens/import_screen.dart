import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/import_provider.dart';
import 'approval_screen.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importing = ref.watch(importProvider.select((s) => s.importing));

    return Scaffold(
      appBar: AppBar(title: const Text('Import')),
      body: Center(
        child: importing ? _buildProgress(ref) : _buildStart(context, ref),
      ),
    );
  }

  Widget _buildProgress(WidgetRef ref) {
    final s = ref.watch(importProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        const Text('Recognizing your books…',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('${s.processed} of ${s.total}',
            style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildStart(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            'Import book photos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Pick photos or screenshots of book covers from your library — "
            "we'll match them and add the sure ones automatically.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Choose Photos'),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    // Downscale natively at pick time — ML Kit on a ~2000px image instead of a
    // full 12MP photo is far lighter and keeps the UI responsive. Cover text
    // stays legible at this size.
    final images = await ImagePicker().pickMultiImage(
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (images.isEmpty) return;

    await ref.read(importProvider.notifier).importImages(images);
    if (!context.mounted) return;

    final s = ref.read(importProvider);
    await _showSummary(context, s.addedCount, s.alreadyInLibrary, s.reviewCount);
  }

  Future<void> _showSummary(
      BuildContext context, int added, int already, int review) async {
    final review0 = review == 0;
    final goReview = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import complete'),
        content: Text(_summaryText(added, already, review)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(review0 ? 'Done' : 'Later'),
          ),
          if (!review0)
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Review $review'),
            ),
        ],
      ),
    );

    if (goReview == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ApprovalScreen()),
      );
    }
  }

  String _summaryText(int added, int already, int review) {
    final lines = <String>[];
    if (added > 0) {
      lines.add('$added ${added == 1 ? 'book' : 'books'} added to your library.');
    }
    if (already > 0) {
      lines.add(
          '$already ${already == 1 ? 'book was' : 'books were'} already in your library.');
    }
    if (review > 0) {
      lines.add('$review ${review == 1 ? 'book needs' : 'books need'} review.');
    }
    return lines.isEmpty ? 'Nothing to import.' : lines.join('\n');
  }
}
