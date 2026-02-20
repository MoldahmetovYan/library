import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/book.dart';
import '../providers/user_provider.dart';
import '../utils/json_utils.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({
    super.key,
    required this.bookId,
    this.initialBook,
  });

  final int bookId;
  final Book? initialBook;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  Book? _book;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _book = widget.initialBook;
    if (_book == null) {
      _loading = true;
    }
    Future.microtask(_loadDetails);
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final response = await api.getBook(widget.bookId);
      final data = extractMap(response.data);
      final fetchedBook = Book.fromJson(data);
      if (!mounted) return;
      setState(() {
        _book = fetchedBook;
      });
      // Update history list after successful fetch.
      await ref.read(userProvider.notifier).refreshHistory();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isFavorite = userState.favoriteIds.contains(widget.bookId);
    final book = _book;

    Widget body;
    if (book == null && _loading && _error == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (book == null && _error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Не удалось загрузить книгу: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDetails,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    } else {
      final coverUrl = book?.coverUrl;
      final genre = book?.genre;
      final pdfUrl = book?.pdfUrl;
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (coverUrl != null) ...[
              if (_loading) const SizedBox(height: 12),
              Center(
                child: CachedNetworkImage(
                  imageUrl: '$apiBaseUrl$coverUrl',
                  width: 220,
                  placeholder: (_, __) => const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    size: 48,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              book?.author ?? 'Неизвестный автор',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (genre != null && genre.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  genre,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            if (book?.averageRating != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(book!.averageRating!.toStringAsFixed(1)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              book?.description?.isNotEmpty == true
                  ? book!.description!
                  : 'Информация о книге недоступна.',
              textAlign: TextAlign.justify,
            ),
            if (pdfUrl != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _openPdf(context, pdfUrl),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Открыть PDF'),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? 'Информация о книге'),
        actions: [
          IconButton(
            tooltip:
                isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () =>
                ref.read(userProvider.notifier).toggleFavorite(widget.bookId),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _loading ? null : _loadDetails,
          ),
        ],
      ),
      body: body,
    );
  }

  void _openPdf(BuildContext context, String path) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(content: Text('PDF доступен по адресу: $apiBaseUrl$path')),
    );
  }
}
