import 'package:flutter/material.dart';
import 'route_detail_page.dart';
import '../utils/get_access_token.dart';
import '../utils/get_bus_route.dart';
import '../utils/bus_route.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus App',
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              fontSize: 20,
              fontFamily: 'Hind',
              color: Color.fromARGB(255, 0, 0, 0)),
        ),
      ),
      home: const MySearchPage(),
    );
  }
}

class MySearchPage extends StatefulWidget {
  const MySearchPage({Key? key}) : super(key: key);

  @override
  State<MySearchPage> createState() => _MySearchPageState();
}

class _MySearchPageState extends State<MySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<String> futureAccessToken;
  late Future<List<BusRoute>> futureBusRoutes;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    futureAccessToken = getAccessToken();
    futureBusRoutes = getBusRoute(futureAccessToken, '0000');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      //_isLoading = true;
    });

    //Simulates waiting for an API call
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.cyanAccent.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: '公車路線搜尋：',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value != "") {
              futureBusRoutes = getBusRoute(futureAccessToken, value);
            } else {
              futureBusRoutes = getBusRoute(futureAccessToken, "0000");
            }
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 184, 232, 255),
      body: Container(
        margin: const EdgeInsets.all(7),
        child: FutureBuilder<List<BusRoute>>(
          future: futureBusRoutes,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, index) {
                  return ListTile(
                    title: Text(
                      '${snapshot.data?[index].routeName}  ${snapshot.data?[index].departureStopNameZh} - ${snapshot.data?[index].destinationStopNameZh}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Color.fromARGB(255, 67, 67, 67),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MyRouteDetailPage(
                            busCode: snapshot.data![index].routeName,
                            stopName0Zh:
                                snapshot.data![index].destinationStopNameZh,
                            stopName1Zh:
                                snapshot.data![index].departureStopNameZh,
                          ),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(
                    color: Color.fromARGB(255, 171, 171, 171),
                  );
                },
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
