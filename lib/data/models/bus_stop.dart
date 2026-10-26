/// 一筆站序代表一個附屬路線及方向，不將所有同方向支線混在一起。
class BusStop {
  const BusStop({
    required this.routeUid,
    required this.subRouteUid,
    required this.subRouteName,
    required this.direction,
    required this.stops,
  });

  final String routeUid;
  final String subRouteUid;
  final String subRouteName;
  final int direction;
  final List<RouteStop> stops;

  factory BusStop.fromJson(Map<String, dynamic> json) {
    final stops = (json['Stops'] as List)
        .map((stop) => RouteStop.fromJson(stop as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return BusStop(
      routeUid: json['RouteUID'] as String,
      subRouteUid: json['SubRouteUID'] as String? ?? '',
      subRouteName: json['SubRouteName']?['Zh_tw'] as String? ?? '路線',
      direction: json['Direction'] as int,
      stops: List.unmodifiable(stops),
    );
  }

  String get directionLabel => switch (direction) {
        0 => '去程',
        1 => '返程',
        2 => '迴圈',
        _ => '方向 $direction',
      };

  // 以實際站序終點顯示方向，也能處理超過 0、1 的方向值。
  String get label => '$subRouteName・$directionLabel'
      '${stops.isEmpty ? '' : ' 往 ${stops.last.name}'}';
}

class RouteStop {
  const RouteStop(
      {required this.uid, required this.name, required this.sequence});

  final String uid;
  final String name;
  final int sequence;

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
        uid: json['StopUID'] as String,
        name: json['StopName']['Zh_tw'] as String,
        sequence: json['StopSequence'] as int,
      );
}
