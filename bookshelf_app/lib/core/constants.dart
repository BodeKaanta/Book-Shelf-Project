// Primary book data source. Its corpus stopped returning mainstream titles in
// Aug 2026 (#75) and recovered by #81 — `isbn:` lookups, author searches and
// popularity ranking all behave again. Requires an API key: keyless calls draw
// on a shared anonymous quota pool that is permanently exhausted (HTTP 429).
const String googleBooksBaseUrl = 'https://www.googleapis.com/books/v1/volumes';

// Fallback, used only when Google Books cannot be reached — timeout, 429 or 5xx
// (#81). Keyless. Open Library asks callers to identify themselves and may
// throttle generic clients.
const String openLibraryBaseUrl = 'https://openlibrary.org/search.json';
const String openLibraryUserAgent = 'Bookedex/1.0 (bookedexapp@gmail.com)';

// Open Library can be slower than Google Books, and a stalled request would
// otherwise leave the import spinner running forever with no error.
const Duration bookLookupTimeout = Duration(seconds: 15);

// Recognition confidence at/above which a book is auto-added silently; below it
// the book goes to the approval queue for review.
// Calibrated on Margot's 20-photo set. #78 separated correct from incorrect
// cleanly on Open Library (correct 0.68-1.00, incorrect 0.00-0.60, split at
// 0.65), but the distribution is a property of the data source, so it is
// re-measured here against Google Books before being moved off 0.75.
const double autoAddConfidenceThreshold = 0.75;
