import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/user_provider.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);

    final isLoading = userState.favoritesLoading && userState.favorites.isEmpty;
    final favorites = userState.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: RefreshIndicator(
        onRefresh: notifier.refreshFavorites,
        child: Column(
          children: [
            if (userState.favoritesError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  userState.favoritesError!,
                  style: const TextStyle(color: Colors.red),
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
                            Center(child: Text('Список избранного пуст.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final book = favorites[index];
                            return Card(
                              child: ListTile(
                                leading: book.coverUrl != null
                                    ? Image.network(
                                        '$apiBaseUrl${book.coverUrl}',
                                        width: 48,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.favorite, color: Colors.red),
                                title: Text(book.title),
                                subtitle: Text(book.author),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => notifier.toggleFavorite(book.id),
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
