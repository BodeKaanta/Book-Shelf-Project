import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/recognition_provider.dart';
import 'change_cover_screen.dart';

// Tapping a cover anywhere in the library slides this in from the right, with
// the library still visible and dimmed beside it (Richie's Figma). A route, not
// a Scaffold endDrawer: Home and Library sit inside the bottom-nav shell, so
// their drawers could never cover the nav bar the way the design does.
void showBookDetail(BuildContext context, Book book) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => BookDetailSidebar(book: book),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class BookDetailSidebar extends ConsumerWidget {
  final Book book;

  const BookDetailSidebar({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Three quarters of a phone, as in the Figma. Capped so a tablet gets a
    // sidebar rather than a second screen of mostly empty line length.
    final width = math.min(MediaQuery.sizeOf(context).width * 0.75, 420.0);
    // Live rather than the snapshot it was opened with, so a changed cover
    // shows here the moment it is picked. Falls back to the snapshot while a
    // removal is closing the sidebar and the book is already gone.
    final current =
        ref
            .watch(booksStreamProvider)
            .valueOrNull
            ?.where((b) => b.id == book.id)
            .firstOrNull ??
        book;

    return Align(
      alignment: Alignment.centerRight,
      child: Dismissible(
        key: ValueKey(book.id),
        // Swiping it back off to the right closes it, the way it came in.
        direction: DismissDirection.startToEnd,
        // No collapse step after the swipe: the route simply closes.
        resizeDuration: null,
        onDismissed: (_) => Navigator.pop(context),
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Material(
            color: Colors.white,
            elevation: 16,
            // The white runs up behind the status bar, but nothing is drawn
            // there — the list stops at the safe area, so even scrolled content
            // never slides under the clock, battery or camera cutout.
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Cover(
                    book: current,
                    // Editions are found by title + author; with no author
                    // there is no telling which results are this book.
                    onChangeCover:
                        Book.identityKey(current.title, current.author) == null
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeCoverScreen(book: current),
                            ),
                          ),
                    onRemove: () => _confirmRemove(context, ref),
                  ),
                  _Details(book: current),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this book?'),
        content: Text('"${book.title}" will be removed from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;

    // Not awaited: Firestore completes a write only once the server confirms
    // it, so offline the sidebar would hang open. The local cache drops the
    // book from booksStreamProvider immediately either way.
    unawaited(ref.read(bookRepositoryProvider).deleteBook(book.id));
    Navigator.pop(context);
  }
}

class _Cover extends StatelessWidget {
  final Book book;
  final VoidCallback? onChangeCover;
  final VoidCallback onRemove;

  const _Cover({
    required this.book,
    required this.onChangeCover,
    required this.onRemove,
  });

  // White on a translucent disc reads over any cover, light or dark.
  static final _overCover = IconButton.styleFrom(
    backgroundColor: Colors.black45,
    foregroundColor: Colors.white,
  );

  // Full width, as in the Figma, but shorter than a cover's own 2:3 so the
  // details — and, post-beta, the buy links — start higher up. The reader
  // already knows which book they tapped. The cover still shows whole inside
  // it, so it is narrower than the box; see _images for what fills the sides.
  static const _aspectRatio = 4 / 5;

  @override
  Widget build(BuildContext context) {
    final url = book.coverUrl?.replaceFirst('http://', 'https://');

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url == null) _placeholder() else ..._images(url),
          Positioned(
            top: 8,
            left: 8,
            child: PopupMenuButton<void>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_horiz),
              style: _overCover,
              itemBuilder: (_) => [
                if (onChangeCover != null)
                  PopupMenuItem(
                    onTap: onChangeCover,
                    child: const Row(
                      children: [
                        Icon(Icons.image_outlined),
                        SizedBox(width: 12),
                        Text('Change cover'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  onTap: onRemove,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline),
                      SizedBox(width: 12),
                      Text('Remove from library'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              style: _overCover,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // The grid has already decoded this cover at 400px, so that copy paints the
  // moment the sidebar opens; the stored 600px one replaces it once downloaded,
  // since at nearly the sidebar's full width 400px is visibly soft.
  List<Widget> _images(String url) => [
    // Fills the slivers either side of the whole cover, so the header reads as
    // one block rather than a cover between two empty bands. A blur paints
    // past its own edges, so without the ClipRect it spills over the status
    // bar and the dimmed library.
    ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
          tileMode: TileMode.clamp,
        ),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    ),
    Image.network(
      url,
      fit: BoxFit.contain,
      cacheWidth: 400,
      errorBuilder: (_, _, _) => _placeholder(),
    ),
    Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  ];

  Widget _placeholder() => Container(
    color: Colors.grey[200],
    child: const Icon(Icons.book, color: Colors.grey, size: 48),
  );
}

class _Details extends StatelessWidget {
  final Book book;

  const _Details({required this.book});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final genre = book.genre;
    final year = book.year;
    final pages = book.pageCount;
    final description = book.description;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Google's categories are far coarser than the Figma's: often just
          // "Fiction", sometimes "Electronic books", sometimes nothing.
          if (genre != null && genre.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                genre,
                style: text.labelMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            book.title,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (book.author != null) ...[
            const SizedBox(height: 4),
            Text(
              book.author!,
              style: text.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
          // Both describe the edition recognition matched, not the work — a
          // movie tie-in shows its own year. Books added before #112 have no
          // year stored, so each stat hides itself rather than showing a gap.
          if (year != null || pages != null) ...[
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                children: [
                  if (year != null) _Stat(label: 'YEAR', value: year),
                  if (year != null && pages != null)
                    // The theme's divider tints pink off the red seed.
                    VerticalDivider(width: 40, color: Colors.grey.shade300),
                  if (pages != null) _Stat(label: 'PAGES', value: '$pages'),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Open Library carries no description, so books added on the
          // fallback (or before #81) have none.
          if (description == null)
            Text(
              'No synopsis for this edition.',
              style: text.bodyMedium?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            _Synopsis(text: description),
        ],
      ),
    );
  }
}

// Collapsed to a few lines so what sits below it — the buy links, post-beta —
// is in view without scrolling past a full blurb first.
class _Synopsis extends StatefulWidget {
  final String text;

  const _Synopsis({required this.text});

  @override
  State<_Synopsis> createState() => _SynopsisState();
}

class _SynopsisState extends State<_Synopsis> {
  static const _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Merged onto the default exactly as Text does, so the measurement below
    // lays out the same text the reader sees.
    final style = DefaultTextStyle.of(context).style.merge(
      theme.textTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade700,
        height: 1.5,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured, not assumed: a synopsis that already fits in three lines
        // gets no "Read more" that would reveal nothing.
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(_expanded ? 'Read less' : 'Read more'),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: Colors.grey.shade600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
