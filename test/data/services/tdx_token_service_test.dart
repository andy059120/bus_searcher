import 'dart:async';
import 'dart:convert';

import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:bus_project/data/services/tdx_token_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const credentials = TdxCredentials(
  clientId: 'test-client',
  clientSecret: 'test-secret',
);

http.Response tokenResponse(String token, {int expiresIn = 3600}) =>
    http.Response(
      jsonEncode({
        'access_token': token,
        'expires_in': expiresIn,
        'token_type': 'Bearer',
      }),
      200,
    );

void main() {
  test('missing credentials fail before making a network request', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return tokenResponse('unused');
    });
    addTearDown(client.close);
    final service = TdxTokenService(
      client: client,
      credentials: const TdxCredentials(clientId: '', clientSecret: ''),
    );
    await expectLater(service.getAccessToken(), throwsA(isA<TdxException>()));
    expect(calls, 0);
  });

  test('uses form credentials over HTTPS and reuses the cached token',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.method, 'POST');
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'tdx.transportdata.tw');
      expect(request.url.path,
          '/auth/realms/TDXConnect/protocol/openid-connect/token');
      expect(request.followRedirects, isFalse);
      expect(request.url.query, isEmpty);
      expect(Uri.splitQueryString(request.body), {
        'grant_type': 'client_credentials',
        'client_id': 'test-client',
        'client_secret': 'test-secret',
      });
      return tokenResponse('cached-token');
    });
    addTearDown(client.close);
    final service = TdxTokenService(client: client, credentials: credentials);
    expect(await service.getAccessToken(), 'cached-token');
    expect(await service.getAccessToken(), 'cached-token');
    expect(calls, 1);
  });

  test('concurrent callers share one authentication request', () async {
    var calls = 0;
    final response = Completer<http.Response>();
    final client = MockClient((_) {
      calls++;
      return response.future;
    });
    addTearDown(client.close);
    final service = TdxTokenService(client: client, credentials: credentials);
    final requests = List.generate(5, (_) => service.getAccessToken());
    response.complete(tokenResponse('shared-token'));
    expect(await Future.wait(requests), List.filled(5, 'shared-token'));
    expect(calls, 1);
  });

  test('refreshes according to expires_in before expiry', () async {
    var now = DateTime.utc(2026);
    var calls = 0;
    final client = MockClient((_) async => tokenResponse('token-${++calls}'));
    addTearDown(client.close);
    final service = TdxTokenService(
      client: client,
      credentials: credentials,
      now: () => now,
    );
    expect(await service.getAccessToken(), 'token-1');
    now = now.add(const Duration(seconds: 3539));
    expect(await service.getAccessToken(), 'token-1');
    now = now.add(const Duration(seconds: 1));
    expect(await service.getAccessToken(), 'token-2');
    now = now.add(const Duration(hours: 2));
    expect(await service.getAccessToken(), 'token-3');
  });

  test('short-lived tokens do not refresh immediately', () async {
    var now = DateTime.utc(2026);
    var calls = 0;
    final client = MockClient(
        (_) async => tokenResponse('token-${++calls}', expiresIn: 10));
    addTearDown(client.close);
    final service = TdxTokenService(
      client: client,
      credentials: credentials,
      now: () => now,
    );
    expect(await service.getAccessToken(), 'token-1');
    now = now.add(const Duration(seconds: 8));
    expect(await service.getAccessToken(), 'token-1');
    now = now.add(const Duration(seconds: 1));
    expect(await service.getAccessToken(), 'token-2');
  });

  test('failed authentication is sanitized and does not poison later attempts',
      () async {
    var calls = 0;
    final client = MockClient((_) async {
      return ++calls == 1
          ? http.Response('test-secret and sensitive response', 401)
          : tokenResponse('recovered-token');
    });
    addTearDown(client.close);
    final service = TdxTokenService(client: client, credentials: credentials);
    await expectLater(
      service.getAccessToken(),
      throwsA(isA<TdxException>()
          .having((e) => e.statusCode, 'status', 401)
          .having((e) => e.toString(), 'safe message',
              isNot(contains('test-secret')))),
    );
    expect(await service.getAccessToken(), 'recovered-token');
    expect(calls, 2);
  });

  final invalidResponses = <String, String>{
    'invalid JSON': 'test-secret',
    'invalid shape': '[]',
    'missing expiry': '{"access_token":"token","token_type":"Bearer"}',
    'invalid expiry':
        '{"access_token":"token","expires_in":0,"token_type":"Bearer"}',
    'invalid token type':
        '{"access_token":"token","expires_in":3600,"token_type":"Basic"}',
    'invalid token':
        '{"access_token":"bad token","expires_in":3600,"token_type":"Bearer"}',
  };
  for (final entry in invalidResponses.entries) {
    test('rejects ${entry.key} without exposing the response', () async {
      final client = MockClient((_) async => http.Response(entry.value, 200));
      addTearDown(client.close);
      final service = TdxTokenService(client: client, credentials: credentials);
      await expectLater(
        service.getAccessToken(),
        throwsA(isA<TdxException>().having((e) => e.toString(), 'safe message',
            isNot(contains('test-secret')))),
      );
    });
  }

  test('request latency counts against the token lifetime', () async {
    var now = DateTime.utc(2026);
    final client = MockClient((_) async {
      now = now.add(const Duration(seconds: 11));
      return tokenResponse('already-expired', expiresIn: 10);
    });
    addTearDown(client.close);
    final service = TdxTokenService(
      client: client,
      credentials: credentials,
      now: () => now,
    );
    await expectLater(service.getAccessToken(), throwsA(isA<TdxException>()));
  });

  test('timeouts fail safely and allow a later retry', () async {
    var calls = 0;
    final delayed = Completer<http.Response>();
    final client = MockClient((_) async {
      if (++calls == 1) return delayed.future;
      return tokenResponse('after-timeout');
    });
    addTearDown(client.close);
    final service = TdxTokenService(
      client: client,
      credentials: credentials,
      requestTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(service.getAccessToken(), throwsA(isA<TdxException>()));
    delayed.complete(tokenResponse('late-token'));
    expect(await service.getAccessToken(), 'after-timeout');
    expect(calls, 2);
  });
}
