import 'book.dart';

class HistoryEntry {
  const HistoryEntry({required this.book, required this.viewedAt});

  final Book book;
  final DateTime viewedAt;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final bookJson =
        (json['book'] as Map<String, dynamic>?) ??
        (json['item'] as Map<String, dynamic>?) ??
        json;
    final timestamp =
        json['viewedAt'] ??
        json['openedAt'] ??
        json['createdAt'] ??
        json['timestamp'];
    return HistoryEntry(
      book: Book.fromJson(bookJson),
      viewedAt:
          DateTime.tryParse(timestamp?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
