import 'package:flutter/material.dart';
import 'package:bus_project/data/services/bus_repository.dart';
import 'package:bus_project/features/favorites/data/favorites_store.dart';
import 'package:bus_project/features/route_detail/presentation/route_detail_page.dart';

class MyRoutineStopPage extends StatelessWidget {
  const MyRoutineStopPage({super.key, required this.repository});

  final BusRepository repository;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: favoritesStore,
        builder: (context, _) {
          final favorites = favoritesStore.items;
          return Column(children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('收藏僅保留於本次使用期間；點選站牌可查看該路線到站資訊。'),
            ),
            Expanded(
                child: favorites.isEmpty
                    ? const Center(child: Text('尚無常用站牌，可在路線明細點選星號加入。'))
                    : ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = favorites[index];
                          return ListTile(
                            title: Text(
                                '${favorite.route.routeName}・${favorite.stop.name}'),
                            subtitle: Text(
                                '${favorite.route.city.label}・${favorite.pattern.label}'),
                            trailing: IconButton(
                              tooltip: '移除常用站牌',
                              icon: const Icon(Icons.star),
                              onPressed: () => favoritesStore.toggle(favorite),
                            ),
                            // 收藏清單本身不發出請求，進入路線時沿用共用快取。
                            onTap: () =>
                                Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MyRouteDetailPage(
                                route: favorite.route,
                                repository: repository,
                                initialSubRouteUid:
                                    favorite.pattern.subRouteUid,
                                initialDirection: favorite.pattern.direction,
                              ),
                            )),
                          );
                        },
                      )),
          ]);
        },
      );
}
