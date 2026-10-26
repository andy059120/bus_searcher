import 'dart:async';
import 'dart:convert';

import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/models/bus_city.dart';
import 'package:bus_project/data/models/bus_route.dart';
import 'package:bus_project/data/services/bus_repository.dart';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/data/services/tdx_token_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const testRoute = BusRoute(
  uid: 'TPE262',
  city: BusCity.taipei,
  routeName: '262',
  departureStopNameZh: '起點',
  destinationStopNameZh: '終點',
);

Map<String, dynamic> routeJson({String uid = 'TPE262'}) => {
      'RouteUID': uid,
      'RouteName': {'Zh_tw': '262'},
      'DepartureStopNameZh': '起點',
      'DestinationStopNameZh': '終點',
    };

Map<String, dynamic> patternJson(
        {String subRoute = 'TPE2620', int direction = 0}) =>
    {
      'RouteUID': 'TPE262',
      'SubRouteUID': subRoute,
      'SubRouteName': {'Zh_tw': '262'},
      'Direction': direction,
      'Stops': [
        {
          'StopUID': 'STOP1',
          'StopName': {'Zh_tw': '車站'},
          'StopSequence': 1
        },
        {
          'StopUID': 'STOP2',
          'StopName': {'Zh_tw': '車站北'},
          'StopSequence': 2
        },
      ],
    };

Map<String, dynamic> arrivalJson({
  String route = 'TPE262',
  String subRoute = 'TPE2620',
  String stop = 'STOP1',
  int direction = 0,
  int? sequence = 1,
  int? seconds = 180,
  int? status = 0,
}) =>
    {
      'RouteUID': route,
      'SubRouteUID': subRoute,
      'StopUID': stop,
      'Direction': direction,
      'StopSequence': sequence,
      'EstimateTime': seconds,
      'StopStatus': status,
    };

http.Response jsonResponse(Object data,
        {int status = 200, Map<String, String>? headers}) =>
    http.Response(jsonEncode(data), status, headers: {
      'content-type': 'application/json; charset=utf-8',
      ...?headers
    });

class BusHarness {
  BusHarness({FutureOr<http.Response> Function(http.Request)? respond}) {
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST') {
        return jsonResponse({
          'access_token': 'test-token',
          'expires_in': 3600,
          'token_type': 'Bearer'
        });
      }
      if (respond != null) return respond(request);
      if (request.url.path.contains('/StopOfRoute/')) {
        return jsonResponse([
          patternJson(),
          patternJson(subRoute: 'TPE2621', direction: 1),
        ]);
      }
      if (request.url.path.contains('/EstimatedTimeOfArrival/')) {
        return jsonResponse([arrivalJson()]);
      }
      return jsonResponse([routeJson()]);
    });
    api = TdxApiClient(
        client: client,
        tokenService: TdxTokenService(
          client: client,
          now: () => now,
          credentials: const TdxCredentials(
              clientId: 'test-id', clientSecret: 'test-secret'),
        ));
    repository = BusRepository(api: api, now: () => now);
  }

  DateTime now = DateTime.utc(2026, 10, 26);
  final List<http.Request> requests = [];
  late final TdxApiClient api;
  late final BusRepository repository;

  List<http.Request> get dataRequests =>
      requests.where((r) => r.method == 'GET').toList();
  void close() => api.close();
}
