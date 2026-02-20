import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Книги')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _openAdmin,
              child: const Icon(Icons.admin_panel_settings),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Поиск по названию или автору',
                prefixIcon: const Icon(Icons.search),
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
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              booksController.search('');
                            },
                          )
                        : null),
              ),
              onChanged: booksController.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<BooksSortOption>(
                    value: booksState.sortOption,
                    decoration: const InputDecoration(
                      labelText: 'Сортировка',
                      border: OutlineInputBorder(),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: booksState.genreFilter,
                    decoration: const InputDecoration(
                      labelText: 'Жанр',
                      border: OutlineInputBorder(),
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (booksState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Не удалось загрузить список книг: ${booksState.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: booksController.loadBooks,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          if (booksState.searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ошибка при поиске: ${booksState.searchError}',
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: booksController.refresh,
              child: booksState.loading && booksState.visibleBooks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: booksState.visibleBooks.length,
                      itemBuilder: (context, index) {
                        final book = booksState.visibleBooks[index];
                        final coverUrl = book.coverUrl;
                        final isFavorite =
                            userState.favoriteIds.contains(book.id);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: coverUrl != null
                                ? Image.network(
                                    '$apiBaseUrl$coverUrl',
                                    width: 52,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.menu_book),
                            title: Text(book.title),
                            subtitle: Text(book.author),
                            trailing: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () => ref
                                  .read(userProvider.notifier)
                                  .toggleFavorite(book.id),
                            ),
                            onTap: () => context.push(
                              '/books/detail/${book.id}',
                              extra: book,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
