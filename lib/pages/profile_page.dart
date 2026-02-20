import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants.dart';
import '../providers/user_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _passwordCtrl;
  String? _cachedName;
  bool _didAddListener = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (ref.read(userProvider).isAuthenticated) {
        await _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_didAddListener) {
      _didAddListener = true;
      ref.listen<UserState>(userProvider, (previous, next) {
        final error = next.error;
        if (!mounted || error == null || error == previous?.error) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      });
    }

    final userState = ref.watch(userProvider);
    final user = userState.user;

    if (userState.loading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден.')),
      );
    }

    if (_cachedName != user.fullName) {
      _cachedName = user.fullName;
      _nameCtrl.text = user.fullName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : user.email[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName.isEmpty ? 'Имя не указано' : user.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(user.email),
                        const SizedBox(height: 4),
                        Text('Роль: ${user.role}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Обновить профиль',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Полное имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Новый пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить аккаунт'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'История чтения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (userState.historyLoading && userState.history.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (userState.history.isEmpty)
                const Text('Вы еще не открывали книги.')
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: userState.history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final book = userState.history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: book.coverUrl != null
                          ? Image.network(
                              '$apiBaseUrl${book.coverUrl}',
                              width: 48,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.history),
                      title: Text(book.title),
                      subtitle: Text(book.author),
                      onTap: () => context.push(
                        '/books/detail/${book.id}',
                        extra: book,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    final notifier = ref.read(userProvider.notifier);
    await Future.wait([notifier.refreshFavorites(), notifier.refreshHistory()]);
  }

  Future<void> _updateProfile() async {
    final notifier = ref.read(userProvider.notifier);
    final fullName = _nameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final success = await notifier.updateProfile(
      fullName: fullName.isEmpty ? null : fullName,
      newPassword: password.isEmpty ? null : password,
    );

    if (!mounted) return;
    if (success) {
      _passwordCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль обновлен')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт'),
        content: const Text('Вы уверены, что хотите удалить аккаунт?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(userProvider.notifier).deleteAccount();
      if (!mounted) return;
      if (success) {
        context.go('/login');
      }
    }
  }
}
