import 'package:flutter/material.dart';
import 'search_page.dart';
//import 'route_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;
  final List<Widget> _pages = [
    PageOne(),
    const MySearchPage(),
    //MyRouteDetailPage(),
  ];

  /*void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }*/

  Future<void> _performSearch() async {
    setState(() {
      //_isLoading = true;
    });

    //Simulates waiting for an API call
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  @override
  Widget build(BuildContext context) {
    //var numArr = [1, 2, 3];
    //var numArr2 = numArr.map((e) => e + 1);
    //numArr2 = [2, 3, 4]
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
          textAlign: TextAlign.center,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: '點我進行公車路線搜尋',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            //suffixIcon: Icon(Icons.search, color: Colors.white54),
            /*prefix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white54),
                SizedBox(width: 8.0), // 調整圖標和文字之間的距離
              ],
            ),*/
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MySearchPage(),
              ),
            );
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 184, 232, 255),
      body: //const Text("bus app"),
          _pages[_selectedIndex],
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
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          }),
      //backgroundColor: Colors.deepPurple.shade900,
    );
  }
}

AppBar appBar() {
  return AppBar(
    title: const Text("Search"),
  );
}

/* bottomNavigationBar
首頁
搜尋
細節
自定義
*/

class PageOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Icon(
            Icons.directions_bus_filled,
            size: 300,
            color: Color.fromARGB(255, 129, 196, 250), // 圖標顏色
          ),
        ),
        Center(
          child: Text(
            '',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
