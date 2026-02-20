const _defaultListKeys = [
  'items',
  'data',
  'content',
  'books',
  'results',
  'history',
  'favorites',
];
const _defaultMapKeys = ['data', 'user', 'profile', 'result', 'me'];

Iterable<dynamic> extractList(
  dynamic data, {
  List<String> keys = _defaultListKeys,
}) {
  if (data is List<dynamic>) {
    return data;
  }
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      final value = data[key];
      if (value is List<dynamic>) {
        return value;
      }
    }
  }
  throw StateError('Unexpected payload type: ${data.runtimeType}');
}

Map<String, dynamic> extractMap(
  dynamic data, {
  List<String> keys = _defaultMapKeys,
}) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  if (data is Iterable) {
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      if (item is Map) {
        return item.map((key, value) => MapEntry(key.toString(), value));
      }
    }
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  for (final key in keys) {
    if (data is Map && data[key] is Map) {
      final map = data[key] as Map;
      return map.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  throw StateError('Unexpected map payload: ${data.runtimeType}');
}
