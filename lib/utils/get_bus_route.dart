import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'bus_route.dart';

Future<List<BusRoute>> getBusRoute(
    Future<String> futureAccessToken, String routeName) async {
  final List<BusRoute> routesOfTaipei, routesOfNewTaipei;
  String accessToken = await futureAccessToken;

  final responseOfTaipei = await http.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/Route/City/NewTaipei/$routeName'),
    headers: {
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  final responseOfNewTaipei = await http.get(
    Uri.https('tdx.transportdata.tw',
        'api/basic/v2/Bus/Route/City/Taipei/$routeName'),
    headers: {
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
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

/*
Future<BusRouters> getBusRoute(
    Future<String> futureAccessToken, String routeNum, int index) async {
  final queryParameters = {
    '%24top': '30',
    '%24format': 'JSON',
  };
  var routeName = routeNum;
  //const accessToken =
  'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJER2lKNFE5bFg4WldFajlNNEE2amFVNm9JOGJVQ3RYWGV6OFdZVzh3ZkhrIn0.eyJleHAiOjE2OTYzMDkwNDksImlhdCI6MTY5NjIyMjY0OSwianRpIjoiNzU2ODgzNmItZWEwNy00NzZhLThmMzktMzUyZDk2MTRmYjVmIiwiaXNzIjoiaHR0cHM6Ly90ZHgudHJhbnNwb3J0ZGF0YS50dy9hdXRoL3JlYWxtcy9URFhDb25uZWN0Iiwic3ViIjoiNzk3YjNjZGItMGM5NC00YzNlLWE1ZmQtNDEzYTQ2MmJkYTU2IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoidTEwOTQ4MDU1LWYwZjI3NzlmLTFkYTktNGVmNCIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsic3RhdGlzdGljIiwicHJlbWl1bSIsIm1hYXMiLCJhZHZhbmNlZCIsImdyZWVubWFhcyIsImhpc3RvcmljYWwiLCJiYXNpYyJdfSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwidXNlciI6ImY3YTUwNDI3In0.olXymOOCXtPAuBqI3hBRZItYcyt8KY2nfJCwWc-N5gfHSZ8G7H-5DN9mtQuGP4lRYx7qGsRzU_PPyEaZEMu5RckboL-nK-o2HXhoxDkD3elb2Vd50nofhIakl5CfMXtdU1Sy5XZCpzjFCa677Hcqe4GeM9sWO64qu503DmU855UjGq6NJKxcHeIo8PRLwECIPTLBvHqIU5x8754EUrLEK9hSYxkFevy8gY7zthAzpFfTYavcRUBA6A8Ci5m9apDFRvMdKdkHx54eW5gH6SakG0NPLWR_7AVx2ZhiTpDW0zzNuG0q2zqcPxCvApudWPxHhbD6HmO9P0SxrLOlewfRow';
  final url = Uri.https('tdx.transportdata.tw',
      'api/basic/v2/Bus/Route/City/NewTaipei/$routeName');
  //print(url);
  //final accessToken = "$futureAccessToken";
  String accessToken = await futureAccessToken;
  final response = await http.get(
    url,
    headers: {
      //HttpHeaders.authorizationHeader: 'Bearer $futureAccessToken',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  print('Response status: ${response.statusCode}');
  //print('Response body: ${response.body}');
  if (response.statusCode == 200) {
    var resp = BusRouters.fromJson(jsonDecode(response.body));
    print(resp);
    return BusRouters.fromJson(jsonDecode(response.body));
    //return BusRoute.fromJson(jsonDecode(response.body)[index]);
  } else {
    throw Exception('Failed to get busRoute');
  }
}*/
