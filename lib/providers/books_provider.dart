import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/error_mapper.dart';
import '../utils/json_utils.dart';
import 'user_provider.dart';
import 'auth_provider.dart';

enum BooksSortOption { titleAsc, titleDesc, authorAsc, ratingDesc }

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
    this.genreFilter,
    this.sortOption = BooksSortOption.titleAsc,
  });

  final List<Book> books;
  final List<Book>? searchResults;
  final bool loading;
  final bool refreshing;
  final bool searching;
  final String? error;
  final String? searchError;
  final String searchQuery;
  final String? genreFilter;
  final BooksSortOption sortOption;

  List<String> get availableGenres {
    final genres =
        books
            .map((book) => book.genre?.trim())
            .whereType<String>()
            .where((genre) => genre.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return genres;
  }

  List<Book> get visibleBooks {
    final base = List<Book>.from(searchResults ?? books);
    final filtered = genreFilter == null
        ? base
        : base
              .where(
                (book) =>
                    (book.genre ?? '').toLowerCase() ==
                    genreFilter!.toLowerCase(),
              )
              .toList();

    filtered.sort((a, b) {
      switch (sortOption) {
        case BooksSortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case BooksSortOption.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case BooksSortOption.authorAsc:
          return a.author.toLowerCase().compareTo(b.author.toLowerCase());
        case BooksSortOption.ratingDesc:
          final left = a.averageRating ?? -1;
          final right = b.averageRating ?? -1;
          return right.compareTo(left);
      }
    });
    return filtered;
  }

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
    String? Function()? genreFilter,
    BooksSortOption? sortOption,
  }) {
    return BooksState(
      books: books ?? this.books,
      searchResults: searchResults != null
          ? searchResults()
          : this.searchResults,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      searching: searching ?? this.searching,
      error: clearError ? null : (error ?? this.error),
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      searchQuery: searchQuery ?? this.searchQuery,
      genreFilter: genreFilter != null ? genreFilter() : this.genreFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

final booksProvider = StateNotifierProvider<BooksController, BooksState>(
  (ref) => BooksController(ref),
);

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
      state = state.copyWith(loading: false, error: mapErrorMessage(error));
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true);
    try {
      final response = await _api.getBooks();
      final books = extractList(response.data)
          .map((dynamic item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(books: books, refreshing: false, clearError: true);
      if (state.searchQuery.isNotEmpty) {
        await search(state.searchQuery, silent: true);
      }
    } catch (error) {
      state = state.copyWith(refreshing: false, error: mapErrorMessage(error));
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
        searchError: mapErrorMessage(error),
      );
    }
  }

  void setGenreFilter(String? genre) {
    final normalized = genre?.trim();
    state = state.copyWith(
      genreFilter: () =>
          (normalized == null || normalized.isEmpty) ? null : normalized,
    );
  }

  void setSortOption(BooksSortOption option) {
    if (state.sortOption == option) {
      return;
    }
    state = state.copyWith(sortOption: option);
  }
}
