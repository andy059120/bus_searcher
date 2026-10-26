import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:bus_project/features/home/presentation/home_page.dart';
import 'package:bus_project/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup loads credentials once before opening the home page',
      (tester) async {
    var loads = 0;
    await tester.pumpWidget(MyApp(credentialsLoader: () async {
      loads++;
      return const TdxCredentials(
          clientId: 'test-id', clientSecret: 'test-secret');
    }));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.text('常用站牌'));
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('invalid settings show an error and can be loaded again',
      (tester) async {
    var loads = 0;
    await tester.pumpWidget(MyApp(credentialsLoader: () async {
      if (++loads == 1) throw const TdxException('測試設定載入失敗');
      return const TdxCredentials(
          clientId: 'test-id', clientSecret: 'test-secret');
    }));
    await tester.pumpAndSettle();
    expect(find.text('測試設定載入失敗'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    await tester.tap(find.text('重試'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(loads, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
