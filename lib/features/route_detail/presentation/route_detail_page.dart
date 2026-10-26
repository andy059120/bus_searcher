import 'package:flutter/material.dart';
import 'package:bus_project/data/models/bus_route.dart';
import 'package:bus_project/data/models/bus_stop.dart';
import 'package:bus_project/data/models/estimated_bus_stop.dart';
import 'package:bus_project/data/services/bus_repository.dart';
import 'package:bus_project/features/favorites/data/favorites_store.dart';
import 'package:bus_project/shared/widgets/query_message.dart';
import 'package:bus_project/shared/widgets/bus_app_bar.dart';

class MyRouteDetailPage extends StatefulWidget {
  const MyRouteDetailPage({
    super.key,
    required this.route,
    required this.repository,
    this.initialSubRouteUid,
    this.initialDirection,
  });

  final BusRoute route;
  final BusRepository repository;
  final String? initialSubRouteUid;
  final int? initialDirection;

  @override
  State<MyRouteDetailPage> createState() => _MyRouteDetailPageState();
}

class _MyRouteDetailPageState extends State<MyRouteDetailPage> {
  List<BusStop> _patterns = [];
  ArrivalSnapshot? _arrivals;
  int _selectedPattern = 0;
  bool _loadingStops = false;
  bool _refreshing = false;
  String? _stopsError;
  String? _arrivalError;

  BusRepository get _repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    if (_loadingStops) return;
    setState(() {
      _loadingStops = true;
      _stopsError = null;
    });
    try {
      final patterns = await _repository.getStops(widget.route);
      // 離開畫面後不更新 State，也不繼續發出 ETA 查詢。
      if (!mounted) return;
      final preferred = patterns.indexWhere((pattern) =>
          pattern.subRouteUid == widget.initialSubRouteUid &&
          pattern.direction == widget.initialDirection);
      setState(() {
        _patterns = patterns;
        _selectedPattern = preferred < 0 ? 0 : preferred;
      });
      if (patterns.isNotEmpty) await _refresh();
    } catch (error) {
      if (mounted) setState(() => _stopsError = queryErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingStops = false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing || _patterns.isEmpty) return;
    setState(() {
      _refreshing = true;
      _arrivalError = null;
    });
    try {
      // 等待真正的查詢完成；60 秒內的刷新直接取共用快取。
      final arrivals = await _repository.getArrivals(widget.route);
      if (mounted) setState(() => _arrivals = arrivals);
    } catch (error) {
      // 更新失敗仍保留原站序與舊快照，並明確顯示錯誤及取得時間。
      if (mounted) setState(() => _arrivalError = queryErrorMessage(error));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _timeLabel(DateTime date) {
    final local = date.toLocal();
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${local.month}/${local.day} ${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BusAppBar(
          title: Text(widget.route.routeName),
          actions: [
            IconButton(
              tooltip: '更新到站資料',
              onPressed: _loadingStops || _refreshing || _patterns.isEmpty
                  ? null
                  : _refresh,
              icon: const Icon(Icons.refresh),
            )
          ],
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_loadingStops) return const Center(child: CircularProgressIndicator());
    if (_stopsError != null) {
      return Center(
          child: QueryMessage(message: _stopsError!, onRetry: _loadStops));
    }
    if (_patterns.isEmpty) {
      return const Center(child: QueryMessage(message: '此路線目前沒有站序資料。'));
    }
    return DefaultTabController(
      length: _patterns.length,
      initialIndex: _selectedPattern,
      child: Column(children: [
        // 回到原本可直接點選／左右滑動的去返程分頁，不需展開選單。
        TabBar(
          isScrollable: _patterns.length > 2,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          onTap: (index) => _selectedPattern = index,
          tabs: _patterns
              .map((pattern) => Tab(text: _tabLabel(pattern)))
              .toList(),
        ),
        if (_arrivals != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('取得於 ${_timeLabel(_arrivals!.fetchedAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        if (_arrivalError != null)
          QueryMessage(
              message: _arrivalError!, onRetry: _refreshing ? null : _refresh),
        if (_refreshing) const LinearProgressIndicator(),
        Expanded(
            child: TabBarView(children: _patterns.map(_stopList).toList())),
      ]),
    );
  }

  String _tabLabel(BusStop pattern) {
    final destination = pattern.direction == 0
        ? widget.route.destinationStopNameZh
        : pattern.direction == 1
            ? widget.route.departureStopNameZh
            : pattern.stops.isEmpty
                ? pattern.directionLabel
                : pattern.stops.last.name;
    final sameDirection =
        _patterns.where((p) => p.direction == pattern.direction).length;
    return sameDirection > 1
        ? '${pattern.subRouteName} 往 $destination'
        : '往 $destination';
  }

  Widget _stopList(BusStop pattern) => RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          key: PageStorageKey((pattern.subRouteUid, pattern.direction)),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: pattern.stops.length,
          itemBuilder: (context, index) {
            final stop = pattern.stops[index];
            final arrival =
                _arrivals?.find(pattern, stop, routePatterns: _patterns);
            final label = arrival?.label ?? '暫無預估';
            final near = arrival?.stopStatus == 0 &&
                arrival?.estimateTime != null &&
                arrival!.estimateTime! >= 0 &&
                arrival.estimateTime! <= 180;
            return ListTile(
              title: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '$label - ',
                        style: TextStyle(
                            color: near ? Colors.red : Colors.black87)),
                    TextSpan(
                        text: stop.name,
                        style: TextStyle(
                            color:
                                label == '進站中' ? Colors.red : Colors.black87)),
                  ]),
                  style: const TextStyle(fontSize: 16)),
              onTap: () => _showStopActions(pattern, stop),
            );
          },
        ),
      );

  void _showStopActions(BusStop pattern, RouteStop stop) {
    final favorite =
        FavoriteStop(route: widget.route, pattern: pattern, stop: stop);
    final alreadySaved = favoritesStore.contains(favorite);
    showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        '${widget.route.routeName} - ${_tabLabel(pattern)} - ${stop.name}')),
                ListTile(
                  leading: const Icon(Icons.directions_bus_filled),
                  title: Text(alreadySaved ? '移除常用站牌' : '新增為常用站牌'),
                  onTap: () {
                    favoritesStore.toggle(favorite);
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(alreadySaved ? '已移除常用站牌' : '已新增常用站牌'),
                    ));
                  },
                ),
              ]),
            ));
  }
}
