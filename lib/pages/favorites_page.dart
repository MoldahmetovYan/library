import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants.dart';
import '../providers/user_provider.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);
    final favorites = userState.favorites;
    final isLoading = userState.favoritesLoading && favorites.isEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: RefreshIndicator(
        onRefresh: notifier.refreshFavorites,
        child: Column(
          children: [
            if (userState.favoritesError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                child: Card(
                  color: scheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userState.favoritesError!,
                            style: TextStyle(color: scheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : favorites.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 56,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Center(child: Text('Список избранного пуст')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 22),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final book = favorites[index];
                        final coverUrl = book.coverUrl;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              onTap: () => context.push(
                                '/books/detail/${book.id}',
                                extra: book,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 48,
                                  height: 68,
                                  color: scheme.primaryContainer,
                                  child: coverUrl != null
                                      ? Image.network(
                                          '$apiBaseUrl$coverUrl',
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.menu_book_rounded,
                                          color: scheme.onPrimaryContainer,
                                        ),
                                ),
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(book.author),
                              trailing: IconButton(
                                tooltip: 'Убрать из избранного',
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () =>
                                    notifier.toggleFavorite(book.id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
