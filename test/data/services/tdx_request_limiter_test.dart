import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:bus_project/data/services/tdx_request_limiter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';

void main() {
  test('sixth request is refused until the rolling window expires', () {
    var now = DateTime.utc(2026);
    final limiter = TdxRequestLimiter(now: () => now);
    for (var i = 0; i < 5; i++) {
      limiter.acquire();
      now = now.add(const Duration(seconds: 1));
    }
    expect(limiter.acquire, throwsA(isA<TdxException>()));
    now = DateTime.utc(2026).add(const Duration(seconds: 60));
    expect(limiter.acquire, throwsA(isA<TdxException>()));
    now = now.add(const Duration(seconds: 1));
    limiter.acquire();
    expect(limiter.acquire, throwsA(isA<TdxException>()));
  });

  for (final headerType in ['seconds', 'date', 'invalid', 'absent']) {
    test('429 cooldown supports $headerType Retry-After', () {
      var now = DateTime.utc(2026);
      final limiter = TdxRequestLimiter(now: () => now);
      final header = switch (headerType) {
        'seconds' => '120',
        'date' => formatHttpDate(now.add(const Duration(seconds: 120))),
        'invalid' => 'bad header',
        _ => null,
      };
      limiter.recordRateLimit(header);
      now = now.add(const Duration(seconds: 60));
      expect(limiter.acquire, throwsA(isA<TdxException>()));
      now = now.add(const Duration(seconds: 1));
      if (headerType == 'seconds' || headerType == 'date') {
        expect(limiter.acquire, throwsA(isA<TdxException>()));
        now = now.add(const Duration(seconds: 59));
      }
      limiter.acquire();
    });
  }
}
