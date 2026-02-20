import 'package:bookhub/utils/json_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractList', () {
    test('returns list when payload is list', () {
      final payload = [
        {'id': 1},
        {'id': 2},
      ];

      final result = extractList(payload);
      expect(result.length, 2);
    });

    test('extracts list by known keys', () {
      final payload = {
        'data': [
          {'id': 42}
        ]
      };

      final result = extractList(payload);
      expect(result.first['id'], 42);
    });

    test('throws for unsupported payload', () {
      expect(() => extractList({'data': {'id': 1}}), throwsStateError);
    });
  });

  group('extractMap', () {
    test('returns map when payload is map', () {
      final payload = {'id': 1, 'title': 'Book'};
      final result = extractMap(payload);
      expect(result['id'], 1);
      expect(result['title'], 'Book');
    });

    test('extracts first map from iterable', () {
      final payload = [
        {'id': 5, 'title': 'First'},
        {'id': 6, 'title': 'Second'},
      ];

      final result = extractMap(payload);
      expect(result['id'], 5);
    });

    test('throws for unsupported map payload', () {
      expect(() => extractMap('invalid'), throwsStateError);
    });
  });
}
