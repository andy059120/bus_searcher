import 'dart:convert';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/data/models/bus_route.dart';

Future<List<BusRoute>> getBusRoute(String routeName) async {
  final List<BusRoute> routesOfTaipei, routesOfNewTaipei;

  final responseOfTaipei = await tdxApiClient.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/Route/City/NewTaipei/$routeName'),
  );

  final responseOfNewTaipei = await tdxApiClient.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/Route/City/Taipei/$routeName'),
  );

  if (responseOfNewTaipei.statusCode == 200) {
    routesOfTaipei = json
        .decode(responseOfTaipei.body)
        .map((model) => BusRoute.fromJson(model))
        .toList()
        .cast<BusRoute>();
    routesOfNewTaipei = json
        .decode(responseOfNewTaipei.body)
        .map((model) => BusRoute.fromJson(model))
        .toList()
        .cast<BusRoute>();
    //print(jsonDecode(responseOfNewTaipei.body));
    return routesOfTaipei + routesOfNewTaipei;
  } else {
    // If the server did not return a 200 OK response, then throw an exception.
    throw Exception('Failed to get busRoutes');
  }
}
