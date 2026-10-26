import 'dart:async';

import 'package:bus_project/features/favorites/data/favorites_store.dart';
import 'package:bus_project/features/home/presentation/home_page.dart';
import 'package:bus_project/features/route_detail/presentation/route_detail_page.dart';
import 'package:bus_project/features/search/presentation/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/bus_fixtures.dart';

void main() {
  tearDown(() {
    for (final favorite in favoritesStore.items) {
      favoritesStore.toggle(favorite);
    }
  });

  testWidgets('all home destinations work without making a request',
      (tester) async {
    final harness = BusHarness();
    addTearDown(harness.close);
    await tester.pumpWidget(
        MaterialApp(home: HomePage(repository: harness.repository)));
    await tester.tap(find.text('常用站牌'));
    await tester.pumpAndSettle();
    expect(find.text('尚無常用站牌，可在路線明細點選星號加入。'), findsOneWidget);
    await tester.tap(find.text('首頁'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(harness.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'typing searches both cities after debounce, narrowing reuses results',
      (tester) async {
    final harness = BusHarness();
    addTearDown(harness.close);
    await tester.pumpWidget(
        MaterialApp(home: MySearchPage(repository: harness.repository)));
    await tester.tap(find.byTooltip('搜尋'));
    await tester.pump();
    expect(harness.requests, isEmpty);
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump(const Duration(milliseconds: 400));
    expect(harness.requests, isEmpty);
    await tester.enterText(find.byType(TextField), '26');
    await tester.pump(const Duration(milliseconds: 400));
    expect(harness.requests, isEmpty);
    await tester.enterText(find.byType(TextField), '262');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(harness.dataRequests, hasLength(2));
    expect(find.textContaining('262  起點 - 終點'), findsWidgets);
    await tester.enterText(find.byType(TextField), '262區');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(harness.dataRequests, hasLength(2));
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(harness.dataRequests, hasLength(2));
  });

  testWidgets(
      'branch switching, favorites and refresh within 60s reuse the route snapshot',
      (tester) async {
    final harness = BusHarness();
    addTearDown(harness.close);
    await tester.pumpWidget(MaterialApp(
        home: MyRouteDetailPage(
      route: testRoute,
      repository: harness.repository,
    )));
    await tester.pumpAndSettle();
    expect(harness.dataRequests, hasLength(2));
    expect(find.textContaining('3 分 -', findRichText: true), findsOneWidget);
    expect(find.textContaining('暫無預估 -', findRichText: true), findsOneWidget);
    await tester.tap(find.textContaining('3 分 -', findRichText: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增為常用站牌'));
    await tester.pumpAndSettle();
    expect(favoritesStore.items, hasLength(1));
    await tester.tap(find.text('往 起點'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('更新到站資料'));
    await tester.pumpAndSettle();
    expect(harness.dataRequests, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('late stop response after leaving page does not start ETA query',
      (tester) async {
    final response = Completer<http.Response>();
    final harness = BusHarness(respond: (_) => response.future);
    addTearDown(harness.close);
    await tester.pumpWidget(MaterialApp(
        home: MyRouteDetailPage(
      route: testRoute,
      repository: harness.repository,
    )));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    response.complete(jsonResponse([patternJson()]));
    await tester.pumpAndSettle();
    expect(harness.dataRequests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh waits for response and tolerates leaving the page',
      (tester) async {
    final refresh = Completer<http.Response>();
    var arrivalCalls = 0;
    final harness = BusHarness(respond: (request) {
      if (request.url.path.contains('/StopOfRoute/')) {
        return jsonResponse([patternJson()]);
      }
      if (++arrivalCalls == 1) return jsonResponse([arrivalJson()]);
      return refresh.future;
    });
    addTearDown(harness.close);
    await tester.pumpWidget(MaterialApp(
        home: MyRouteDetailPage(
      route: testRoute,
      repository: harness.repository,
    )));
    await tester.pumpAndSettle();
    harness.now = harness.now.add(const Duration(seconds: 61));
    await tester.tap(find.byTooltip('更新到站資料'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    refresh.complete(jsonResponse([arrivalJson(seconds: 60)]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed refresh preserves stops and the previous timestamp',
      (tester) async {
    var arrivalCalls = 0;
    final harness = BusHarness(respond: (request) {
      if (request.url.path.contains('/StopOfRoute/')) {
        return jsonResponse([patternJson()]);
      }
      return ++arrivalCalls == 1
          ? jsonResponse([arrivalJson()])
          : http.Response('', 500);
    });
    addTearDown(harness.close);
    await tester.pumpWidget(MaterialApp(
        home: MyRouteDetailPage(
      route: testRoute,
      repository: harness.repository,
    )));
    await tester.pumpAndSettle();
    final originalTimestamp =
        tester.widget<Text>(find.textContaining('取得於')).data!;
    harness.now = harness.now.add(const Duration(seconds: 61));
    await tester.tap(find.byTooltip('更新到站資料'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 分 - 車站', findRichText: true), findsOneWidget);
    expect(find.textContaining('3 分 -', findRichText: true), findsOneWidget);
    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.text(originalTimestamp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
