import 'package:bookhub/models/book.dart';
import 'package:bookhub/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Book.fromJson', () {
    test('parses required and optional fields', () {
      final book = Book.fromJson({
        'id': 10,
        'title': 'Clean Code',
        'author': 'Robert C. Martin',
        'genre': 'Programming',
        'description': 'Best practices',
        'coverUrl': '/uploads/cover.jpg',
        'pdfUrl': '/uploads/book.pdf',
        'averageRating': '4.7',
      });

      expect(book.id, 10);
      expect(book.title, 'Clean Code');
      expect(book.author, 'Robert C. Martin');
      expect(book.genre, 'Programming');
      expect(book.averageRating, 4.7);
    });

    test('supports legacy rating field', () {
      final book = Book.fromJson({
        'id': 1,
        'title': '1984',
        'author': 'George Orwell',
        'rating': 5,
      });

      expect(book.averageRating, 5.0);
    });
  });

  group('User.fromJson', () {
    test('parses canonical fields', () {
      final user = User.fromJson({
        'id': 7,
        'email': 'user@example.com',
        'fullName': 'User Name',
        'role': 'ROLE_USER',
      });

      expect(user.id, 7);
      expect(user.email, 'user@example.com');
      expect(user.fullName, 'User Name');
      expect(user.role, 'ROLE_USER');
    });

    test('uses fallback fields and defaults', () {
      final user = User.fromJson({
        'id': '12',
        'username': 'alt@example.com',
        'name': 'Alt Name',
      });

      expect(user.id, 12);
      expect(user.email, 'alt@example.com');
      expect(user.fullName, 'Alt Name');
      expect(user.role, 'user');
    });
  });
}
