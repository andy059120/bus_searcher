import 'dart:convert';
import 'dart:io';

import 'package:bus_project/data/models/bus_stop.dart';
import 'package:bus_project/data/models/estimated_bus_stop.dart';
import 'package:bus_project/features/search/presentation/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/bus_fixtures.dart';

List<dynamic> fixture(String name) => jsonDecode(
      File('test/fixtures/tdx_262/$name.json').readAsStringSync(),
    ) as List;

void main() {
  test(
      'real Taipei 262 payload maps all 149 stops without branch or sequence in ETA',
      () {
    final patterns = fixture('stops').map((r) => BusStop.fromJson(r)).toList();
    final records = fixture('arrivals');
    expect(
        records.every((r) =>
            !r.containsKey('SubRouteUID') && !r.containsKey('StopSequence')),
        isTrue);
    final snapshot = ArrivalSnapshot(
        records.map((r) => EstimateBusStop.fromJson(r)).toList(),
        DateTime.utc(2026, 10, 26));
    final matched = [
      for (final pattern in patterns)
        for (final stop in pattern.stops)
          snapshot.find(pattern, stop, routePatterns: patterns)
    ];
    expect(patterns.map((p) => p.stops.length), [72, 77]);
    expect(matched, hasLength(149));
    expect(matched.where((a) => a == null), isEmpty);
    expect(matched.where((a) => a!.label == '尚未發車'), hasLength(20));
  });

  test('fallback refuses stations shared by branches in the same direction',
      () {
    final patterns = [
      BusStop.fromJson(patternJson()),
      BusStop.fromJson(patternJson(subRoute: 'OTHER'))
    ];
    final snapshot = ArrivalSnapshot([
      EstimateBusStop.fromJson(arrivalJson(subRoute: '', sequence: null)),
    ], DateTime.utc(2026));
    expect(
        snapshot.find(patterns.first, patterns.first.stops.first,
            routePatterns: patterns),
        isNull);
  });

  testWidgets(
      'real payload passes search, route selection and both direction tabs',
      (tester) async {
    final harness = BusHarness(respond: (request) {
      final path = request.url.path;
      if (path.contains('/StopOfRoute/')) return jsonResponse(fixture('stops'));
      if (path.contains('/EstimatedTimeOfArrival/')) {
        return jsonResponse(fixture('arrivals'));
      }
      return jsonResponse(fixture(
          path.endsWith('/NewTaipei') ? 'NewTaipei_routes' : 'Taipei_routes'));
    });
    addTearDown(harness.close);
    await tester.pumpWidget(
        MaterialApp(home: MySearchPage(repository: harness.repository)));
    await tester.enterText(find.byType(TextField), '262');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('262  宏國德霖科技大學 - 民生社區'), findsOneWidget);
    await tester.tap(find.text('262  宏國德霖科技大學 - 民生社區'));
    await tester.pumpAndSettle();
    expect(find.text('往 民生社區'), findsOneWidget);
    expect(find.text('往 宏國德霖科技大學'), findsOneWidget);
    expect(find.textContaining('宏國德霖科技大學', findRichText: true), findsWidgets);
    expect(find.textContaining('暫無預估 -', findRichText: true), findsNothing);
    await tester.tap(find.text('往 宏國德霖科技大學'));
    await tester.pumpAndSettle();
    expect(find.textContaining('莊敬里', findRichText: true), findsOneWidget);
    expect(find.textContaining('暫無預估 -', findRichText: true), findsNothing);
    expect(harness.requests, hasLength(5));
    expect(tester.takeException(), isNull);
  });
}
