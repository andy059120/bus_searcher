import 'dart:collection';
import 'package:http_parser/http_parser.dart' show parseHttpDate;

import 'package:bus_project/data/services/tdx_exception.dart';

/// 單一 app 執行期間共用的限流器；不將過時的搜尋排隊送出。
class TdxRequestLimiter {
  TdxRequestLimiter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Queue<DateTime> _sentAt = Queue<DateTime>();
  DateTime? _blockedUntil;

  // 多留一秒邊界，避免本機與伺服器的分鐘視窗恰好重疊。
  static const window = Duration(seconds: 61);
  static const maxRequests = 5;

  void acquire() {
    final now = _now();
    while (_sentAt.isNotEmpty && !now.isBefore(_sentAt.first.add(window))) {
      _sentAt.removeFirst();
    }
    if (_blockedUntil != null && now.isBefore(_blockedUntil!)) {
      _reject(_blockedUntil!.difference(now));
    }
    if (_sentAt.length >= maxRequests) {
      _reject(_sentAt.first.add(window).difference(now));
    }
    // 檢查與登記之間沒有 await，併發呼叫也不會取得相同名額。
    _sentAt.addLast(now);
  }

  void _reject(Duration remaining) {
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    throw TdxException('查詢頻率已達上限，請於 $seconds 秒後再試。', statusCode: 429);
  }

  /// 伺服器可能包含其他裝置的用量，因此 429 後至少停止一個視窗。
  void recordRateLimit(String? retryAfter) {
    final now = _now();
    var until = now.add(window);
    final seconds = int.tryParse(retryAfter ?? '');
    DateTime? requestedUntil;
    if (seconds != null && seconds > 0) {
      requestedUntil = now.add(Duration(seconds: seconds));
    } else if (retryAfter != null) {
      try {
        requestedUntil = parseHttpDate(retryAfter);
      } on FormatException {
        // 無效 header 使用保守的預設冷卻時間。
      }
    }
    if (requestedUntil != null && requestedUntil.isAfter(until)) {
      until = requestedUntil;
    }
    if (_blockedUntil == null || until.isAfter(_blockedUntil!)) {
      _blockedUntil = until;
    }
  }
}
