import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/user_provider.dart';

class BookListPage extends ConsumerStatefulWidget {
  const BookListPage({super.key});

  @override
  ConsumerState<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends ConsumerState<BookListPage> {
  late final TextEditingController _searchCtrl;

  static const Map<BooksSortOption, String> _sortLabels = {
    BooksSortOption.titleAsc: 'Название (A-Z)',
    BooksSortOption.titleDesc: 'Название (Z-A)',
    BooksSortOption.authorAsc: 'Автор (A-Z)',
    BooksSortOption.ratingDesc: 'Рейтинг (по убыванию)',
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAdmin() async {
    final changed = await context.push<bool>('/admin');
    if (changed == true && mounted) {
      await ref.read(booksProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);
    final booksController = ref.read(booksProvider.notifier);
    final userState = ref.watch(userProvider);
    final isAdmin = userState.user?.role == 'ROLE_ADMIN';
    final visibleBooks = booksState.visibleBooks;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотека'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Панель администратора',
              onPressed: _openAdmin,
              icon: const Icon(Icons.admin_panel_settings_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию или автору',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: booksState.searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (booksState.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    booksController.search('');
                                  },
                                )
                              : null),
                  ),
                  onChanged: booksController.search,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              'Сортировка',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          DropdownButtonFormField<BooksSortOption>(
                            initialValue: booksState.sortOption,
                            decoration: const InputDecoration(
                              hintText: 'Выберите сортировку',
                              isDense: true,
                            ),
                            items: BooksSortOption.values
                                .map(
                                  (option) => DropdownMenuItem<BooksSortOption>(
                                    value: option,
                                    child: Text(_sortLabels[option]!),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                booksController.setSortOption(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              'Жанр',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          DropdownButtonFormField<String?>(
                            initialValue: booksState.genreFilter,
                            decoration: const InputDecoration(
                              hintText: 'Выберите жанр',
                              isDense: true,
                            ),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Все жанры'),
                              ),
                              ...booksState.availableGenres.map(
                                (genre) => DropdownMenuItem<String?>(
                                  value: genre,
                                  child: Text(genre),
                                ),
                              ),
                            ],
                            onChanged: booksController.setGenreFilter,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Найдено: ${visibleBooks.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (booksState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: _InlineStatus(
                icon: Icons.error_outline,
                text: 'Не удалось загрузить книги: ${booksState.error}',
                actionText: 'Повторить',
                onPressed: booksController.loadBooks,
              ),
            ),
          if (booksState.searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: _InlineStatus(
                icon: Icons.warning_amber_rounded,
                text: 'Ошибка поиска: ${booksState.searchError}',
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: booksController.refresh,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: booksState.loading && visibleBooks.isEmpty
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator(),
                      )
                    : visibleBooks.isEmpty
                    ? ListView(
                        key: const ValueKey('empty'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 110),
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 52,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Center(child: Text('Книги не найдены')),
                        ],
                      )
                    : ListView.builder(
                        key: const ValueKey('list'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 26),
                        itemCount: visibleBooks.length,
                        itemBuilder: (context, index) {
                          final book = visibleBooks[index];
                          final isFavorite = userState.favoriteIds.contains(
                            book.id,
                          );
                          return _BookCard(
                            book: book,
                            isFavorite: isFavorite,
                            index: index,
                            onTap: () => context.push(
                              '/books/detail/${book.id}',
                              extra: book,
                            ),
                            onFavoriteTap: () => ref
                                .read(userProvider.notifier)
                                .toggleFavorite(book.id),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.index,
  });

  final Book book;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delay = (index * 30).clamp(0, 260);
    final duration = Duration(milliseconds: 220 + delay);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _BookCover(url: book.coverUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (book.genre != null && book.genre!.isNotEmpty)
                              _Tag(text: book.genre!),
                            if (book.averageRating != null)
                              _Tag(
                                text:
                                    '★ ${book.averageRating!.toStringAsFixed(1)}',
                                color: scheme.tertiaryContainer,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.red : scheme.onSurfaceVariant,
                    ),
                    onPressed: onFavoriteTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 58,
        height: 82,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: url != null
            ? Image.network('$apiBaseUrl$url', fit: BoxFit.cover)
            : Icon(
                Icons.menu_book_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.text,
    this.actionText,
    this.onPressed,
  });

  final IconData icon;
  final String text;
  final String? actionText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
            if (actionText != null && onPressed != null)
              TextButton(onPressed: onPressed, child: Text(actionText!)),
          ],
        ),
      ),
    );
  }
}
