class BusRoute {
  final String routeName;
  final String departureStopNameZh;
  final String destinationStopNameZh;

  const BusRoute({
    required this.routeName,
    required this.departureStopNameZh,
    required this.destinationStopNameZh,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      routeName: json['RouteName']['Zh_tw'],
      departureStopNameZh: json['DepartureStopNameZh'],
      destinationStopNameZh: json['DestinationStopNameZh'],
    );
  }
}
