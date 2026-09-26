import 'package:flutter/material.dart';
import '../models/book.dart';

// One book anywhere it appears in the user's own library: cover, title, author.
// A cover on its own is unidentifiable when recognition picked an odd edition,
// and the user had no way to tell without opening the book.
//
// Shared by the Library grid, the Home rows, and library search (#100) so they
// cannot drift apart.
class BookGridTile extends StatelessWidget {
  final Book book;

  const BookGridTile({super.key, required this.book});

  // Covers are 2:3, so a grid tile is that plus its caption. GridView fixes one
  // ratio for every tile, so this only lands exactly right at typical widths —
  // the cover absorbs the difference rather than the tile overflowing.
  static const double gridAspectRatio = 0.52;

  static const _titleSize = 13.0;
  static const _authorSize = 11.0;
  static const _lineHeight = 1.25;
  static const _coverGap = 6.0;

  // What a tile needs below its cover. Reserved at two title lines even when
  // the title is one, so every cover in a row ends at the same height — the
  // slack sits *below* the author, not between it and the title.
  static double captionHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _coverGap +
        scaler.scale(_titleSize * _lineHeight) * 2 +
        scaler.scale(_authorSize * _lineHeight);
  }

  @override
  Widget build(BuildContext context) {
    final url = book.coverUrl?.replaceFirst('http://', 'https://');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expanded, not a fixed ratio: the cover gives up space so a long title
        // or a large accessibility text scale can never overflow the tile.
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url == null
                ? _placeholder()
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    // Covers are stored at 600px so the detail sidebar has a
                    // sharp source; decoding every tile at that width would
                    // hold ~2MB each and thrash the 100MB image cache.
                    cacheWidth: 400,
                    errorBuilder: (_, _, _) => _placeholder(),
                  ),
          ),
        ),
        const SizedBox(height: _coverGap),
        SizedBox(
          height: captionHeight(context) - _coverGap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: _titleSize,
                    height: _lineHeight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                book.author ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _authorSize,
                  height: _lineHeight,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        width: double.infinity,
        child: const Icon(Icons.book, color: Colors.grey, size: 32),
      );
}
