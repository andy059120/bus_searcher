import 'dart:convert';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/data/models/estimated_bus_stop.dart';

Future<List<EstimateBusStop>> getEstimateBusStop(String routeName) async {
  final List<EstimateBusStop> stopsOfTaipei, stopsOfNewTaipei;

  final responseOfTaipei = await tdxApiClient.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taipei/$routeName'),
  );

  final responseOfNewTaipei = await tdxApiClient.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei/$routeName'),
  );

  if (responseOfNewTaipei.statusCode == 200 &&
      responseOfNewTaipei.body != [].toString()) {
    stopsOfNewTaipei = json
        .decode(responseOfNewTaipei.body)
        .map((model) => EstimateBusStop.fromJson(model))
        .where((busStop) => busStop.estimateTime != null)
        .toList()
        .cast<EstimateBusStop>();
    return stopsOfNewTaipei;
  } else if (responseOfTaipei.statusCode == 200 &&
      responseOfTaipei.body != [].toString()) {
    stopsOfTaipei = json
        .decode(responseOfTaipei.body)
        .map((model) => EstimateBusStop.fromJson(model))
        .where((busStop) => busStop.estimateTime != null)
        .toList()
        .cast<EstimateBusStop>();
    return stopsOfTaipei;
  } else {
    // If the server did not return a 200 OK response, then throw an exception.
    throw Exception('Failed to get estimateBusStops');
  }
}
