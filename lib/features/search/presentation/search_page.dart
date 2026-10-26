import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bus_project/data/models/bus_route.dart';
import 'package:bus_project/data/services/bus_repository.dart';
import 'package:bus_project/features/route_detail/presentation/route_detail_page.dart';
import 'package:bus_project/shared/widgets/bus_app_bar.dart';
import 'package:bus_project/shared/widgets/query_message.dart';

class MySearchPage extends StatefulWidget {
  const MySearchPage({super.key, required this.repository});

  final BusRepository repository;

  @override
  State<MySearchPage> createState() => _MySearchPageState();
}

class _MySearchPageState extends State<MySearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  RouteSearchResult? _result;
  String? _error;
  bool _loading = false;
  int _generation = 0;
  String _lastQuery = '';
  DateTime? _lastFetchedAt;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // 立即作廢舊結果的畫面更新；不讓慢回應覆蓋最新輸入。
    _generation++;
    setState(() {
      _error = null;
      _loading = value.trim().isNotEmpty;
      _result = null;
    });
    if (value.trim().isNotEmpty) {
      // 保留原本輸入即搜尋的操作，以 debounce 合併連續按鍵。
      _debounce = Timer(const Duration(milliseconds: 800), _search);
    }
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    final generation = ++_generation;
    // 既有結果是 contains 搜尋的完整集合，縮小關鍵字可直接本機篩選。
    // 保留原集合，避免刪字後遺失先前的路線。
    if (_lastQuery.isNotEmpty &&
        query.contains(_lastQuery) &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < BusRepository.searchTtl &&
        _completeResult != null) {
      setState(() {
        _loading = false;
        _error = null;
        _result = RouteSearchResult(_completeResult!.routes
            .where((route) => route.routeName.contains(query))
            .toList());
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.searchAllRoutes(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        if (result.warning == null) {
          _completeResult = result;
          _lastQuery = query;
          _lastFetchedAt = DateTime.now();
        }
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = queryErrorMessage(error));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  RouteSearchResult? _completeResult;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BusAppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: '公車路線搜尋：',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
            onChanged: _onChanged,
            onSubmitted: (_) => _search(),
          ),
          actions: [
            IconButton(
                tooltip: '搜尋',
                onPressed: _search,
                icon: const Icon(Icons.search))
          ],
        ),
        body: Column(children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) QueryMessage(message: _error!, onRetry: _search),
          if (_result?.warning != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_result!.warning!),
            ),
          Expanded(child: _buildResults()),
        ]),
      );

  Widget _buildResults() {
    if (_result == null) {
      return Center(child: Text(_loading ? '搜尋中…' : '輸入公車路線，例如 262'));
    }
    final routes = _result!.routes;
    if (routes.isEmpty) return const Center(child: Text('找不到符合的公車路線'));
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(7),
      itemCount: routes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _routeTile(routes[index]),
    );
  }

  Widget _routeTile(BusRoute route) => ListTile(
        title: Text(
            '${route.routeName}  ${route.departureStopNameZh} - ${route.destinationStopNameZh}',
            style: const TextStyle(
                fontSize: 16, color: Color.fromARGB(255, 67, 67, 67))),
        onTap: () {
          _debounce?.cancel();
          FocusScope.of(context).unfocus();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MyRouteDetailPage(
                    route: route,
                    repository: widget.repository,
                  )));
        },
      );
}
