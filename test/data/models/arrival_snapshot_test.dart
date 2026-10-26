import 'package:bus_project/data/models/bus_stop.dart';
import 'package:bus_project/data/models/estimated_bus_stop.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/bus_fixtures.dart';

void main() {
  test('missing branch UID does not guess an ETA', () {
    final pattern = BusStop.fromJson(patternJson(subRoute: ''));
    final snapshot = ArrivalSnapshot([
      EstimateBusStop.fromJson(arrivalJson(subRoute: '')),
    ], DateTime.utc(2026));
    expect(snapshot.find(pattern, pattern.stops.first), isNull);
  });

  test('station matching uses route, branch, direction and UID instead of name',
      () {
    final pattern = BusStop.fromJson(patternJson());
    final arrivals = ArrivalSnapshot([
      EstimateBusStop.fromJson(
          arrivalJson(stop: 'STOP2', sequence: 2, seconds: 60)),
      EstimateBusStop.fromJson(arrivalJson(route: 'OTHER', seconds: 10)),
      EstimateBusStop.fromJson(arrivalJson(subRoute: 'OTHER', seconds: 20)),
      EstimateBusStop.fromJson(arrivalJson(direction: 1, seconds: 30)),
      EstimateBusStop.fromJson(arrivalJson(seconds: 180)),
    ], DateTime.utc(2026));
    expect(arrivals.find(pattern, pattern.stops.first)?.label, '3 分');
    expect(arrivals.find(pattern, pattern.stops.last)?.label, '將進站');
  });

  test('loop stations match by sequence; absent sequence is not guessed', () {
    final json = patternJson();
    json['Stops'] = [
      {
        'StopUID': 'STOP1',
        'StopName': {'Zh_tw': '車站'},
        'StopSequence': 3
      },
      {
        'StopUID': 'STOP1',
        'StopName': {'Zh_tw': '車站'},
        'StopSequence': 1
      },
    ];
    final pattern = BusStop.fromJson(json);
    expect(pattern.stops.first.sequence, 1);
    final exact = ArrivalSnapshot([
      EstimateBusStop.fromJson(arrivalJson(sequence: 3, seconds: 240)),
      EstimateBusStop.fromJson(arrivalJson(sequence: 1, seconds: 120)),
    ], DateTime.utc(2026));
    expect(exact.find(pattern, pattern.stops.first)?.label, '2 分');
    expect(exact.find(pattern, pattern.stops.last)?.label, '4 分');
    final ambiguous = ArrivalSnapshot([
      EstimateBusStop.fromJson(arrivalJson(sequence: null)),
    ], DateTime.utc(2026));
    expect(ambiguous.find(pattern, pattern.stops.first), isNull);
  });

  test('single unique station can match an ETA without sequence', () {
    final pattern = BusStop.fromJson(patternJson());
    final snapshot = ArrivalSnapshot([
      EstimateBusStop.fromJson(arrivalJson(sequence: null)),
    ], DateTime.utc(2026));
    expect(snapshot.find(pattern, pattern.stops.first)?.label, '3 分');
  });

  test('null ETA preserves operating status and unknown data remains unknown',
      () {
    for (final entry in {
      0: '暫無預估',
      1: '尚未發車',
      2: '交管不停靠',
      3: '末班車已過',
      4: '今日未營運',
      99: '狀態未提供',
    }.entries) {
      expect(
          EstimateBusStop.fromJson(
                  arrivalJson(seconds: null, status: entry.key))
              .label,
          entry.value);
    }
    expect(EstimateBusStop.fromJson(arrivalJson(seconds: -1)).label, '暫無預估');
  });

  test('direction values outside zero and one do not index endpoint names', () {
    expect(BusStop.fromJson(patternJson(direction: 2)).label, contains('迴圈'));
    expect(BusStop.fromJson(patternJson(direction: 255)).label,
        contains('方向 255'));
  });
}
