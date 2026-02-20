class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    this.description,
    this.coverUrl,
    this.pdfUrl,
    this.averageRating,
  });

  final int id;
  final String title;
  final String author;
  final String? genre;
  final String? description;
  final String? coverUrl;
  final String? pdfUrl;
  final double? averageRating;

  factory Book.fromJson(Map<String, dynamic> json) {
    double? parseRating(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Book(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      genre: json['genre']?.toString(),
      description: json['description']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      averageRating: parseRating(json['averageRating'] ?? json['rating']),
    );
  }
}
