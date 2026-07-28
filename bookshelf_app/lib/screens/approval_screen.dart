import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/pending_book.dart';
import '../providers/import_provider.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  bool _showOtherMatches = false;
  // A ValueNotifier (not setState) so only the card's transform rebuilds while
  // dragging — the image, pills, and the rest of the screen stay put.
  final ValueNotifier<Offset> _drag = ValueNotifier(Offset.zero);
  late final AnimationController _controller;

  static const double _swipeThreshold = 100;

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

  // Animate the card from its current position to [target]; run [onDone] when
  // it arrives. Used for both fly-out (off-screen) and spring-back (to center).
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

  // Fly the card off-screen in [direction], apply [action], then reset for the
  // next card.
  void _commit(Offset direction, VoidCallback action) {
    final size = MediaQuery.of(context).size;
    _animateTo(direction.scale(size.width, size.height), onDone: () {
      action();
      _drag.value = Offset.zero;
      setState(() => _showOtherMatches = false);
    });
  }

  void _approve(Book book) =>
      _commit(const Offset(1.5, 0), () => ref.read(importProvider.notifier).approveTop(book));

  void _reject() =>
      _commit(const Offset(-1.5, 0), () => ref.read(importProvider.notifier).rejectTop());

  void _manualSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual search — coming next (#44)')),
    );
    _animateTo(Offset.zero); // spring back; manual search doesn't discard
  }

  void _onDragEnd(PendingBook pending) {
    final drag = _drag.value;
    if (drag.dx > _swipeThreshold && pending.hasResults) {
      _approve(pending.topGuess!);
    } else if (drag.dx < -_swipeThreshold) {
      _reject();
    } else if (drag.dy < -_swipeThreshold) {
      _manualSearch();
    } else {
      _animateTo(Offset.zero); // didn't reach threshold — spring back
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(importProvider.select((s) => s.queue));

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
      ),
      body: queue.isEmpty
          ? _buildComplete(context)
          : _buildReview(context, queue.first),
    );
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

  Widget _buildReview(BuildContext context, PendingBook pending) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanUpdate: (d) => _drag.value += d.delta,
                onPanEnd: (_) => _onDragEnd(pending),
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _drag,
                  child: _reviewCard(pending),
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

  Widget _reviewCard(PendingBook pending) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(pending.imagePath), fit: BoxFit.cover),
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
    );
  }

  // A ✓ / ✗ / search stamp that fades in with the drag so the action is visible.
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
            child: Icon(stamp.icon, size: 72, color: stamp.color),
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
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _otherMatchesRow(PendingBook pending) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pending.otherMatches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
