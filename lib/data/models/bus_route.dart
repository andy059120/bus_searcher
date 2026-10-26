import 'package:bus_project/data/models/bus_city.dart';

class BusRoute {
  const BusRoute({
    required this.uid,
    required this.city,
    required this.routeName,
    required this.departureStopNameZh,
    required this.destinationStopNameZh,
  });

  final String uid;
  final BusCity city;
  final String routeName;
  final String departureStopNameZh;
  final String destinationStopNameZh;

  factory BusRoute.fromJson(Map<String, dynamic> json, BusCity city) =>
      BusRoute(
        uid: json['RouteUID'] as String,
        city: city,
        routeName: json['RouteName']['Zh_tw'] as String,
        departureStopNameZh: json['DepartureStopNameZh'] as String? ?? '起點未提供',
        destinationStopNameZh:
            json['DestinationStopNameZh'] as String? ?? '終點未提供',
      );
}
