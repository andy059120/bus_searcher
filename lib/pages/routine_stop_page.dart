import 'package:flutter/material.dart';
//import 'home_page.dart';
import '../utils/get_access_token.dart';
import '../utils/get_bus_stops_of_route.dart';
import '../utils/bus_stop.dart';
import '../utils/get_estimated_bus_stop.dart';
import '../utils/estimated_bus_stop.dart';

class MyRoutineStopPage extends StatefulWidget {
  final String busCode;
  final String stopDirectionZh;
  final String stopNameZh;
  final String estimateTime;

  const MyRoutineStopPage(
      {super.key,
      required this.busCode,
      required this.stopDirectionZh,
      required this.stopNameZh,
      required this.estimateTime});

  @override
  State<MyRoutineStopPage> createState() => _MyRoutineStopPageState(
        busCode: busCode,
        stopDirectionZh: stopDirectionZh,
        stopNameZh: stopNameZh,
        estimateTime: estimateTime,
      );
}

class _MyRoutineStopPageState extends State<MyRoutineStopPage> {
  _MyRoutineStopPageState(
      {required this.busCode,
      required this.stopDirectionZh,
      required this.stopNameZh,
      required this.estimateTime});
  final String busCode;
  final String stopDirectionZh;
  final String stopNameZh;
  final String estimateTime;
  late Future<String> futureAccessToken;
  late Future<List<BusStop>> futureBusStops;
  late Future<List<EstimateBusStop>> futureEstimateBusStops;

  @override
  void initState() {
    super.initState();
    futureAccessToken = getAccessToken();
    futureBusStops = getBusStopsOfRoute(futureAccessToken, busCode);
    futureEstimateBusStops = getEstimateBusStop(futureAccessToken, busCode);
  }

  void reloadWindow() {
    setState(() {
      futureEstimateBusStops = getEstimateBusStop(futureAccessToken, busCode);
    });
  }

  Future<void> refreshTime() async {
    // 模擬刷新操作，比如從網絡或其他地方重新加載數據
    await Future.delayed(const Duration(seconds: 10));

    setState(() {
      futureEstimateBusStops = getEstimateBusStop(futureAccessToken, busCode);
    });
    print("refresh");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.cyanAccent.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '常用站牌',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              ),
            ]),
      ),
      backgroundColor: const Color.fromARGB(255, 184, 232, 255),
      body: RefreshIndicator(
        onRefresh: refreshTime,
        child: ListTile(
          title: //Text("d"),
              Text(
                  '$estimateTime - $busCode - 往$stopDirectionZh - $stopNameZh'),
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        fixedColor: const Color.fromARGB(255, 54, 212, 244),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location_alt),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
