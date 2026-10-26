import 'package:bus_project/data/models/bus_stop.dart';

class EstimateBusStop {
  const EstimateBusStop({
    required this.routeUid,
    required this.subRouteUid,
    required this.stopUid,
    required this.direction,
    required this.stopSequence,
    required this.estimateTime,
    required this.stopStatus,
  });

  final String routeUid;
  final String subRouteUid;
  final String stopUid;
  final int direction;
  final int? stopSequence;
  final int? estimateTime;
  final int? stopStatus;

  factory EstimateBusStop.fromJson(Map<String, dynamic> json) =>
      EstimateBusStop(
        routeUid: json['RouteUID'] as String,
        subRouteUid: json['SubRouteUID'] as String? ?? '',
        stopUid: json['StopUID'] as String,
        direction: json['Direction'] as int,
        stopSequence: json['StopSequence'] as int?,
        estimateTime: json['EstimateTime'] as int?,
        stopStatus: json['StopStatus'] as int?,
      );

  String get label {
    // null 只代表沒有預估秒數，不能一律解讀為未行駛。
    switch (stopStatus) {
      case 1:
        return '尚未發車';
      case 2:
        return '交管不停靠';
      case 3:
        return '末班車已過';
      case 4:
        return '今日未營運';
      case 0:
      case null:
        final seconds = estimateTime;
        if (seconds == null || seconds < 0) return '暫無預估';
        if (seconds < 30) return '進站中';
        if (seconds < 90) return '將進站';
        return '${(seconds / 60).ceil()} 分';
      default:
        return '狀態未提供';
    }
  }
}

typedef _StopKey = (String, String, int, String);
typedef _RouteStopKey = (String, int, String);

/// 一次查詢整條路線的 ETA，切換方向不需逐站查詢。
class ArrivalSnapshot {
  ArrivalSnapshot(List<EstimateBusStop> arrivals, this.fetchedAt) {
    for (final arrival in arrivals) {
      final key = (
        arrival.routeUid,
        arrival.subRouteUid,
        arrival.direction,
        arrival.stopUid,
      );
      (_byStop[key] ??= []).add(arrival);
      (_byRouteStop[(arrival.routeUid, arrival.direction, arrival.stopUid)] ??=
              [])
          .add(arrival);
    }
  }

  final DateTime fetchedAt;
  final Map<_StopKey, List<EstimateBusStop>> _byStop = {};
  final Map<_RouteStopKey, List<EstimateBusStop>> _byRouteStop = {};

  EstimateBusStop? find(
    BusStop pattern,
    RouteStop stop, {
    List<BusStop> routePatterns = const [],
  }) {
    final exactBranch = _byStop[(
      pattern.routeUid,
      pattern.subRouteUid,
      pattern.direction,
      stop.uid,
    )];
    List<EstimateBusStop>? candidates = exactBranch;
    if ((candidates == null || pattern.subRouteUid.isEmpty) &&
        routePatterns.isNotEmpty) {
      // 實測臺北 262 的 ETA 沒有 SubRouteUID、StopSequence。
      // 只在整份站序中「路線＋方向＋站牌 UID」唯一時允許降級配對；
      // 同方向的多條支線或迴圈重複站不猜測，仍顯示暫無預估。
      final occurrences = routePatterns
          .where((p) =>
              p.routeUid == pattern.routeUid &&
              p.direction == pattern.direction)
          .expand((p) => p.stops)
          .where((s) => s.uid == stop.uid)
          .length;
      if (occurrences != 1) return null;
      candidates = _byRouteStop[(pattern.routeUid, pattern.direction, stop.uid)]
          ?.where((a) => a.subRouteUid.isEmpty)
          .toList();
    }
    if (pattern.subRouteUid.isEmpty && routePatterns.isEmpty) return null;
    if (candidates == null) return null;
    final exact =
        candidates.where((a) => a.stopSequence == stop.sequence).toList();
    if (exact.length == 1) return exact.single;
    // API 未提供站序時，僅在站牌出現一次且資料唯一時配對。
    // 迴圈路線重複經過同一站且無站序，寧可不顯示也不猜測。
    if (candidates.length == 1 &&
        candidates.single.stopSequence == null &&
        pattern.stops.where((s) => s.uid == stop.uid).length == 1) {
      return candidates.single;
    }
    return null;
  }
}
