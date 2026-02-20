import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/json_utils.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

class BooksState {
  const BooksState({
    this.books = const [],
    this.searchResults,
    this.loading = false,
    this.refreshing = false,
    this.searching = false,
    this.error,
    this.searchError,
    this.searchQuery = '',
  });

  final List<Book> books;
  final List<Book>? searchResults;
  final bool loading;
  final bool refreshing;
  final bool searching;
  final String? error;
  final String? searchError;
  final String searchQuery;

  List<Book> get visibleBooks => searchResults ?? books;

  BooksState copyWith({
    List<Book>? books,
    List<Book>? Function()? searchResults,
    bool? loading,
    bool? refreshing,
    bool? searching,
    String? error,
    bool clearError = false,
    String? searchError,
    bool clearSearchError = false,
    String? searchQuery,
  }) {
    return BooksState(
      books: books ?? this.books,
      searchResults:
          searchResults != null ? searchResults() : this.searchResults,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      searching: searching ?? this.searching,
      error: clearError ? null : (error ?? this.error),
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final booksProvider =
    StateNotifierProvider<BooksController, BooksState>((ref) => BooksController(ref));

class BooksController extends StateNotifier<BooksState> {
  BooksController(this._ref) : super(const BooksState()) {
    _loadInitial();
  }

  final Ref _ref;

  ApiClient get _api => _ref.read(apiProvider);

  Future<void> _loadInitial() async {
    await loadBooks();
  }

  Future<void> loadBooks() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await _api.getBooks();
      final books = extractList(response.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        books: books,
        loading: false,
        clearError: true,
        searchResults: () => null,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true);
    try {
      final response = await _api.getBooks();
      final books = extractList(response.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        books: books,
        refreshing: false,
        clearError: true,
      );
      if (state.searchQuery.isNotEmpty) {
        await search(state.searchQuery, silent: true);
      }
    } catch (error) {
      state = state.copyWith(
        refreshing: false,
        error: error.toString(),
      );
    }
  }

  Future<void> search(String query, {bool silent = false}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: () => null,
        searching: false,
        clearSearchError: true,
      );
      return;
    }

    if (!silent) {
      state = state.copyWith(
        searching: true,
        searchQuery: normalized,
        clearSearchError: true,
      );
    }

    try {
      final response = await _api.searchBooks(normalized);
      final results = extractList(response.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        searchResults: () => results,
        searching: false,
        searchQuery: normalized,
        clearSearchError: true,
      );
    } catch (error) {
      state = state.copyWith(
        searching: false,
        searchError: error.toString(),
      );
    }
  }
}
