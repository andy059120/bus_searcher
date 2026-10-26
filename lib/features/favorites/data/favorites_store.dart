import 'package:flutter/foundation.dart';
import 'package:bus_project/data/models/bus_route.dart';
import 'package:bus_project/data/models/bus_stop.dart';

class FavoriteStop {
  const FavoriteStop(
      {required this.route, required this.pattern, required this.stop});

  final BusRoute route;
  final BusStop pattern;
  final RouteStop stop;

  // 同站名、不同城市／支線／方向及迴圈站序，均視為不同收藏。
  (String, String, String, int, String, int) get key => (
        route.city.apiName,
        route.uid,
        pattern.subRouteUid,
        pattern.direction,
        stop.uid,
        stop.sequence,
      );
}

/// 先提供本次使用期間的收藏；不額外查詢 API，也不宣稱已永久儲存。
class FavoritesStore extends ChangeNotifier {
  final List<FavoriteStop> _items = [];

  List<FavoriteStop> get items => List.unmodifiable(_items);

  bool contains(FavoriteStop stop) =>
      _items.any((item) => item.key == stop.key);

  void toggle(FavoriteStop stop) {
    final index = _items.indexWhere((item) => item.key == stop.key);
    if (index < 0) {
      _items.add(stop);
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }
}

final favoritesStore = FavoritesStore();
