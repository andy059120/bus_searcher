import 'dart:async';
import 'dart:convert';

import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:bus_project/data/services/tdx_token_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final apiUri = Uri.https(
    'tdx.transportdata.tw', '/api/basic/v2/Bus/Route/City/Taipei/262');

TdxApiClient createApi(MockClient client,
    {DateTime Function()? now,
    Duration requestTimeout = const Duration(seconds: 5)}) {
  final api = TdxApiClient(
    client: client,
    tokenService: TdxTokenService(
      client: client,
      credentials: const TdxCredentials(
          clientId: 'test-id', clientSecret: 'test-secret'),
      now: now,
    ),
    requestTimeout: requestTimeout,
  );
  addTearDown(api.close);
  return api;
}

http.Response tokenResponse(String token) => http.Response(
    jsonEncode({
      'access_token': token,
      'expires_in': 3600,
      'token_type': 'Bearer',
    }),
    200);

void main() {
  test('reuses authorization and checks expiry on every API call', () async {
    var now = DateTime.utc(2026);
    var authCalls = 0;
    final headers = <String?>[];
    final api = createApi(MockClient((request) async {
      expect(request.followRedirects, isFalse);
      if (request.method == 'POST') {
        return tokenResponse('token-${++authCalls}');
      }
      headers.add(request.headers['Authorization']);
      return http.Response('[]', 200);
    }), now: () => now);
    await api.get(apiUri);
    await api.get(apiUri);
    now = now.add(const Duration(hours: 2));
    await api.get(apiUri);
    expect(authCalls, 2);
    expect(headers, ['Bearer token-1', 'Bearer token-1', 'Bearer token-2']);
  });

  test('401 renews authorization and retries exactly once', () async {
    var authCalls = 0;
    var getCalls = 0;
    final api = createApi(MockClient((request) async {
      if (request.method == 'POST') {
        return tokenResponse('token-${++authCalls}');
      }
      getCalls++;
      return http.Response('', getCalls == 1 ? 401 : 200);
    }));
    expect((await api.get(apiUri)).statusCode, 200);
    expect(authCalls, 2);
    expect(getCalls, 2);
  });

  test('repeated 401 cannot create an infinite refresh loop', () async {
    var authCalls = 0;
    var getCalls = 0;
    final api = createApi(MockClient((request) async {
      if (request.method == 'POST') {
        return tokenResponse('token-${++authCalls}');
      }
      getCalls++;
      return http.Response('', 401);
    }));
    expect((await api.get(apiUri)).statusCode, 401);
    expect(authCalls, 2);
    expect(getCalls, 2);
  });

  test('a late 401 for an old token does not discard the renewed token',
      () async {
    var now = DateTime.utc(2026);
    var authCalls = 0;
    var oldGets = 0;
    final lateResponse = Completer<http.Response>();
    final api = createApi(MockClient((request) async {
      if (request.method == 'POST') {
        return tokenResponse('token-${++authCalls}');
      }
      if (request.headers['Authorization'] == 'Bearer token-1') {
        if (++oldGets == 1) return http.Response('', 401);
        return lateResponse.future;
      }
      return http.Response('[]', 200);
    }), now: () => now);
    final first = api.get(apiUri);
    final second = api.get(apiUri);
    expect((await first).statusCode, 200);
    // 認證與資料重試共用每分鐘 5 次額度，延後舊回應以測試新視窗。
    now = now.add(const Duration(seconds: 61));
    lateResponse.complete(http.Response('', 401));
    expect((await second).statusCode, 200);
    expect(authCalls, 2);
    expect(oldGets, 2);
  });

  for (final status in [302, 403, 423, 429, 500]) {
    test('HTTP $status is returned without repeated authentication', () async {
      var authCalls = 0;
      var getCalls = 0;
      final api = createApi(MockClient((request) async {
        if (request.method == 'POST') {
          return tokenResponse('token-${++authCalls}');
        }
        getCalls++;
        return http.Response('', status);
      }));
      expect((await api.get(apiUri)).statusCode, status);
      expect(authCalls, 1);
      expect(getCalls, 1);
    });
  }

  test('rejects external or insecure URLs before sending credentials',
      () async {
    var calls = 0;
    final api = createApi(MockClient((_) async {
      calls++;
      return http.Response('', 200);
    }));
    for (final url in [
      'http://tdx.transportdata.tw/api/basic/v2/Bus/Route',
      'https://example.com/api/basic/v2/Bus/Route',
      'https://tdx.transportdata.tw:8443/api/basic/v2/Bus/Route',
      'https://user@tdx.transportdata.tw/api/basic/v2/Bus/Route',
      'https://tdx.transportdata.tw/other',
    ]) {
      await expectLater(api.get(Uri.parse(url)), throwsA(isA<TdxException>()));
    }
    expect(calls, 0);
  });

  test('API timeout does not trigger another authentication request', () async {
    var authCalls = 0;
    final delayed = Completer<http.Response>();
    final api = createApi(MockClient((request) async {
      if (request.method == 'POST') {
        authCalls++;
        return tokenResponse('token');
      }
      return delayed.future;
    }), requestTimeout: const Duration(milliseconds: 10));
    await expectLater(api.get(apiUri), throwsA(isA<TdxException>()));
    delayed.complete(http.Response('[]', 200));
    expect(authCalls, 1);
  });
}
