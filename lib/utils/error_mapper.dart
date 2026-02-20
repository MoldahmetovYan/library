import 'package:dio/dio.dart';

import 'json_utils.dart';

String mapErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final map = extractMap(data);
      final message = map['message'] ?? map['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Check your internet connection.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return code == null
            ? 'Server returned an error response.'
            : 'Server returned an error response ($code).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed (certificate error).';
      case DioExceptionType.unknown:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unexpected network error.';
    }
  }

  final text = error.toString().trim();
  return text.isEmpty ? 'Unexpected error.' : text;
}
