import 'dart:async';

import 'package:bus_project/data/models/bus_city.dart';
import 'package:bus_project/data/models/bus_route.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/bus_fixtures.dart';

void main() {
  test('combined search preserves a successful city when the other fails',
      () async {
    final harness = BusHarness(
        respond: (request) => request.url.path.endsWith('/NewTaipei')
            ? http.Response('', 503)
            : jsonResponse([routeJson()]));
    addTearDown(harness.close);
    final result = await harness.repository.searchAllRoutes('262');
    expect(result.routes.single.uid, 'TPE262');
    expect(result.warning, contains('新北市'));
    expect(result.warning, contains('503'));
  });

  test(
      'empty input makes no request; input is quoted and only selected city is queried',
      () async {
    final harness = BusHarness();
    addTearDown(harness.close);
    expect(
        await harness.repository.searchRoutes('  ', BusCity.taipei), isEmpty);
    expect(harness.requests, isEmpty);
    final routes =
        await harness.repository.searchRoutes("  紅'5  ", BusCity.newTaipei);
    expect(routes.single.city, BusCity.newTaipei);
    final uri = harness.dataRequests.single.url;
    expect(uri.path, endsWith('/Route/City/NewTaipei'));
    expect(
        uri.queryParameters[r'$filter'], "contains(RouteName/Zh_tw, '紅''5')");
  });

  test(
      'concurrent duplicate searches share one request; cache expires in one hour',
      () async {
    final response = Completer<http.Response>();
    final harness = BusHarness(respond: (_) => response.future);
    addTearDown(harness.close);
    final first = harness.repository.searchRoutes('262', BusCity.taipei);
    final second = harness.repository.searchRoutes('262', BusCity.taipei);
    response.complete(jsonResponse([routeJson()]));
    await Future.wait([first, second]);
    await harness.repository.searchRoutes('262', BusCity.taipei);
    expect(harness.dataRequests, hasLength(1));
    harness.now = harness.now.add(const Duration(hours: 1));
    await harness.repository.searchRoutes('262', BusCity.taipei);
    expect(harness.dataRequests, hasLength(2));
  });

  test('route requests keep city and UID; cache stops for 24h and ETA for 60s',
      () async {
    final harness = BusHarness();
    addTearDown(harness.close);
    await harness.repository.getStops(testRoute);
    final first = await harness.repository.getArrivals(testRoute);
    harness.now = harness.now.add(const Duration(seconds: 59));
    final cached = await harness.repository.getArrivals(testRoute);
    expect(cached.fetchedAt, first.fetchedAt);
    expect(harness.dataRequests, hasLength(2));
    harness.now = harness.now.add(const Duration(seconds: 1));
    final refreshed = await harness.repository.getArrivals(testRoute);
    expect(refreshed.fetchedAt, harness.now);
    await harness.repository.getStops(testRoute);
    expect(harness.dataRequests, hasLength(3));
    for (final request in harness.dataRequests) {
      expect(request.url.path, endsWith('/City/Taipei'));
      expect(request.url.queryParameters[r'$filter'], "RouteUID eq 'TPE262'");
    }
    harness.now = harness.now.add(const Duration(hours: 24));
    await harness.repository.getStops(testRoute);
    expect(harness.dataRequests, hasLength(4));
  });

  test('same route name in another city has its own cache', () async {
    final harness = BusHarness();
    addTearDown(harness.close);
    const newTaipeiRoute = BusRoute(
        uid: 'NWT262',
        city: BusCity.newTaipei,
        routeName: '262',
        departureStopNameZh: '起點',
        destinationStopNameZh: '終點');
    await harness.repository.getStops(testRoute);
    expect(await harness.repository.getStops(newTaipeiRoute), isEmpty);
    expect(harness.dataRequests, hasLength(2));
  });

  test('whitespace empty array is a valid empty result', () async {
    final harness = BusHarness(respond: (_) => http.Response(' [ ] \n', 200));
    addTearDown(harness.close);
    expect(await harness.repository.getStops(testRoute), isEmpty);
  });

  for (final body in ['not json', '{}', '[{}]']) {
    test('malformed response is sanitized and not cached: $body', () async {
      var calls = 0;
      final harness = BusHarness(
          respond: (_) => ++calls == 1
              ? http.Response(body, 200)
              : jsonResponse([routeJson()]));
      addTearDown(harness.close);
      await expectLater(harness.repository.searchRoutes('262', BusCity.taipei),
          throwsA(isA<TdxException>()));
      expect(await harness.repository.searchRoutes('262', BusCity.taipei),
          hasLength(1));
      expect(calls, 2);
    });
  }

  test(
      'authentication and data requests share five slots, with no queued sixth call',
      () async {
    final harness = BusHarness();
    addTearDown(harness.close);
    await harness.repository.searchRoutes('262', BusCity.taipei);
    await harness.repository.getStops(testRoute);
    await harness.repository.getArrivals(testRoute);
    await harness.repository.searchRoutes('紅5', BusCity.taipei);
    expect(harness.requests, hasLength(5));
    await expectLater(
        harness.repository.searchRoutes('藍1', BusCity.taipei),
        throwsA(
            isA<TdxException>().having((e) => e.statusCode, 'status', 429)));
    expect(harness.requests, hasLength(5));
    // 快取命中不消耗額度，即使用量已滿仍可讀取。
    expect(await harness.repository.searchRoutes('262', BusCity.taipei),
        hasLength(1));
    harness.now = harness.now.add(const Duration(seconds: 61));
    await harness.repository.searchRoutes('藍1', BusCity.taipei);
    expect(harness.requests, hasLength(6));
  });

  test('429 Retry-After blocks later requests and is not automatically retried',
      () async {
    var calls = 0;
    final harness = BusHarness(
        respond: (_) => ++calls == 1
            ? jsonResponse([], status: 429, headers: {'retry-after': '120'})
            : jsonResponse([routeJson()]));
    addTearDown(harness.close);
    await expectLater(harness.repository.searchRoutes('262', BusCity.taipei),
        throwsA(isA<TdxException>()));
    harness.now = harness.now.add(const Duration(seconds: 61));
    await expectLater(harness.repository.searchRoutes('262', BusCity.taipei),
        throwsA(isA<TdxException>()));
    expect(calls, 1);
    harness.now = harness.now.add(const Duration(seconds: 59));
    await harness.repository.searchRoutes('262', BusCity.taipei);
    expect(calls, 2);
  });
}
