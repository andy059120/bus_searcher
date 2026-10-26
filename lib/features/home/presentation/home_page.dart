import 'package:flutter/material.dart';
import 'package:bus_project/data/services/bus_repository.dart';
import 'package:bus_project/features/favorites/presentation/routine_stop_page.dart';
import 'package:bus_project/features/search/presentation/search_page.dart';
import 'package:bus_project/shared/widgets/bus_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});

  final BusRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _openSearch() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MySearchPage(repository: widget.repository),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BusAppBar(
            title: _selectedIndex == 0
                ? TextField(
                    readOnly: true,
                    textAlign: TextAlign.center,
                    onTap: _openSearch,
                    decoration: const InputDecoration(
                      hintText: '點我進行公車路線搜尋',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  )
                : const Text('常用站牌')),
        body: _selectedIndex == 0
            ? const Center(
                child: Icon(Icons.directions_bus_filled,
                    size: 300, color: Color.fromARGB(255, 129, 196, 250)))
            : MyRoutineStopPage(repository: widget.repository),
        // 保留原本底部導覽的外觀，項目只對應已實作的頁面。
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color.fromARGB(255, 54, 212, 244),
          unselectedItemColor: Colors.grey.shade500,
          iconSize: 30,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: '常用站牌'),
          ],
        ),
      );
}
