import 'dart:async';

import 'package:dio/dio.dart';

import '../constants.dart';
import '../utils/auth_storage.dart';

class ApiClient {
  ApiClient({String? baseUrl, this.onUnauthorized})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 10),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.next(options),
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          if (status == 401) {
            await storage.clear();
            if (onUnauthorized != null) {
              await onUnauthorized!();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final AuthStorage storage = const AuthStorage();
  Future<void> Function()? onUnauthorized;

  void registerUnauthorizedHandler(Future<void> Function() handler) {
    onUnauthorized = handler;
  }

  Future<Response<T>> _wrap<T>(Future<Response<T>> future) async {
    try {
      return await future.timeout(const Duration(seconds: 10));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        await storage.clear();
        if (onUnauthorized != null) {
          await onUnauthorized!();
        }
      }
      rethrow;
    }
  }

  Future<Options> _authorizedOptions() async {
    final token = await storage.readToken();
    if (token == null) {
      throw StateError('Missing authentication token');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Options?> _optionalAuthorizedOptions() async {
    final token = await storage.readToken();
    if (token == null) {
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response<dynamic>> login(String email, String password) {
    return _wrap(
      dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      ),
    );
  }

  Future<Response<dynamic>> register(
    String email,
    String password,
    String fullName,
  ) {
    return _wrap(
      dio.post(
        '/api/auth/register',
        data: {'email': email, 'password': password, 'fullName': fullName},
      ),
    );
  }

  Future<Response<dynamic>> getBooks({int? page, int? size}) {
    final params = <String, dynamic>{};
    if (page != null) params['page'] = page;
    if (size != null) params['size'] = size;
    return _wrap(dio.get('/api/books', queryParameters: params.isEmpty ? null : params));
  }

  Future<Response<dynamic>> getBook(int id) async {
    final options = await _optionalAuthorizedOptions();
    try {
      return await _wrap(dio.get('/api/books/$id', options: options));
    } on DioException catch (e) {
      // Some backends incorrectly return 400 for malformed/expired bearer token
      // even on public endpoints. Retry once without auth header.
      if (options != null && e.response?.statusCode == 400) {
        return _wrap(dio.get('/api/books/$id'));
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> searchBooks(String query) {
    return _wrap(
      dio.get(
        '/api/books/search',
        queryParameters: {'query': query},
      ),
    );
  }

  Future<Response<dynamic>> getProfile() async {
    final options = await _authorizedOptions();
    return _wrap(dio.get('/api/users/me', options: options));
  }

  Future<Response<dynamic>> updateProfile({String? fullName, String? newPassword}) async {
    final options = await _authorizedOptions();
    final payload = <String, String>{};
    if (fullName != null) payload['fullName'] = fullName;
    if (newPassword != null) payload['newPassword'] = newPassword;
    return _wrap(dio.post('/api/users/update', data: payload, options: options));
  }

  Future<Response<dynamic>> deleteAccount() async {
    final options = await _authorizedOptions();
    return _wrap(dio.delete('/api/users/delete', options: options));
  }

  Future<Response<dynamic>> getFavorites() async {
    final options = await _authorizedOptions();
    return _wrap(dio.get('/api/favorites', options: options));
  }

  Future<Response<dynamic>> addFavorite(int bookId) async {
    final options = await _authorizedOptions();
    return _wrap(
      dio.post(
        '/api/favorites',
        queryParameters: {'bookId': bookId},
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> removeFavorite(int bookId) async {
    final options = await _authorizedOptions();
    return _wrap(
      dio.delete(
        '/api/favorites',
        queryParameters: {'bookId': bookId},
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> getHistory() async {
    final options = await _authorizedOptions();
    return _wrap(dio.get('/api/history', options: options));
  }

  Future<Response<dynamic>> getReviews(int bookId) {
    return _wrap(dio.get('/api/reviews/$bookId'));
  }

  Future<Response<dynamic>> submitReview(
    int bookId,
    int rating,
    String comment,
  ) async {
    final options = await _authorizedOptions();
    return _wrap(
      dio.post(
        '/api/reviews/$bookId',
        data: {'rating': rating, 'comment': comment},
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> updateReview(
    int bookId,
    int rating,
    String comment,
  ) async {
    final options = await _authorizedOptions();
    return _wrap(
      dio.put(
        '/api/reviews/$bookId',
        data: {'rating': rating, 'comment': comment},
        options: options,
      ),
    );
  }

  Future<Response<dynamic>> deleteReview(int bookId) async {
    final options = await _authorizedOptions();
    return _wrap(dio.delete('/api/reviews/$bookId', options: options));
  }

  Future<Response<dynamic>> uploadCover(int id, String filePath) async {
    final options = await _authorizedOptions();
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    return _wrap(dio.post('/api/books/$id/cover', data: form, options: options));
  }

  Future<Response<dynamic>> createBook(Map<String, dynamic> data) async {
    final options = await _authorizedOptions();
    return _wrap(dio.post('/api/books', data: data, options: options));
  }

  Future<Response<dynamic>> updateBook(
    int id,
    Map<String, dynamic> data,
  ) async {
    final options = await _authorizedOptions();
    return _wrap(dio.put('/api/books/$id', data: data, options: options));
  }

  Future<Response<dynamic>> deleteBook(int id) async {
    final options = await _authorizedOptions();
    return _wrap(dio.delete('/api/books/$id', options: options));
  }
}
