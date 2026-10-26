import 'dart:convert';

import 'package:bus_project/data/models/bus_city.dart';
import 'package:bus_project/data/models/bus_route.dart';
import 'package:bus_project/data/models/bus_stop.dart';
import 'package:bus_project/data/models/estimated_bus_stop.dart';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/data/services/tdx_exception.dart';

/// 統一城市、路線識別、快取與併發合併，畫面不自行組合 API 位址。
class BusRepository {
  BusRepository({required TdxApiClient api, DateTime Function()? now})
      : _api = api,
        _now = now ?? DateTime.now;

  final TdxApiClient _api;
  final DateTime Function() _now;
  final _cache = <Uri, _CachedResult>{};
  final Map<Uri, Future<_CachedResult>> _pending = {};

  static const searchTtl = Duration(hours: 1);
  static const stopsTtl = Duration(hours: 24);
  static const arrivalsTtl = Duration(seconds: 60);
  static const maxCacheEntries = 100;

  /// 恢復原本雙北一起搜尋；單一城市失敗時仍呈現另一城市的結果。
  Future<RouteSearchResult> searchAllRoutes(String query) async {
    if (query.trim().isEmpty) return const RouteSearchResult([]);
    final errors = <String>[];
    final results = await Future.wait(BusCity.values.map((city) async {
      try {
        return await searchRoutes(query, city);
      } on TdxException catch (error) {
        errors.add('${city.label}：${error.message}');
        return <BusRoute>[];
      }
    }));
    if (errors.length == BusCity.values.length) {
      throw TdxException(errors.join('\n'));
    }
    final routes = results.expand((rows) => rows).toList()
      ..sort((a, b) {
        final aExact = a.routeName == query.trim();
        final bExact = b.routeName == query.trim();
        if (aExact != bExact) return aExact ? -1 : 1;
        return a.routeName.compareTo(b.routeName);
      });
    return RouteSearchResult(routes,
        warning: errors.isEmpty ? null : errors.join('\n'));
  }

  Future<List<BusRoute>> searchRoutes(String query, BusCity city) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];
    final uri = _uri('Route', city, {
      r'$filter': "contains(RouteName/Zh_tw, '${_quote(keyword)}')",
    });
    final result = await _load(
      uri,
      searchTtl,
      (json) => BusRoute.fromJson(json, city),
    );
    return result.items.cast<BusRoute>();
  }

  Future<List<BusStop>> getStops(BusRoute route) async {
    final uri = _routeUri('StopOfRoute', route);
    final result = await _load(uri, stopsTtl, BusStop.fromJson);
    // 即使來源忽略 filter，也不讓其他同名路線進入明細。
    return result.items
        .cast<BusStop>()
        .where((pattern) => pattern.routeUid == route.uid)
        .toList();
  }

  Future<ArrivalSnapshot> getArrivals(BusRoute route) async {
    final result = await _load(
      _routeUri('EstimatedTimeOfArrival', route),
      arrivalsTtl,
      EstimateBusStop.fromJson,
    );
    return ArrivalSnapshot(
      result.items
          .cast<EstimateBusStop>()
          .where((arrival) => arrival.routeUid == route.uid)
          .toList(),
      result.fetchedAt,
    );
  }

  Uri _routeUri(String resource, BusRoute route) => _uri(resource, route.city, {
        r'$filter': "RouteUID eq '${_quote(route.uid)}'",
      });

  Uri _uri(String resource, BusCity city, Map<String, String> query) =>
      Uri.https(
        'tdx.transportdata.tw',
        '/api/basic/v2/Bus/$resource/City/${city.apiName}',
        {...query, r'$format': 'JSON'},
      );

  // OData 的字串常值以兩個單引號跳脫；URL 編碼交由 Uri 處理。
  String _quote(String value) => value.replaceAll("'", "''");

  Future<_CachedResult> _load<T>(
    Uri uri,
    Duration ttl,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final cached = _cache[uri];
    if (cached != null && _now().isBefore(cached.fetchedAt.add(ttl))) {
      // 命中移到尾端，容量滿時淘汰最久未使用的查詢。
      _cache.remove(uri);
      _cache[uri] = cached;
      return cached;
    }
    _cache.remove(uri);
    // 相同路線在不同頁面同時查詢，只會送出一份請求。
    final pending = _pending[uri] ??= _fetch(uri, decode);
    try {
      return await pending;
    } finally {
      if (identical(_pending[uri], pending)) _pending.remove(uri);
    }
  }

  Future<_CachedResult> _fetch<T>(
    Uri uri,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final response = await _api.get(uri);
    if (response.statusCode != 200) {
      final message = switch (response.statusCode) {
        401 => 'TDX 認證失效，請稍後重試。',
        403 => 'TDX 未授權此資料服務，請確認金鑰權限。',
        429 => 'TDX 查詢頻率已達上限，請稍後再試。',
        _ => 'TDX 資料查詢失敗（HTTP ${response.statusCode}），請稍後重試。',
      };
      throw TdxException(message, statusCode: response.statusCode);
    }

    final List<T> items;
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! List) throw const FormatException();
      items = json.map((item) => decode(item as Map<String, dynamic>)).toList();
    } on FormatException {
      throw const TdxException('TDX 回傳的資料格式不正確，請稍後重試。');
    } on TypeError {
      throw const TdxException('TDX 回傳的資料欄位不完整，請稍後重試。');
    }
    // 僅快取解析成功的回應；錯誤不會阻止使用者稍後重試。
    final result = _CachedResult(List.unmodifiable(items), _now());
    _cache[uri] = result;
    if (_cache.length > maxCacheEntries) _cache.remove(_cache.keys.first);
    return result;
  }
}

class _CachedResult {
  const _CachedResult(this.items, this.fetchedAt);

  final List<dynamic> items;
  final DateTime fetchedAt;
}

class RouteSearchResult {
  const RouteSearchResult(this.routes, {this.warning});

  final List<BusRoute> routes;
  final String? warning;
}
