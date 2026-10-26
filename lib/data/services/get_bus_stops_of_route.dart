import 'dart:convert';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/data/models/bus_stop.dart';

Future<List<BusStop>> getBusStopsOfRoute(String routeName) async {
  final List<BusStop> stopsOfTaipei, stopsOfNewTaipei;

  final responseOfTaipei = await tdxApiClient.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/DisplayStopOfRoute/City/Taipei/$routeName'),
  );

  final responseOfNewTaipei = await tdxApiClient.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/DisplayStopOfRoute/City/NewTaipei/$routeName'),
  );

  if (responseOfNewTaipei.statusCode == 200 &&
      responseOfNewTaipei.body != [].toString()) {
    stopsOfNewTaipei = json
        .decode(responseOfNewTaipei.body)
        .map((model) => BusStop.fromJson(model))
        .toList()
        .cast<BusStop>();
    return stopsOfNewTaipei;
  } else if (responseOfTaipei.statusCode == 200 &&
      responseOfTaipei.body != [].toString()) {
    stopsOfTaipei = json
        .decode(responseOfTaipei.body)
        .map((model) => BusStop.fromJson(model))
        .toList()
        .cast<BusStop>();
    return stopsOfTaipei;
  } else {
    // If the server did not return a 200 OK response, then throw an exception.
    throw Exception('Failed to get busStops');
  }
}
//262 & 262區的問題，能否只處理前兩筆回傳資料就好？
