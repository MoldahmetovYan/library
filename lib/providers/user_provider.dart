import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../utils/auth_storage.dart';
import '../utils/error_mapper.dart';
import '../utils/json_utils.dart';

class UserState {
  const UserState({
    this.user,
    this.loading = false,
    this.error,
    this.favorites = const [],
    this.favoritesLoading = false,
    this.favoritesError,
    this.history = const [],
    this.historyLoading = false,
    this.historyError,
  });

  final User? user;
  final bool loading;
  final String? error;
  final List<Book> favorites;
  final bool favoritesLoading;
  final String? favoritesError;
  final List<Book> history;
  final bool historyLoading;
  final String? historyError;

  bool get isAuthenticated => user != null;

  Set<int> get favoriteIds => favorites.map((book) => book.id).toSet();

  static const Object _sentinel = Object();

  UserState copyWith({
    Object? user = _sentinel,
    bool? loading,
    Object? error = _sentinel,
    List<Book>? favorites,
    bool? favoritesLoading,
    Object? favoritesError = _sentinel,
    List<Book>? history,
    bool? historyLoading,
    Object? historyError = _sentinel,
  }) {
    return UserState(
      user: user == _sentinel ? this.user : user as User?,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
      favorites: favorites ?? this.favorites,
      favoritesLoading: favoritesLoading ?? this.favoritesLoading,
      favoritesError: favoritesError == _sentinel
          ? this.favoritesError
          : favoritesError as String?,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError == _sentinel
          ? this.historyError
          : historyError as String?,
    );
  }
}

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

final userProvider = StateNotifierProvider<UserController, UserState>(
  (ref) => UserController(ref),
);

// Maintains backward compatibility for existing imports.
final authProvider = userProvider;

class UserController extends StateNotifier<UserState> {
  UserController(this._ref) : super(const UserState()) {
    final api = _ref.read(apiProvider);
    api.registerUnauthorizedHandler(logout);
    Future.microtask(restoreSession);
  }

  final Ref _ref;
  final AuthStorage _storage = const AuthStorage();

  ApiClient get _api => _ref.read(apiProvider);

  Future<void> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null) {
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _fetchProfile();
      state = state.copyWith(user: user);
      await Future.wait([refreshFavorites(), refreshHistory()]);
    } catch (error) {
      await logout();
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _api.login(email, password);
      final token = response.data['token'] as String?;
      if (token == null) {
        throw StateError('Token not provided');
      }
      await _storage.saveToken(token);
      final user = await _fetchProfile();
      state = state.copyWith(user: user);
      await Future.wait([refreshFavorites(), refreshHistory()]);
      state = state.copyWith(loading: false, error: null);
      return true;
    } catch (error) {
      final message = _messageFromError(error);
      state = state.copyWith(
        loading: false,
        error: message,
        user: null,
        favorites: const [],
        history: const [],
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _api.register(email, password, name);
      final token = response.data['token'] as String?;
      if (token == null) {
        throw StateError('Token not provided');
      }
      await _storage.saveToken(token);
      final user = await _fetchProfile();
      state = state.copyWith(user: user);
      await Future.wait([refreshFavorites(), refreshHistory()]);
      state = state.copyWith(loading: false, error: null);
      return true;
    } catch (error) {
      final message = _messageFromError(error);
      state = state.copyWith(
        loading: false,
        error: message,
        user: null,
        favorites: const [],
        history: const [],
      );
      return false;
    }
  }

  Future<void> loadProfile() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await _fetchProfile();
      state = state.copyWith(user: user, loading: false);
    } catch (error) {
      state = state.copyWith(loading: false, error: _messageFromError(error));
    }
  }

  Future<void> refreshFavorites() async {
    if (!state.isAuthenticated) {
      state = state.copyWith(
        favorites: const [],
        favoritesLoading: false,
        favoritesError: null,
      );
      return;
    }
    state = state.copyWith(favoritesLoading: true, favoritesError: null);
    try {
      final response = await _api.getFavorites();
      final items = extractList(response.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        favorites: items,
        favoritesLoading: false,
        favoritesError: null,
      );
    } catch (error) {
      state = state.copyWith(
        favoritesLoading: false,
        favoritesError: _messageFromError(error),
      );
    }
  }

  Future<void> refreshHistory() async {
    if (!state.isAuthenticated) {
      state = state.copyWith(
        history: const [],
        historyLoading: false,
        historyError: null,
      );
      return;
    }
    state = state.copyWith(historyLoading: true, historyError: null);
    try {
      final response = await _api.getHistory();
      final items = extractList(response.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      final history = _dedupeBooks(items);
      state = state.copyWith(
        history: history,
        historyLoading: false,
        historyError: null,
      );
    } catch (error) {
      state = state.copyWith(
        historyLoading: false,
        historyError: _messageFromError(error),
      );
    }
  }

  Future<void> toggleFavorite(int bookId) async {
    if (!state.isAuthenticated) {
      return;
    }
    final isFavorite = state.favoriteIds.contains(bookId);
    try {
      if (isFavorite) {
        await _api.removeFavorite(bookId);
      } else {
        await _api.addFavorite(bookId);
      }
      await refreshFavorites();
    } catch (error) {
      state = state.copyWith(favoritesError: _messageFromError(error));
    }
  }

  Future<bool> updateProfile({String? fullName, String? newPassword}) async {
    if (!state.isAuthenticated) {
      return false;
    }
    try {
      await _api.updateProfile(fullName: fullName, newPassword: newPassword);
      final user = await _fetchProfile();
      state = state.copyWith(user: user, error: null);
      return true;
    } catch (error) {
      state = state.copyWith(error: _messageFromError(error));
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (!state.isAuthenticated) {
      return false;
    }
    try {
      await _api.deleteAccount();
      await logout();
      return true;
    } catch (error) {
      state = state.copyWith(error: _messageFromError(error));
      return false;
    }
  }

  bool isFavorite(int bookId) => state.favoriteIds.contains(bookId);

  Future<void> logout() async {
    await _storage.clear();
    state = const UserState();
  }

  Future<User> _fetchProfile() async {
    final response = await _api.getProfile();
    final map = extractMap(response.data);
    return User.fromJson(map);
  }

  List<Book> _dedupeBooks(List<Book> books) {
    final seen = <int>{};
    final result = <Book>[];
    for (final book in books) {
      if (seen.add(book.id)) {
        result.add(book);
      }
    }
    return result;
  }

  String _messageFromError(Object error) {
    return mapErrorMessage(error);
  }
}
