import 'package:flutter_test/flutter_test.dart';

import 'package:medlink_app/services/bonus_wallet_controller.dart'
    show newIdempotencyKey;

void main() {
  group('newIdempotencyKey', () {
    test('generates unique keys across many calls', () {
      final keys = <String>{for (var i = 0; i < 500; i++) newIdempotencyKey()};
      expect(keys.length, 500);
    });

    test('key carries no financial or user payload', () {
      final key = newIdempotencyKey();
      expect(key.startsWith('client-'), isTrue);
      expect(key.contains('100'), isFalse);
    });

    test('two consecutive keys differ (no timestamp-only collision)', () {
      expect(newIdempotencyKey() == newIdempotencyKey(), isFalse);
    });
  });
}
