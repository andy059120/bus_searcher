import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'estimated_bus_stop.dart';

Future<List<EstimateBusStop>> getEstimateBusStop(
    Future<String> futureAccessToken, String routeName) async {
  final List<EstimateBusStop> stopsOfTaipei, stopsOfNewTaipei;
  String accessToken = await futureAccessToken;

  final responseOfTaipei = await http.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taipei/$routeName'),
    headers: {
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  final responseOfNewTaipei = await http.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei/$routeName'),
    headers: {
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
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
