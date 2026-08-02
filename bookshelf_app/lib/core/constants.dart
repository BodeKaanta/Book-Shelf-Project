const String openLibraryBaseUrl = 'https://openlibrary.org/search.json';

// Open Library asks callers to identify themselves and may throttle generic
// clients.
const String openLibraryUserAgent =
    'Bookedex/1.0 (bookedexapp@gmail.com)';

// Open Library can be slower than Google Books, and a stalled request would
// otherwise leave the import spinner running forever with no error.
const Duration bookLookupTimeout = Duration(seconds: 15);

// Google Books — kept for a fast switch back if its corpus recovers (#75). It
// stopped returning mainstream titles: `isbn:9780593135204` (Project Hail Mary)
// returns 0 results, and no Rowling for "harry potter". Not an app-side fault.
// const String googleBooksBaseUrl = 'https://www.googleapis.com/books/v1/volumes';

// Recognition confidence at/above which a book is auto-added silently; below it
// the book goes to the approval queue for review. Provisional — recalibrate
// against real photos (see #41 calibration data).
// Open Library separates correct from incorrect far better than Google Books
// did (correct 70-85%, incorrect 19-60% on the 20-photo set, versus an
// overlapping 62-90 / 0-70). 0.65 is the measured split, but #78 will change
// the distribution again, so recalibrate once the query builder lands rather
// than twice.
const double autoAddConfidenceThreshold = 0.75;
