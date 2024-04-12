import 'package:flutter/material.dart';
import 'routine_stop_page.dart';
import '../utils/get_access_token.dart';
import '../utils/get_bus_stops_of_route.dart';
import '../utils/bus_stop.dart';
import '../utils/get_estimated_bus_stop.dart';
import '../utils/estimated_bus_stop.dart';

class MyRouteDetailPage extends StatefulWidget {
  final String busCode;
  final String stopName0Zh;
  final String stopName1Zh;

  const MyRouteDetailPage(
      {super.key,
      required this.busCode,
      required this.stopName0Zh,
      required this.stopName1Zh});

  @override
  State<MyRouteDetailPage> createState() => _MyRouteDetailPageState(
        busCode: busCode,
        stopName0Zh: stopName0Zh,
        stopName1Zh: stopName1Zh,
      );
}

class _MyRouteDetailPageState extends State<MyRouteDetailPage> {
  _MyRouteDetailPageState(
      {required this.busCode,
      required this.stopName0Zh,
      required this.stopName1Zh});
  final String busCode;
  final String stopName0Zh;
  final String stopName1Zh;
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
        title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                busCode,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold),
              ),
            ]),
      ),
      backgroundColor: const Color.fromARGB(255, 184, 232, 255),
      body: RefreshIndicator(
        onRefresh: refreshTime,
        child: FutureBuilder<List<BusStop>>(
          future: futureBusStops,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Set<int> directions =
                  snapshot.data!.map((busStop) => busStop.direction).toSet();
              final List<String> stopNameStr = [stopName0Zh, stopName1Zh];
              return DefaultTabController(
                length: directions.length,
                child: Scaffold(
                  appBar: TabBar(
                    tabs: directions
                        .map((direction) =>
                            Tab(text: '往 ${stopNameStr[direction]}'))
                        .toList(),
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    //onTap: (){reloadWindow()},
                  ),
                  backgroundColor: const Color.fromARGB(255, 184, 232, 255),
                  body: TabBarView(
                    children: directions.map((direction) {
                      var busStopsForDirection = snapshot.data!
                          .where((busStop) => busStop.direction == direction)
                          .toList();
                      return FutureBuilder<List<EstimateBusStop>>(
                        future: futureEstimateBusStops,
                        builder: (context, snapshotEstimate) {
                          if (snapshotEstimate.hasData) {
                            return ListView.builder(
                              itemCount: busStopsForDirection.length,
                              itemBuilder: (context, index) {
                                var busStop = busStopsForDirection[index];
                                var stopNamesZhList = busStop.stopNamesZh;
                                var waitingTimesList =
                                    stopNamesZhList.map((stopName) {
                                  var estimateBusStop =
                                      snapshotEstimate.data!.firstWhere(
                                    (estimateBusStop) =>
                                        estimateBusStop.direction ==
                                            busStop.direction &&
                                        estimateBusStop.stopNamesZh
                                            .contains(stopName),
                                    orElse: () => const EstimateBusStop(
                                      direction: -1, // 這裡設置一個不存在的方向，表示未行駛
                                      estimateTime: -1, // 這裡設置一個不存在的等候時間，表示未行駛
                                      stopNamesZh: '未行駛', // 這裡設置未行駛的站名
                                    ),
                                  );
                                  var estimateTime =
                                      estimateBusStop.estimateTime;

                                  switch (estimateTime != -1
                                      ? (estimateTime! / 60).round()
                                      : -1) {
                                    case -1:
                                      return '未行駛';
                                    case 0:
                                      return '進站中';
                                    case 1:
                                      return '將進站';
                                    case 2:
                                    //return '2 分';
                                    default:
                                      return '${(estimateTime! / 60).round()} 分';
                                  }
                                  /*return estimateTime != -1
                                      ? ((estimateTime! / 60).round() < 3
                                          ? '將進站'
                                          : '${(estimateTime / 60).round()} 分')
                                      : '未行駛';*/
                                }).toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0;
                                        i < stopNamesZhList.length;
                                        i++)
                                      ListTile(
                                        //if(waitingTimesList[i]== '將進站')
                                        title: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '${waitingTimesList[i]}',
                                                style: TextStyle(
                                                  color: waitingTimesList[i] ==
                                                              '將進站' ||
                                                          waitingTimesList[i] ==
                                                              '進站中' ||
                                                          waitingTimesList[i] ==
                                                              '2 分' ||
                                                          waitingTimesList[i] ==
                                                              '3 分'
                                                      ? Colors.red
                                                      : const Color.fromARGB(
                                                          255, 67, 67, 67),
                                                  fontSize: 16,
                                                  //fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' - ${stopNamesZhList[i]}',
                                                style: TextStyle(
                                                  color: waitingTimesList[i] ==
                                                          '進站中'
                                                      ? Colors.red
                                                      : const Color.fromARGB(
                                                          255, 67, 67, 67),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        /*Text(
                                          '${waitingTimesList[i]} - ${stopNamesZhList[i]}',
                                          style: TextStyle(
                                            //backgroundColor: waitingTimesList[
                                            color: waitingTimesList[i] == '將進站'
                                                ? Colors.red
                                                : null,
                                          ),
                                        ),*/

                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  TextField(
                                                    textAlign: TextAlign.center,
                                                    readOnly: true,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          '$busCode - 往${stopNameStr[direction]} - ${stopNamesZhList[i]}',
                                                      hintStyle:
                                                          const TextStyle(
                                                              color: Color
                                                                  .fromARGB(
                                                                      136,
                                                                      110,
                                                                      110,
                                                                      110)),
                                                      border: InputBorder.none,
                                                    ),
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons
                                                        .directions_bus_filled),
                                                    title:
                                                        const Text('新增為常用站牌'),
                                                    onTap: () {
                                                      //丟值過去
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              MyRoutineStopPage(
                                                            busCode: busCode,
                                                            stopDirectionZh:
                                                                stopNameStr[
                                                                    direction],
                                                            stopNameZh:
                                                                stopNamesZhList[
                                                                    i],
                                                            estimateTime:
                                                                waitingTimesList[
                                                                    i],
                                                            //"9",
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            );
                          } else if (snapshotEstimate.hasError) {
                            return Text('${snapshotEstimate.error}');
                          }
                          return const CircularProgressIndicator();
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
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
