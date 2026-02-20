import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookhub/utils/error_mapper.dart';

void main() {
  RequestOptions requestOptions() => RequestOptions(path: '/test');

  test('mapErrorMessage reads message from backend map', () {
    final error = DioException(
      requestOptions: requestOptions(),
      response: Response<dynamic>(
        requestOptions: requestOptions(),
        statusCode: 400,
        data: {'message': 'Invalid payload'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(mapErrorMessage(error), 'Invalid payload');
  });

  test('mapErrorMessage maps timeout exception', () {
    final error = DioException(
      requestOptions: requestOptions(),
      type: DioExceptionType.connectionTimeout,
    );

    expect(mapErrorMessage(error), 'Request timeout. Please try again.');
  });

  test('mapErrorMessage maps connection error', () {
    final error = DioException(
      requestOptions: requestOptions(),
      type: DioExceptionType.connectionError,
    );

    expect(
      mapErrorMessage(error),
      'Network error. Check your internet connection.',
    );
  });

  test('mapErrorMessage handles plain exception text', () {
    expect(mapErrorMessage(Exception('boom')), 'Exception: boom');
  });
}
