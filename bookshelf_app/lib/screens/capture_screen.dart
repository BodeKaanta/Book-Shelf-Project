import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/import_provider.dart';
import 'approval_screen.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importing = ref.watch(importProvider.select((s) => s.importing));

    return Scaffold(
      appBar: AppBar(title: const Text('Capture')),
      body: Center(
        child: importing ? _buildProgress() : _buildStart(context, ref),
      ),
    );
  }

  Widget _buildProgress() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Recognizing…',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStart(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text('Snap a book cover',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "Point at the cover — we'll recognize it and add it to your library.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _capture(context, ref),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(importProvider.notifier);
    notifier.beginPicking();

    // Full resolution on purpose: a single capture is one image, so the OCR
    // cost is a one-time wait (not a per-book hiccup like batch import) — worth
    // it for the best recognition, including thin/vertical cover text.
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image == null) {
      notifier.cancelPicking();
      return;
    }

    await notifier.importImages([image]);
    if (!context.mounted) return;

    final s = ref.read(importProvider);
    if (s.reviewCount > 0) {
      // Not confident enough — let the user confirm on the approval card.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ApprovalScreen()),
      );
    } else if (s.addedCount > 0) {
      final added = s.autoAdded.last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${added.book.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                ref.read(importProvider.notifier).undoAutoAdd(added.id),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That book is already in your library.')),
      );
    }
  }
}
