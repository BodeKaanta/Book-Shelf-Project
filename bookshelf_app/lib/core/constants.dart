const String googleBooksBaseUrl = 'https://www.googleapis.com/books/v1/volumes';

// Recognition confidence at/above which a book is auto-added silently; below it
// the book goes to the approval queue for review. Provisional — recalibrate
// against real photos (see #41 calibration data).
const double autoAddConfidenceThreshold = 0.75;
