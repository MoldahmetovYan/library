import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/book.dart';
import '../providers/user_provider.dart';
import '../ui/app_backdrop.dart';
import '../utils/error_mapper.dart';
import '../utils/json_utils.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.bookId, this.initialBook});

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
      final fetchedBook = Book.fromJson(extractMap(response.data));
      if (!mounted) return;
      setState(() {
        _book = fetchedBook;
      });
      await ref.read(userProvider.notifier).refreshHistory();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = mapErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isFavorite = userState.favoriteIds.contains(widget.bookId);
    final book = _book;

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? 'Книга'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () =>
                ref.read(userProvider.notifier).toggleFavorite(widget.bookId),
          ),
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadDetails,
          ),
        ],
      ),
      body: AppBackdrop(child: _buildBody(context, book)),
    );
  }

  Widget _buildBody(BuildContext context, Book? book) {
    if (book == null && _loading && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (book == null && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'Не удалось загрузить книгу: $_error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadDetails,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final coverUrl = book?.coverUrl;
    final genre = book?.genre;
    final pdfUrl = book?.pdfUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: [
        if (_loading) const LinearProgressIndicator(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 120,
                    height: 170,
                    color: scheme.primaryContainer,
                    child: coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: '$apiBaseUrl$coverUrl',
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.image_not_supported_rounded),
                          )
                        : Icon(
                            Icons.menu_book_rounded,
                            size: 44,
                            color: scheme.onPrimaryContainer,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ?? 'Без названия',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(book?.author ?? 'Неизвестный автор'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (genre != null && genre.isNotEmpty)
                            _Tag(text: genre),
                          if (book?.averageRating != null)
                            _Tag(
                              text:
                                  '★ ${book!.averageRating!.toStringAsFixed(1)}',
                              color: scheme.tertiaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Описание',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book?.description?.isNotEmpty == true
                      ? book!.description!
                      : 'Информация о книге недоступна.',
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
        if (pdfUrl != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openPdf(context, pdfUrl),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Открыть PDF'),
          ),
        ],
      ],
    );
  }

  void _openPdf(BuildContext context, String path) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF доступен по адресу: $apiBaseUrl$path')),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }
}
