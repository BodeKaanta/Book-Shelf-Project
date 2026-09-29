import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/pending_book.dart';
import '../providers/import_provider.dart';
import 'manual_search_screen.dart';

const _maxBackCards = 2;

class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(importProvider.select((s) => s.queue));
    final notifier = ref.read(importProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left),
          label: const Text('Import'),
        ),
        title: const Text('Review Match'),
        centerTitle: true,
        actions: [
          if (queue.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${queue.length} to review',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ),
            ),
        ],
      ),
      body: queue.isEmpty
          ? _buildComplete(context)
          : _ReviewCard(
              // Keyed by the photo so advancing the queue mounts a fresh card
              // (no shared drag offset to snap back — fixes the flash).
              key: ValueKey(queue.first.imagePath),
              pending: queue.first,
              upNext: queue.skip(1).take(_maxBackCards).toList(),
              onApprove: (book) => _approve(context, notifier, book),
              onReject: notifier.rejectTop,
              onManualSearch: () => _manualSearch(context, notifier),
            ),
    );
  }

  Future<void> _manualSearch(
      BuildContext context, ImportNotifier notifier) async {
    final book = await Navigator.of(context).push<Book>(
      MaterialPageRoute(builder: (_) => const ManualSearchScreen()),
    );
    if (book != null && context.mounted) _approve(context, notifier, book);
  }

  Future<void> _approve(
      BuildContext context, ImportNotifier notifier, Book book) async {
    final added = await notifier.approveTop(book);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" is already in your library.')),
      );
    }
  }

  Widget _buildComplete(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Review complete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No more books to review.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final PendingBook pending;
  final List<PendingBook> upNext;
  final void Function(Book) onApprove;
  final VoidCallback onReject;
  final VoidCallback onManualSearch;

  const _ReviewCard({
    super.key,
    required this.pending,
    required this.upNext,
    required this.onApprove,
    required this.onReject,
    required this.onManualSearch,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard>
    with SingleTickerProviderStateMixin {
  bool _showOtherMatches = false;
  bool _committing = false;
  final ValueNotifier<Offset> _drag = ValueNotifier(Offset.zero);
  late final AnimationController _controller;

  static const double _swipeThreshold = 100;
  static const double _stackStep = 12;
  static const double _stackScaleStep = 0.04;
  static const double _stackDim = 0.18;

  // Constant, not scaled to the current queue depth: if the top card's own
  // bounds changed as the queue shrank, every advance would snap.
  static const double _stackReserve = _stackStep * _maxBackCards;

  // Slides the deck forward while the top card flies out, so the promoted card
  // is already at depth 0 when the queue advances. Spring-back and manual
  // search reuse the same controller and must not promote.
  double get _promotion =>
      _committing ? Curves.easeOut.transform(_controller.value) : 0;

  // Every card must decode at the same width, or the queued card behind gets a
  // different image-cache key and the pre-decode buys nothing.
  static const int _cardDecodeWidth = 1080;

  static final _cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _controller.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _animateTo(Offset target, {VoidCallback? onDone}) {
    final anim = Tween<Offset>(begin: _drag.value, end: target)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    void listener() => _drag.value = anim.value;
    anim.addListener(listener);
    _controller
      ..reset()
      ..forward().whenComplete(() {
        anim.removeListener(listener);
        onDone?.call();
      });
  }

  // Fly off-screen, then hand control back to the parent, which advances the
  // queue and disposes this card — so there's nothing left to snap back.
  void _flyOut(Offset direction, VoidCallback action) {
    _committing = true;
    final size = MediaQuery.of(context).size;
    _animateTo(direction.scale(size.width, size.height), onDone: action);
  }

  void _approve(Book book) =>
      _flyOut(const Offset(1.5, 0), () => widget.onApprove(book));

  void _reject() => _flyOut(const Offset(-1.5, 0), widget.onReject);

  void _manualSearch() {
    _animateTo(Offset.zero); // spring back — parent handles the search screen
    widget.onManualSearch();
  }

  void _onDragEnd() {
    final drag = _drag.value;
    if (drag.dx > _swipeThreshold && widget.pending.hasResults) {
      _approve(widget.pending.topGuess!);
    } else if (drag.dx < -_swipeThreshold) {
      _reject();
    } else if (drag.dy < -_swipeThreshold) {
      _manualSearch();
    } else {
      _animateTo(Offset.zero); // below threshold — spring back
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pending;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              // Tight width: a Stack of only Positioned children collapses
              // under the loose constraints a Column hands out.
              child: SizedBox(
                width: double.infinity,
                // Clip.none so the committed card flies clear of these bounds
                // and card shadows aren't cut off at the edges.
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var depth = widget.upNext.length; depth >= 1; depth--)
                      _stackedCard(widget.upNext[depth - 1], depth),
                    _cardSlot(
                      child: GestureDetector(
                        onPanUpdate: (d) => _drag.value += d.delta,
                        onPanEnd: (_) => _onDragEnd(),
                        child: ValueListenableBuilder<Offset>(
                          valueListenable: _drag,
                          child: _card(pending),
                          builder: (context, drag, child) {
                            return Transform.translate(
                              offset: drag,
                              child: Transform.rotate(
                                angle: drag.dx / 1500,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [child!, _dragStamp(drag)],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (pending.hasResults && pending.otherMatches.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    setState(() => _showOtherMatches = !_showOtherMatches),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: Text(_showOtherMatches
                    ? 'Hide other matches'
                    : 'See other matches'),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showOtherMatches
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _otherMatchesRow(pending),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
            const SizedBox(height: 12),
            _actionBar(pending),
          ],
        ),
      ),
    );
  }

  Positioned _cardSlot({required Widget child}) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: _stackReserve,
      child: child,
    );
  }

  // Queued cards are mounted in full behind the current one, so both the photo
  // and the cover thumbnail are already decoded when one is promoted — nothing
  // pops in mid-reveal. Scaling about the bottom edge makes the peek below the
  // card exactly _stackStep per depth without measuring the card.
  Widget _stackedCard(PendingBook pending, int depth) {
    return _cardSlot(
      child: AnimatedBuilder(
        animation: _controller,
        child: _card(pending),
        builder: (context, child) {
          final depthNow = depth - _promotion;
          return Transform.translate(
            offset: Offset(0, _stackStep * depthNow),
            child: Transform.scale(
              scale: 1 - _stackScaleStep * depthNow,
              alignment: Alignment.bottomCenter,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: Colors.black
                          .withValues(alpha: _stackDim * depthNow),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(PendingBook pending) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(pending.imagePath),
              fit: BoxFit.cover,
              cacheWidth: _cardDecodeWidth,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: pending.hasResults
                    ? _matchInfo(pending)
                    : const Text(
                        "We couldn't read this one",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragStamp(Offset drag) {
    final right = (drag.dx / _swipeThreshold).clamp(0.0, 1.0);
    final left = (-drag.dx / _swipeThreshold).clamp(0.0, 1.0);
    final up = (-drag.dy / _swipeThreshold).clamp(0.0, 1.0);

    ({IconData icon, Color color, double opacity, Alignment align}) stamp;
    if (up > right && up > left) {
      stamp = (icon: Icons.search, color: Colors.blueGrey, opacity: up, align: Alignment.topCenter);
    } else if (right >= left) {
      stamp = (icon: Icons.check_circle, color: Colors.green, opacity: right, align: Alignment.topLeft);
    } else {
      stamp = (icon: Icons.cancel, color: Colors.red, opacity: left, align: Alignment.topRight);
    }

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: stamp.align,
          child: Opacity(
            opacity: stamp.opacity,
            // These glyphs knock the check and cross out of a filled disc, so
            // without a backing the symbol is just whatever photo is behind it.
            // The disc is about 60 across at size 72, so 64 fills the cut-out
            // and leaves a hairline rim rather than a heavy ring.
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(stamp.icon, size: 72, color: stamp.color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchInfo(PendingBook pending) {
    final book = pending.topGuess!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _cover(book, width: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _matchBadge(pending.confidence),
              const SizedBox(height: 6),
              Text(
                book.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              if (book.author != null)
                Text(book.author!,
                    style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _matchBadge(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text('${(confidence * 100).round()}% match',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cover(Book book, {required double width}) {
    final placeholder = Container(
      width: width,
      height: width * 1.5,
      color: Colors.grey.shade300,
      child: const Icon(Icons.book, color: Colors.grey),
    );
    if (book.coverUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        book.coverUrl!.replaceFirst('http://', 'https://'),
        width: width,
        height: width * 1.5,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }

  Widget _otherMatchesRow(PendingBook pending) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pending.otherMatches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final book = pending.otherMatches[i];
          return GestureDetector(
            onTap: () => _approve(book),
            child: SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cover(book, width: 90),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionBar(PendingBook pending) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        // Low rather than Highest: the container tones carry the seed hue, and
        // at Highest the pill went pale red under the same tint as the buttons
        // sitting on it.
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _action(
            icon: Icons.close,
            label: 'Incorrect',
            hint: 'Swipe Left',
            color: Colors.red.shade400,
            onTap: _reject,
          ),
          _action(
            icon: Icons.search,
            label: 'Manual Search',
            hint: 'Swipe Up',
            color: Colors.grey.shade600,
            onTap: _manualSearch,
          ),
          _action(
            icon: Icons.check,
            label: 'Correct',
            hint: 'Swipe Right',
            color: Colors.green.shade500,
            onTap: pending.hasResults ? () => _approve(pending.topGuess!) : null,
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required String hint,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text(hint,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
